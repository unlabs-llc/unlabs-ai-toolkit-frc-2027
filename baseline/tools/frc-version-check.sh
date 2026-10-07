#!/usr/bin/env bash
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
#
# frc-version-check.sh — a SessionStart hook that tells the student when a newer release of this
# toolkit exists.
#
# WHAT IT DOES, AND NOTHING ELSE. It reads the installed version from
# .claude/frc-baseline-manifest.yml, and asks GitHub for the latest release of the public repository.
# Each session start makes at most one request with a three-second timeout, and successful and failed
# results are cached per user for 24 hours when the cache can be written. If the release is newer,
# the script prints one JSON object. Claude Code shows the object's systemMessage to the student and
# hands additionalContext to the assistant. It never blocks a session, never writes inside the
# project, and sends nothing but one unauthenticated GET to api.github.com.
#
# SILENT WHEN IT CANNOT KNOW. Offline (a competition pit), rate limited, a reply it cannot parse, a
# development build with no release version, no manifest, or a missing required tool: it prints
# nothing and exits 0. A check that complains on every offline session teaches students to ignore it,
# and then it is worth nothing on the day it matters.
#
# BOUNDED. Each session start makes at most one request with a three-second timeout. Successful and
# failed results are cached per user for 24 hours when the cache can be written. A cache path that
# resolves inside the project is not used, so nothing here needs .gitignore.
#
# SECURITY RELEASES. A release whose title contains "[security]" (any case) is reported with an
# instruction to pause and ask a mentor to update before continuing. That convention is defined in
# release/README.md, in the build repository, which is where releases are made.
#
# Switch it off for a user or a session: FRC_TOOLKIT_NO_UPDATE_CHECK=1

set -u
LC_ALL=C; export LC_ALL
# Nothing this script prints on stderr is useful to a student; a missing tool just means silence.
exec 2>/dev/null
umask 077

[ "${FRC_TOOLKIT_NO_UPDATE_CHECK:-}" = 1 ] && exit 0

API_URL="https://api.github.com/repos/unlabs-llc/unlabs-ai-toolkit-frc-2027/releases/latest"
RELEASES_URL="https://github.com/unlabs-llc/unlabs-ai-toolkit-frc-2027/releases"
OK_TTL=86400
FAIL_TTL=86400
VERSION_RE='^[0-9]{1,6}\.[0-9]{1,6}\.[0-9]{1,6}(_(Alpha|Beta|RC)-[0-9]{1,6})?$'

case ${CLAUDE_PROJECT_DIR:-} in
  /*) project_candidate=$CLAUDE_PROJECT_DIR ;;
  *) project_candidate=$PWD ;;
esac
proj=$(cd -P -- "$project_candidate" 2>/dev/null && pwd -P) || exit 0
manifest="$proj/.claude/frc-baseline-manifest.yml"
[ -r "$manifest" ] || exit 0

# The first "  version:" line is the release block's. Accept either a wholly unquoted version or a
# wholly double-quoted version, with an optional trailing comment. Any other value is not a release.
first_version_line=""
while IFS= read -r manifest_line; do
  case "$manifest_line" in
    "  version:"*) first_version_line=$manifest_line; break ;;
  esac
done < "$manifest"
unquoted_version_re='^  version:[[:space:]]*(v?)([0-9]{1,6}\.[0-9]{1,6}\.[0-9]{1,6}(_(Alpha|Beta|RC)-[0-9]{1,6})?)[[:space:]]*(#.*)?$'
quoted_version_re='^  version:[[:space:]]*"(v?)([0-9]{1,6}\.[0-9]{1,6}\.[0-9]{1,6}(_(Alpha|Beta|RC)-[0-9]{1,6})?)"[[:space:]]*(#.*)?$'
if [[ $first_version_line =~ $unquoted_version_re ]]; then
  installed=${BASH_REMATCH[2]}
elif [[ $first_version_line =~ $quoted_version_re ]]; then
  installed=${BASH_REMATCH[2]}
else
  exit 0
fi

# jq is part of the trust boundary: without structural JSON parsing there is no release fact to use.
for required_tool in curl jq date mkdir mktemp mv rm; do
  command -v "$required_tool" >/dev/null 2>&1 || exit 0
done

cache_enabled=0
cache_base=""
case ${XDG_CACHE_HOME:-} in
  /*) cache_base=$XDG_CACHE_HOME ;;
  *)
    case ${HOME:-} in
      /*) cache_base="$HOME/.cache" ;;
    esac
    ;;
esac
# The XDG default ($HOME/.cache) often does not exist yet, on a new Mac especially. Canonicalise the
# base when it exists, or else its parent; write_cache then creates it (mode 0700 under the umask
# above). With no usable base at all the script stays silent, as before: an uncached check would
# make a request at every session start.
if [ -n "$cache_base" ]; then
  while [ "$cache_base" != / ] && [ "${cache_base%/}" != "$cache_base" ]; do
    cache_base=${cache_base%/}
  done
  if [ -e "$cache_base" ]; then
    cache_base=$(cd -P -- "$cache_base" 2>/dev/null && pwd -P) || cache_base=""
  else
    cache_leaf=${cache_base##*/}
    cache_parent=${cache_base%/*}
    case "$cache_leaf" in
      ""|.|..) cache_base="" ;;
      *)
        if cache_parent=$(cd -P -- "${cache_parent:-/}" 2>/dev/null && pwd -P); then
          cache_base="${cache_parent%/}/$cache_leaf"
        else
          cache_base=""
        fi
        ;;
    esac
  fi
fi
[ -n "$cache_base" ] || exit 0
cache_dir=""
cache=""
if [ -n "$cache_base" ]; then
  cache_dir="$cache_base/unlabs-ai-toolkit-frc-2027"
  cache="$cache_dir/latest-release"
  case "$proj" in
    /) : ;;
    *)
      case "$cache_dir" in
        "$proj"|"$proj"/*) : ;;
        *) cache_enabled=1 ;;
      esac
      ;;
  esac
fi
now=$(date +%s 2>/dev/null) || exit 0
[[ $now =~ ^[0-9]{1,18}$ ]] || exit 0

strip_leading_zeroes() {
  local value=$1
  while [ "${value#0}" != "$value" ]; do value=${value#0}; done
  printf '%s' "${value:-0}"
}
now=$(strip_leading_zeroes "$now")

write_cache() { # state, version, security bit
  local state=$1 version=$2 security_bit=$3 temporary=""
  [ "$cache_enabled" -eq 1 ] || return 0
  mkdir -p -- "$cache_dir" 2>/dev/null || return 0
  if [ ! -d "$cache_dir" ] || [ -L "$cache_dir" ]; then
    return 0
  fi
  temporary=$(mktemp "$cache_dir/.latest-release.XXXXXX" 2>/dev/null) || return 0
  if printf '%s\n%s\n%s\n%s\n' "$now" "$state" "$version" "$security_bit" \
       > "$temporary" 2>/dev/null; then
    # BSD mv has no -T. Remove a destination symlink explicitly, reject every other existing
    # non-regular destination, then use the portable two-operand form. There is an unavoidable
    # check/rename race on platforms without renameat2: another process can create a directory at
    # $cache after this check and make mv place the temporary file inside it.
    if [ -L "$cache" ]; then
      rm -f -- "$cache" 2>/dev/null || { rm -f -- "$temporary" 2>/dev/null; return 0; }
    elif [ -e "$cache" ] && [ ! -f "$cache" ]; then
      rm -f -- "$temporary" 2>/dev/null
      return 0
    fi
    mv -f -- "$temporary" "$cache" 2>/dev/null || rm -f -- "$temporary" 2>/dev/null
  else
    rm -f -- "$temporary" 2>/dev/null
  fi
}

latest="" security=0 fresh=0
if [ "$cache_enabled" -eq 1 ] && [ -f "$cache" ] && [ ! -L "$cache" ] && [ -r "$cache" ]; then
  # A plain read loop rather than mapfile: the macOS system bash is 3.2, which has no mapfile, and a
  # cache that is never read means a request every session there.
  cache_lines=0; c_when=""; c_state=""; c_latest=""; c_security=""
  while IFS= read -r cache_line || [ -n "$cache_line" ]; do
    cache_lines=$((cache_lines + 1))
    case "$cache_lines" in
      1) c_when=$cache_line ;;
      2) c_state=$cache_line ;;
      3) c_latest=$cache_line ;;
      4) c_security=$cache_line ;;
      *) break ;;
    esac
  done < "$cache"
  if [ "$cache_lines" -eq 4 ]; then
    cache_valid=0
    if [[ $c_when =~ ^[0-9]{1,18}$ ]] && [[ $c_security =~ ^[01]$ ]]; then
      case "$c_state" in
        ok) [[ $c_latest =~ $VERSION_RE ]] && cache_valid=1 ;;
        fail) [ -z "$c_latest" ] && [ "$c_security" = 0 ] && cache_valid=1 ;;
      esac
    fi
    if [ "$cache_valid" -eq 1 ]; then
      c_when=$(strip_leading_zeroes "$c_when")
      age=$((now - c_when))
      if [ "$c_state" = ok ] && [ "$age" -ge 0 ] && [ "$age" -lt "$OK_TTL" ]; then
        latest=$c_latest; security=$c_security; fresh=1
      elif [ "$c_state" = fail ] && [ "$age" -ge 0 ] && [ "$age" -lt "$FAIL_TTL" ]; then
        exit 0
      fi
    fi
  fi
fi

if [ "$fresh" -eq 0 ]; then
  body=$(curl -q -fsS --max-time 3 \
              -H 'Accept: application/vnd.github+json' \
              -A 'unlabs-ai-toolkit-frc-2027-version-check' \
              -- "$API_URL" 2>/dev/null) || body=""
  parsed=$(printf '%s' "$body" | jq -erRs '
    fromjson?
    | objects
    | select((.tag_name | type) == "string")
    | select(.tag_name | test("^v?[0-9]{1,6}\\.[0-9]{1,6}\\.[0-9]{1,6}(_(Alpha|Beta|RC)-[0-9]{1,6})?$"))
    | select((.name | type) == "string")
    | [(.tag_name | sub("^v"; "")),
       (if (.name | ascii_downcase | contains("[security]")) then "1" else "0" end)]
    | @tsv
  ' 2>/dev/null) || parsed=""
  latest=""; security=0
  case "$parsed" in
    *$'\n'*|*$'\r'*) ;;
    *$'\t'*) latest=${parsed%%$'\t'*}; security=${parsed#*$'\t'} ;;
  esac
  if [[ $latest =~ $VERSION_RE ]] && [[ $security =~ ^[01]$ ]]; then
    write_cache ok "$latest" "$security"
  else
    write_cache fail "" 0
    exit 0
  fi
fi

# true when $2 is a later release than $1. Compares X.Y.Z numerically (leading zeroes removed); for the
# same X.Y.Z a plain release is later than any _Alpha/_Beta/_RC build of it, and builds order
# Alpha < Beta < RC, then by their number.
is_newer() {
  local a1 a2 a3 aq an b1 b2 b3 bq bn core pre
  core=${1%%_*}; pre=""; [ "$core" != "$1" ] && pre=${1#*_}
  IFS=. read -r a1 a2 a3 <<< "$core"
  aq=${pre%%-*}; an=${pre#*-}
  core=${2%%_*}; pre=""; [ "$core" != "$2" ] && pre=${2#*_}
  IFS=. read -r b1 b2 b3 <<< "$core"
  bq=${pre%%-*}; bn=${pre#*-}
  a1=$(strip_leading_zeroes "$a1"); a2=$(strip_leading_zeroes "$a2"); a3=$(strip_leading_zeroes "$a3")
  b1=$(strip_leading_zeroes "$b1"); b2=$(strip_leading_zeroes "$b2"); b3=$(strip_leading_zeroes "$b3")
  [ "$b1" -gt "$a1" ] && return 0; [ "$b1" -lt "$a1" ] && return 1
  [ "$b2" -gt "$a2" ] && return 0; [ "$b2" -lt "$a2" ] && return 1
  [ "$b3" -gt "$a3" ] && return 0; [ "$b3" -lt "$a3" ] && return 1
  local ar br
  case "$aq" in Alpha) ar=1 ;; Beta) ar=2 ;; RC) ar=3 ;; *) ar=4; an=0 ;; esac
  case "$bq" in Alpha) br=1 ;; Beta) br=2 ;; RC) br=3 ;; *) br=4; bn=0 ;; esac
  [ "$br" -gt "$ar" ] && return 0; [ "$br" -lt "$ar" ] && return 1
  an=$(strip_leading_zeroes "$an"); bn=$(strip_leading_zeroes "$bn")
  [ "$bn" -gt "$an" ] && return 0
  return 1
}
is_newer "$installed" "$latest" || exit 0

# Every value interpolated below is a version string checked above, or a constant: nothing from the
# network reaches this JSON except a validated version number and the one-bit security classification.
if [ "$security" -eq 1 ]; then
  msg="Unlabs AI Toolkit for FRC 2027 Season Teams $latest is a security release, and this project has $installed. Pause and ask a mentor to update the toolkit before you continue: $RELEASES_URL"
  ctx="The Unlabs AI Toolkit for FRC 2027 Season Teams installed in this project is version $installed. Version $latest is available and is marked as a security release. In your first reply, before anything else, tell the student in one or two plain sentences that a security update is available, that they should pause and ask a mentor to update the toolkit before continuing, and where it is: $RELEASES_URL. Do not update the toolkit yourself."
else
  msg="Unlabs AI Toolkit for FRC 2027 Season Teams $latest is available, and this project has $installed. Ask a mentor to update when convenient: $RELEASES_URL"
  ctx="The Unlabs AI Toolkit for FRC 2027 Season Teams installed in this project is version $installed. Version $latest is available. In your first reply, tell the student in one sentence that a newer toolkit release exists and that a mentor can update it: $RELEASES_URL. Then carry on with what they asked. Do not update the toolkit yourself."
fi
printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg" "$ctx"
exit 0
