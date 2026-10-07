#!/usr/bin/env bash
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
#
# Unlabs AI Toolkit for FRC 2027 Season Teams — scaffold.
#
# Upstream: current-wpilib-2027
# Last verified: 2026-09-03
#
# ONE STATED PROPERTY: leave-it-alone. No file that exists when this runs has its contents
# overwritten or rewritten. Two qualifications, stated rather than hidden behind "no exceptions":
#   - .gitignore: when the managed block's begin marker is absent, the block is APPENDED — existing
#     lines are kept, nothing is rewritten. With begin and end markers both present, in that order,
#     the file is not touched; a begin marker with no later end marker stops the run (exit 16).
#   - the pre-deploy runner AND the compile-probe driver: chmod +x is attempted on each — a mode
#     change, not a content change — and a bit that does not take is WARNED about at the chmod site
#     rather than assumed. The attempt is made only on this baseline's own regular, non-symlink copy
#     of each file: the one this run wrote, or a regular, non-symlink file already here that compares
#     equal to it byte for byte. Every other path already here is left alone; its mode is not changed
#     either, and the run says so where it says the path was left unchanged. (The driver was added to
#     this sentence on 2026-09-08: its chmod had carried neither guard, so an unverified pre-existing
#     driver was made executable while the run reported nothing had changed.)
# A second run after a successful one does not change installed-file contents when those files still
# match. It may retry the runner mode repair described above and uses temporary verification data
# under .git/.
#
# v1.0 installs ONE hook, and it gates nothing: a SessionStart update check
# (.claude/tools/frc-version-check.sh) that tells the student when a newer release exists. It never
# blocks a session or an action. The deploy gate stays withdrawn (see docs/LIMITATIONS.md). An earlier
# version carved out a settings.json merge exception for that gate, because "never overwrite" plus
# "gate on by default" would otherwise have left every experienced team unprotected while the script
# exited 0. The exception went with the gate, and it is NOT revived for the update check: an existing
# settings.json is left alone unconditionally, and the run reports when the supplied update hook
# cannot be confirmed there.
#
# EXIT CODES — stable across versions; teams script against them.
#   0  success
#   10 not a git repository
#   11 not at repository top level
#   12 unsupported platform
#   13 path not writable
#   14 baseline source files missing or unreadable
#   16 managed .gitignore block has a begin marker but no later end marker
#   17 managed .gitignore block has both markers but is missing one or more of the exclusion lines
#      between them
#   18 an existing .claude/settings.json could not be confirmed to carry this baseline's
#      permissions.deny rule strings
#   19 the managed .gitignore block was not confirmed: git does not ignore one of the paths the run
#      derived from the exclusion lines that name a path literally, or a path that git knows about in
#      this project -- a file in the working tree, or an entry already in git's index -- that git has
#      NOT committed, and that the block's own text names is still visible to git, or that check
#      could not be run. A path already committed is outside both questions and is not what this code
#      reports; so is a path left unmerged by a conflicted merge, which git refuses to commit at all
#      while the conflict stands
#   20 one or more files this baseline ships already existed and could not be confirmed to carry the
#      content this baseline ships
#
# Codes 18 and 20 are RECORDED and reported at the end; every other code stops the run where it
# occurs. When both 18 and 20 apply, both warnings print and the run exits with the one recorded
# first in step order, which is 20.
#
# (Exit 15 previously meant "deploy gate NOT installed". The deploy gate is WITHDRAWN from v1.0 --
# see docs/LIMITATIONS.md -- so the code is RETIRED, not reused. Reusing a code
# teams may have scripted against would silently change what it means.)

set -euo pipefail

STEP="startup"
trap 'printf "ABORTED during step: %s\n" "$STEP" >&2' ERR

SRC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# A path a team is told to go and read is printed so that it resolves FROM WHERE THAT TEAM IS
# STANDING. This script runs in the robot project; every file it points at lives in the baseline
# source tree, which is $SRC_DIR and is somewhere else entirely. Printing `baseline/templates/...`
# as a project-relative path sent teams to paths that do not exist in the repository the script
# requires them to run in -- and it did so in exactly the cases that need manual work. The two
# templates are preflighted below, so their absolute paths are safe to print unconditionally.
CLAUDE_MD_TEMPLATE_PATH="$SRC_DIR/baseline/templates/CLAUDE.md.template"
SETTINGS_TEMPLATE_PATH="$SRC_DIR/baseline/templates/settings.json.template"

# Reads the lines BETWEEN an HTML-comment BEGIN and END marker pair, exclusive of both. Returns
# nonzero unless the file contains exactly one properly ordered pair, so an extraction that did not
# establish the block's shape can never become content that happened to compare equal.
extract_block() { # file block-name
  awk -v b="$2" '
    BEGIN {
      begin_marker = "<!-- " b "-BEGIN -->"
      end_marker = "<!-- " b "-END -->"
    }
    $0 == begin_marker {
      begin_count++
      if (begin_count != 1 || in_block || seen_end) malformed = 1
      in_block = 1
      next
    }
    $0 == end_marker {
      end_count++
      if (!in_block || seen_end) malformed = 1
      in_block = 0
      seen_end = 1
      next
    }
    in_block { print }
    END {
      if (malformed || begin_count != 1 || end_count != 1 || in_block) exit 3
    }
  ' "$1"
}

# The first line of a pre-existing CLAUDE.md is checked against the header this baseline template
# defines. The template supplies the grammar rather than a second hand-maintained copy here. Its
# version and source-ref placeholders must each occur once; its install-date placeholder is the one
# field whose existing value is retained, and only the decimal YYYY-MM-DD shape is accepted.
claude_header_template_valid() { # template-file
  awk '
    function occurrences(text, needle, count, at) {
      count = 0
      while ((at = index(text, needle)) != 0) {
        count++
        text = substr(text, at + length(needle))
      }
      return count
    }
    FNR == 1 { header = $0; saw_header = 1 }
    END {
      if (!saw_header ||
          occurrences(header, "__BASELINE_VERSION__") != 1 ||
          occurrences(header, "__INSTALL_DATE__") != 1 ||
          occurrences(header, "__SOURCE_REF__") != 1) exit 3
    }
  ' "$1"
}

claude_header_matches() { # template-file existing-file baseline-version source-ref
  awk -v version="$3" -v source_ref="$4" '
    FILENAME == ARGV[1] && FNR == 1 { pattern = $0; next }
    FILENAME == ARGV[2] && FNR == 1 { candidate = $0; saw_candidate = 1 }
    END {
      if (!saw_candidate) exit 1

      at = index(pattern, "__BASELINE_VERSION__")
      pattern = substr(pattern, 1, at - 1) version \
                substr(pattern, at + length("__BASELINE_VERSION__"))
      at = index(pattern, "__SOURCE_REF__")
      pattern = substr(pattern, 1, at - 1) source_ref \
                substr(pattern, at + length("__SOURCE_REF__"))
      at = index(pattern, "__INSTALL_DATE__")
      prefix = substr(pattern, 1, at - 1)
      suffix = substr(pattern, at + length("__INSTALL_DATE__"))

      if (substr(candidate, 1, length(prefix)) != prefix ||
          substr(candidate, length(candidate) - length(suffix) + 1) != suffix) exit 1
      date_text = substr(candidate, length(prefix) + 1,
                         length(candidate) - length(prefix) - length(suffix))
      if (date_text !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) exit 1
    }
  ' "$1" "$2"
}

# The run's final exit status. Most steps below either die() immediately (an aborted, partial
# install) or leave this at 0 (nothing to report). TWO steps record a problem instead of calling
# die(), so the run reaches the "done" step below rather than aborting part-way through: the
# baseline-files step, when something it was told to leave alone cannot be confirmed to carry the
# content this baseline ships (20), and the settings step (18). A nonzero value stops the run THERE,
# above the success-only banner and the commit instruction.
#
# record_exit() keeps the FIRST code recorded and ignores later ones, so a run that hits both prints
# both warnings and exits with one number rather than with whichever step ran last.
#
# Any step that records a code MUST also say, in its own step, what it found: the message printed at
# the "done" step points back at those warnings rather than repeating them.
EXIT_CODE=0
record_exit() { if [ "$EXIT_CODE" -eq 0 ]; then EXIT_CODE="$1"; fi; }

# Every path this run left in place WITHOUT confirming it carries the content this baseline ships.
# The list is what the closing message names: a run that cannot say what it left behind must not
# report an installation, and "cannot say" has to be carried to the end of the run to be said.
UNCONFIRMED=""
note_unconfirmed() { UNCONFIRMED="$UNCONFIRMED
    $1"; }

die() { printf '%s\n' "$2" >&2; exit "$1"; }
say() { printf '%s\n' "$1"; }

# Refuse an existing symbolic link or any other existing non-directory at the named project-relative
# path or at any of its ancestors. Callers pass the directory they are about to create in; checking
# the destination file itself is left to that file's existing-path policy. Component-by-component
# shell expansion avoids turning a failed path resolver into an empty answer, and starts at the
# deepest component so the diagnostic names the node that would actually stop or redirect the write.
refuse_symlink_components() { # project-relative path
  local component=$1
  while :; do
    [ ! -L "$component" ] \
      || die 13 "path not writable — refusing destination $1 because $component is a symbolic link; replace it with a directory inside $TOP and run again"
    { [ ! -e "$component" ] || [ -d "$component" ]; } \
      || die 13 "path not writable — refusing destination $1 because $component exists and is not a directory; replace it with a directory inside $TOP and run again"
    case "$component" in
      */*) component=${component%/*} ;;
      *) break ;;
    esac
  done
}

# ============================================================================================
STEP="preconditions"
# ============================================================================================
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die 10 "not a git repository — run this from inside your robot project's git repository"

TOP=$(git rev-parse --show-toplevel)
[ "$(pwd -P)" = "$(cd "$TOP" && pwd -P)" ] \
  || die 11 "not at repository top level — cd to $TOP and run again"

case "$(uname -s)" in
  Linux|Darwin|MINGW*|MSYS*|CYGWIN*) : ;;
  *) die 12 "unsupported platform — supported: Linux, macOS, and Windows via Git Bash" ;;
esac

[ -w . ] || die 13 "path not writable — check permissions on $(pwd -P)"

# A WRITABLE DIRECTORY DOES NOT MAKE ITS EXISTING FILES WRITABLE, and exit 13 is a documented,
# scriptable status rather than a courtesy. Measured 2026-08-28: with a project directory writable and
# a pre-existing `.gitignore` at mode 444, the append at the ignore-rules step failed with bash's own
# "Permission denied" and the run ended at the generic ABORTED trap with raw status 1 — not 13. A team
# scripting against the documented codes got an undocumented one and no path-specific remedy.
#
# The probe is the ATTEMPTED OPERATION, not a mode-bit reading. `[ -w ]` and a stat of the mode can
# both disagree with the kernel under ACLs, a read-only mount, or elevated privilege, in either
# direction — so this opens the file for append exactly as the real write will and writes nothing.
# An existing file only: where the file is absent the directory check above is the operative one, and
# this probe would create it.
require_appendable() { # <path>
  [ -e "$1" ] || return 0
  { : >> "$1"; } 2>/dev/null || die 13 "path not writable — $1 exists but could not be opened for append; check its permissions"
}

# This destination preflight is above the first project write. In particular, a non-directory
# .claude ancestor must stop with the documented path status before the ignore block is appended.
refuse_symlink_components .claude/frc

# The ten commands, in the order they appear in the manifest. Named explicitly, never globbed: a
# glob silently widens the moment a stray file lands in the directory, and this list is what makes
# "the install wrote something it should not have" a comparison rather than an argument.
#
# `robot-debug` and `robot-review` are RENAMED from `debug` and `review`, which collide with the
# Claude Code product surface. CI-20 enforces this. Do not rename them back.
COMMANDS="subsystem command auto robot-debug tune test vision-integrate explain robot-review deploy"

# Sources named here are checked BEFORE anything is written, so a missing one exits 14 rather than
# leaving a partial install behind an ordinary cp failure. This list must mirror the copies made
# below; it drifted once — the WPILib host, its four references, and the pre-deploy runner were
# copied but never preflighted, so a missing one aborted MID-INSTALL with .gitignore already
# appended and an ordinary cp exit status. When adding a copy below, add its source here.
for f in baseline/templates/gitignore-fragment.txt \
         baseline/templates/settings.json.template \
         baseline/templates/CLAUDE.md.template \
         baseline/skills/current-wpilib-2027/SKILL.md \
         baseline/skills/current-wpilib-2027/references/namespaces.md \
         baseline/skills/current-wpilib-2027/references/ref-divergence.md \
         baseline/skills/current-wpilib-2027/references/commands.md \
         baseline/skills/current-wpilib-2027/references/gradle-tasks.md \
         baseline/skills/current-claude-models/SKILL.md \
         baseline/skills/frc-pre-deploy/SKILL.md \
         baseline/skills/frc-pre-deploy/scripts/run-pre-deploy.sh \
         baseline/agents/frc-docs-checker.md \
         baseline/tools/frc-docs-probe.sh \
         baseline/tools/frc-docs-probe.init.gradle \
         baseline/tools/frc-version-check.sh \
         baseline/skills/frc-behavior-first/SKILL.md \
         baseline/manifest.yml \
         baseline/COMMERCIAL-LICENSE.md; do
  # -f AND -r, not -r alone. `[ -r somedirectory ]` succeeds (measured 2026-08-21, Linux), so a
  # directory sitting where a source file belongs passed this loop and was then handed to a reader
  # that had no way to report the difference.
  { [ -f "$SRC_DIR/$f" ] && [ -r "$SRC_DIR/$f" ]; } \
    || die 14 "baseline source files missing or unreadable — $f is not a readable regular file"
done

claude_header_template_rc=0
claude_header_template_valid "$CLAUDE_MD_TEMPLATE_PATH" || claude_header_template_rc=$?
case "$claude_header_template_rc" in
  0) : ;;
  3) die 14 "baseline source files missing or unreadable — the first line of $CLAUDE_MD_TEMPLATE_PATH does not contain exactly one of each required header placeholder; refusing to check or render a CLAUDE.md header" ;;
  *) die 14 "baseline source files missing or unreadable — the header-placeholder check for $CLAUDE_MD_TEMPLATE_PATH exited $claude_header_template_rc and did not complete; refusing to check or render a CLAUDE.md header" ;;
esac

# Read only after the loop above has confirmed the manifest is a readable regular file. The same
# producer that reads the value also establishes that there is exactly one nonempty release-version
# line. Its framed output keeps invalid source content distinct from a reader that did not complete;
# neither can flow into the header checks, rendered header, success banner or commit suggestion.
BASELINE_VERSION_RECORD=$(awk '
  BEGIN { prefix = "  version: " }
  index($0, prefix) == 1 {
    version_count++
    version = substr($0, length(prefix) + 1)
  }
  END {
    if (version_count == 1 && version ~ /[^[:space:]]/)
      printf "valid\n%s", version
    else
      printf "invalid"
  }
' "$SRC_DIR/baseline/manifest.yml") \
  || die 14 "baseline source files missing or unreadable — the release-version reader for $SRC_DIR/baseline/manifest.yml did not complete; refusing to install without established version provenance"
case "$BASELINE_VERSION_RECORD" in
  valid$'\n'?*) BASELINE_VERSION=${BASELINE_VERSION_RECORD#*$'\n'} ;;
  invalid) die 14 "baseline source files missing or unreadable — $SRC_DIR/baseline/manifest.yml does not contain exactly one nonempty release-version value; refusing to install without established version provenance" ;;
  *) die 14 "baseline source files missing or unreadable — the release-version reader for $SRC_DIR/baseline/manifest.yml returned an invalid result; refusing to install without established version provenance" ;;
esac
INSTALL_DATE=$(date -u +%Y-%m-%d)

# Provenance for the installed CLAUDE.md header line. The installed manifest's `installed_from_ref`
# and `installed_at` are null and STAY null: this script copies that file verbatim and substitutes
# nothing into it, and a ref written there that this script had guessed would be worse than the null
# because it would read as provenance. What this script can establish, it
# records in the rendered CLAUDE.md instead -- the file a team actually opens in a pit. When the
# baseline source directory answers no git ref, the field says that in words and names nothing.
# git searches PARENT directories for a repository, so `rev-parse HEAD` run inside the baseline
# source directory answers with the enclosing repository's HEAD when the baseline has been vendored
# into a robot project -- measured 2026-08-22: an untracked baseline release under
# robot-project/vendor/baseline-src/ made this record the robot project's own unrelated commit as the
# baseline's provenance. A ref that names the wrong repository is exactly the "worse than the null"
# outcome this field exists to avoid, so a ref is taken ONLY when $SRC_DIR is the top level of the
# worktree git found: --show-prefix prints the path from that top level down to the directory it was
# run in, and prints nothing at all when they are the same directory.
#
# THE TOP-LEVEL TEST ALONE IS NOT ENOUGH, and that gap reproduced the same defect one step smaller.
# Measured 2026-08-28: a release vendored at the ROBOT PROJECT'S OWN ROOT makes $SRC_DIR the top level
# of the robot's worktree, so --show-prefix is empty and the guard passes -- and the ref recorded as
# "baseline source ref" is the robot project's HEAD. Being the top level of A worktree does not
# establish that it is the BASELINE'S worktree. So the ref is also refused when the worktree found
# from $SRC_DIR is the same worktree we are installing INTO: same repository, wrong provenance.
SOURCE_REF=""
SOURCE_GIT_PREFIX=$(git -C "$SRC_DIR" rev-parse --show-prefix 2>/dev/null) \
  || SOURCE_GIT_PREFIX="not a git worktree"
if [ -z "$SOURCE_GIT_PREFIX" ]; then
  SOURCE_TOPLEVEL=$(git -C "$SRC_DIR" rev-parse --show-toplevel 2>/dev/null) || SOURCE_TOPLEVEL=""
  PROJECT_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null) || PROJECT_TOPLEVEL=""
  if [ -n "$SOURCE_TOPLEVEL" ] && [ "$SOURCE_TOPLEVEL" = "$PROJECT_TOPLEVEL" ]; then
    SOURCE_REF=""
  else
    SOURCE_REF=$(git -C "$SRC_DIR" rev-parse HEAD 2>/dev/null) || SOURCE_REF=""
  fi
fi
[ -n "$SOURCE_REF" ] || SOURCE_REF="not recorded (the baseline source directory was not the top level of a git worktree of its own with a readable HEAD)"
for c in $COMMANDS; do
  { [ -f "$SRC_DIR/baseline/commands/$c.md" ] && [ -r "$SRC_DIR/baseline/commands/$c.md" ]; } \
    || die 14 "baseline source files missing or unreadable — baseline/commands/$c.md is not a readable regular file"
done

# A missing platform prerequisite WARNS and proceeds. Configure-then-install is a legitimate order,
# and blocking here would stop a team setting up before its toolchain install finishes.
if command -v jq >/dev/null 2>&1; then HAVE_JQ=1; else HAVE_JQ=0; fi
[ "$HAVE_JQ" -eq 1 ] \
  || say "WARNING: jq is not installed. /frc-pre-deploy needs it to write a verdict and will stop without it. The settings step below also needs it, and without it a .claude/settings.json that already exists is left unchecked and this run ends at exit 18."
[ -x ./gradlew ] \
  || say "WARNING: no ./gradlew wrapper here yet. Install WPILib 2027 and create the robot project when ready."

# Pin the complete settings template before ANY project file is written. This is deliberately
# broader than another deploy-rule enumeration: a release author may change the template, but must
# update this one canonical digest in the same source change. A hash command is a producer, not a
# predicate: only status 0 plus one well-formed SHA-256 value reaches the equality test. Failure,
# missing tools, or malformed/empty output means the validation could not run and is not reported as
# a content mismatch.
SETTINGS_TEMPLATE_SHA256='7deb4aa8014936bf9caf3810a038e4242d64afeb621753a73e239571de3498e3'
settings_hash_output=""
settings_hash_rc=127
set +e
if command -v sha256sum >/dev/null 2>&1; then
  settings_hash_output=$(sha256sum < "$SETTINGS_TEMPLATE_PATH" 2>/dev/null)
  settings_hash_rc=$?
elif command -v shasum >/dev/null 2>&1; then
  settings_hash_output=$(shasum -a 256 < "$SETTINGS_TEMPLATE_PATH" 2>/dev/null)
  settings_hash_rc=$?
fi
set -e
if [ "$settings_hash_rc" -ne 0 ]; then
  die 14 "baseline source files missing or unreadable — could not validate $SETTINGS_TEMPLATE_PATH against this release's SHA-256 pin (no working sha256sum or shasum; hash command status $settings_hash_rc)"
fi
# READ THE HASH, NOT THE SEPARATOR. This previously stripped a literal two-space `  -` suffix and
# required the remainder to be exactly that shape. GNU coreutils emits `<hash>  -` when it reads
# stdin in text mode and `<hash> *-` in BINARY mode, and the sha256sum shipped with Git for Windows
# emits the binary form. Measured 2026-09-04 on windows-latest, the first Windows execution this
# project has ever had: sha256sum was present at /usr/bin/sha256sum, ran fine, and the installer
# still died with exit 14 saying no 64-character result was emitted -- because it was parsing the
# mode marker rather than the digest. Take the leading 64 hex characters and ignore what follows.
settings_template_sha256=$(printf '%s\n' "$settings_hash_output" \
  | sed -n 's/^\([0-9a-fA-F]\{64\}\).*/\1/p' | head -1 | tr 'A-F' 'a-f')
if [ "${#settings_template_sha256}" -ne 64 ]; then
  die 14 "baseline source files missing or unreadable — could not validate $SETTINGS_TEMPLATE_PATH against this release's SHA-256 pin (the hash command did not emit one recognized 64-character result)"
fi
case "$settings_template_sha256" in
  *[!0123456789abcdef]*)
    die 14 "baseline source files missing or unreadable — could not validate $SETTINGS_TEMPLATE_PATH against this release's SHA-256 pin (the hash command emitted a malformed value)" ;;
esac
[ "$settings_template_sha256" = "$SETTINGS_TEMPLATE_SHA256" ] \
  || die 14 "baseline source files missing or unreadable — $SETTINGS_TEMPLATE_PATH does not match this release's pinned SHA-256 digest"

# The permission rules this baseline installs carry a vendor-stated version requirement: per
# code.claude.com/docs/en/permissions.md (verified 2026-08-21), a Read deny rule covers the Edit tool
# from v2.1.208 and the Write tool from v2.1.228, and the startup warning about an ineffective
# path-rule form appears from v2.1.210. The floor is the highest of the three. Until now no run ever
# mentioned it, and the document that explains it is not installed on a team machine, so a team below
# the floor got the same successful install as a team above it.
#
# This REPORTS every outcome and blocks none of them, which is the same policy as the jq and gradlew
# warnings above. Three outcomes are warnings -- a version below the floor, a version string this
# cannot read, and no `claude` on the PATH -- and the fourth, a version at or above the floor, is an
# informational line rather than a warning. A version it cannot parse and a `claude` it cannot find
# are each reported as NOT CHECKED, never as checked and fine. Nothing else about the installed
# version is examined, and nothing here re-checks it after the run.
CLAUDE_VERSION_FLOOR=2.1.228
version_below() { # a b -> status 0 when dotted version a is strictly below dotted version b
  vb_a_major=${1%%.*}; vb_a_rest=${1#*.}; vb_a_minor=${vb_a_rest%%.*}; vb_a_patch=${vb_a_rest#*.}
  vb_b_major=${2%%.*}; vb_b_rest=${2#*.}; vb_b_minor=${vb_b_rest%%.*}; vb_b_patch=${vb_b_rest#*.}
  if [ "$vb_a_major" -ne "$vb_b_major" ]; then [ "$vb_a_major" -lt "$vb_b_major" ]; return; fi
  if [ "$vb_a_minor" -ne "$vb_b_minor" ]; then [ "$vb_a_minor" -lt "$vb_b_minor" ]; return; fi
  [ "$vb_a_patch" -lt "$vb_b_patch" ]
}
if command -v claude >/dev/null 2>&1; then
  # The version string is taken only when it matches three dot-separated runs of digits at the start
  # of the output. Anything else is an unread version, not a zero.
  CLAUDE_VERSION_RAW=$(claude --version </dev/null 2>/dev/null) || CLAUDE_VERSION_RAW=""
  CLAUDE_VERSION=$(printf '%s\n' "$CLAUDE_VERSION_RAW" \
    | sed -n 's/^\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' | head -1)
  if [ -z "$CLAUDE_VERSION" ]; then
    say "WARNING: no version number could be read out of 'claude --version', so this run did NOT check the Claude Code version against this baseline's floor of v$CLAUDE_VERSION_FLOOR. Check it yourself."
  elif version_below "$CLAUDE_VERSION" "$CLAUDE_VERSION_FLOOR"; then
    say "WARNING: Claude Code $CLAUDE_VERSION is below this baseline's floor of v$CLAUDE_VERSION_FLOOR. Below that floor the vendor's permissions documentation does not establish that a write to a path this baseline's settings template denies is checked at all. Upgrade Claude Code."
  else
    say "  Claude Code    $CLAUDE_VERSION — at or above this baseline's floor of v$CLAUDE_VERSION_FLOOR. Nothing else about this version was checked."
  fi
else
  say "WARNING: no 'claude' executable on this PATH, so this run did NOT check the Claude Code version against this baseline's floor of v$CLAUDE_VERSION_FLOOR. Check it yourself with: claude --version"
fi

# ============================================================================================
STEP="ignore rules"
# ============================================================================================
# ORDERING REQUIREMENT, not a content one: this block runs immediately after the precondition
# checks and BEFORE any other file is created. A gitignore that predates the first key. Once a
# credential is committed even once, removing it from the working tree does not remove it from
# history, and a student cannot un-ring that bell.
#
# Nothing credential-bearing sits between the precondition checks and here today. That is the
# point: ordering that is incidental rather than specified is lost the first time someone adds a
# credential-adjacent template above it.
# BOTH markers are prefixes of real lines in the fragment — MARKER of its first line, END_MARKER of
# its last. Edit them together with the fragment, or the completeness check below stops every run.
# The begin marker ALONE is not accepted as the block: a .gitignore truncated to the first line, or
# an append interrupted partway, carries the begin marker while the credential entries the block
# exists for are absent — and the old marker-substring check read exactly that state as
# "already carries the managed block", exit 0. The check is ORDER-AWARE: an end marker appearing
# BEFORE the begin marker is not a closed block either, and an unordered test would accept it.
MARKER='# --- Unlabs AI Toolkit for FRC 2027 Season Teams (managed block'
END_MARKER='# --- end Unlabs AI Toolkit for FRC 2027 Season Teams managed block'
FRAGMENT="$SRC_DIR/baseline/templates/gitignore-fragment.txt"
MARKER_STATE=absent
[ ! -L .gitignore ] \
  || die 19 "the managed .gitignore block was NOT checked or written — .gitignore is a symbolic link, so appending would write to its target instead of a regular project file. Replace it with a regular .gitignore inside this repository, then run again."
{ [ ! -e .gitignore ] || [ -f .gitignore ]; } \
  || die 19 "the managed .gitignore block was NOT checked or written — .gitignore exists and is not a regular file, so it was left unchanged instead of being opened for a scan or append. Replace it with a regular .gitignore inside this repository, then run again."
if [ -f .gitignore ]; then
  # ORDER-AWARE for the markers (unchanged from the check above this one), and now CONTENT-AWARE
  # too: matching markers with nothing real between them used to read as "complete" -- a .gitignore carrying both marker comments but none of the exclusion
  # lines they bracket scored identically to a real install. The set of lines a "complete" block must
  # contain is read from the shipped fragment ITSELF at run time, rather than retyped into this
  # script a second time.
  #
  # The fragment read is not assumed to have succeeded. `getline line < fragfile` returns -1 on a
  # read error and 0 at end of input, and a test of `> 0` alone cannot tell those apart: with the
  # fragment missing, with a directory named as the fragment, and with an empty fragment, want[] came
  # out EMPTY and a marker-only .gitignore then printed "complete" (all three measured 2026-08-21,
  # gawk 5.2.1). The terminal status is captured, an empty pattern set is refused, and both report
  # source_error -- which the case below turns into exit 14 instead of letting "complete" through.
  MARKER_STATE=$(awk -v begin="$MARKER" -v end="$END_MARKER" -v fragfile="$FRAGMENT" '
    BEGIN {
      while ((read_rc = (getline line < fragfile)) > 0) {
        if (line !~ /^#/ && line != "") { want[line] = 1; nwant++ }
      }
      close(fragfile)
      if (read_rc < 0 || nwant == 0) { source_error = 1; exit }
    }
    index($0, begin) == 1 { seen_begin = 1; next }
    seen_begin && index($0, end) == 1 { found_end = 1; exit }
    seen_begin && ($0 in want) { seen[$0] = 1 }
    END {
      if (source_error) {
        print "source_error"
        exit
      }
      if (!found_end) {
        print (seen_begin ? "malformed" : "absent")
        exit
      }
      nseen = 0
      for (w in want) if (w in seen) nseen++
      print (nseen == nwant ? "complete" : "incomplete")
    }
  ' .gitignore)
fi

case "$MARKER_STATE" in
  source_error)
    die 14 "baseline source files missing or unreadable — could not read the exclusion lines out of $FRAGMENT, so the managed block in .gitignore was not checked against them. Nothing was written. Re-clone or re-download the release."
    ;;
  complete)
    say "  .gitignore     already carries the managed block — unchanged"
    ;;
  malformed)
    die 16 "managed .gitignore block has a begin marker but no later end marker — an interrupted append, or a hand-copied partial block. Open .gitignore, delete the partial block (it begins at the line starting '# --- Unlabs AI Toolkit for FRC 2027 Season Teams (managed block'), then re-run. The full block is at $FRAGMENT."
    ;;
  incomplete)
    die 17 "managed .gitignore block has both markers but is missing one or more of the exclusion lines between them — a hand-edited or partially-merged block. Open .gitignore, delete the block between the line starting '# --- Unlabs AI Toolkit for FRC 2027 Season Teams (managed block' and the line starting '# --- end Unlabs AI Toolkit for FRC 2027 Season Teams managed block', then re-run. The full block is at $FRAGMENT."
    ;;
  absent)
    require_appendable .gitignore
    [ -f .gitignore ] && printf '\n' >> .gitignore
    cat "$SRC_DIR/baseline/templates/gitignore-fragment.txt" >> .gitignore
    say "  .gitignore     managed block appended"
    ;;
esac

# PRESENT IS NOT IN EFFECT -- AND A PROBE PATH PROVES SOMETHING ONLY ABOUT ITSELF. Everything above
# reads the block's TEXT back. Three measured defeats set the shape of what follows.
#
# gitignore is last-match-wins, and a .gitignore in a LOWER directory overrides a higher one
# (gitignore(5): "patterns in the higher level files being overridden by those in lower level files
# down to the directory containing the file"). Three negation lines pasted inside the managed block
# made git report .env and secrets/key NOT ignored while this script printed "already carries the
# managed block" and exited 0, with the banner and the commit instruction.
# A sub/.gitignore holding '!/.env' then left sub/.env trackable while a root .env probe still
# answered "ignored" -- a check that asked about ONE path per exclusion line reported a confirmation
# it had not made (2026-08-22). Asking once per exclusion line PER DIRECTORY fixed that for the lines
# that name a path literally and did NOT fix it for the one line that does not: `.env.*` was turned
# into the invented filename `.env.frc-baseline-probe`, git was asked about THAT, and the run passed
# while .env.production, .env.local and .env.prod were each trackable (measured 2026-08-23 on five
# trees, root and nested). A witness the checker invents for itself is not a witness.
#
# So the block is checked TWO ways and both must answer before this run continues.
#
# ONE -- DERIVED PATHS, and only for the lines that name a path literally. The list is built from the
# SHIPPED fragment, so no path is retyped here, and from the directories that exist right now:
#
#   - an exclusion line with a `/` at its start or in its middle is anchored to the directory of the
#     .gitignore holding it (gitignore(5)), so the block claims only the one path it names, at the
#     root. It is asked about there and nowhere else. Asking about such a line deeper down would
#     manufacture a failure the block never claimed to prevent.
#   - an exclusion line whose only `/` is a trailing one matches at any depth, so it is asked about
#     once in EVERY directory that exists in this working tree right now. A trailing slash names a
#     DIRECTORY, and git will not re-include a file whose parent directory is excluded, so the probe
#     filename inside it carries no weight of its own -- only the directory's own fate matters, and
#     that is what the probe reads.
#   - a line carrying `*`, `?`, `[`, `]` or `\` names no single path. It is NOT probed. Inventing a
#     filename for it is the defect above.
#
# TWO -- THE PATHS GIT KNOWS ABOUT HERE, which needs no invented name at all. Of the paths git knows
# about in this project and has NOT committed -- the set built at the call site below, which is every
# path `git status` reports as untracked-and-not-ignored, as recorded by `git add -N`, or as an
# addition in the index, because a path in the INDEX is not in `--others` and an intent-to-add
# credential escaped an earlier build on exactly that -- does the managed block's own text name any
# of them? Note that such a path need not be a file sitting in the working tree: a path staged and
# then deleted from the working tree is still in the index, and the next commit still records it.
# That is
# asked in a scratch repository whose ONLY ignore input is the shipped fragment, so the answer is
# about the block and nothing else. Three things leak into a naive scratch repo and all three were
# measured doing it on 2026-08-23: a configured init.templateDir seeds a new repository's
# info/exclude (a template naming CLAUDE.md made an earlier draft of this check report CLAUDE.md,
# which the block never mentions); core.excludesFile applies to every repository the user creates (a
# global `*.log` made the same draft report debug.log); and core.ignorecase is detected per
# repository from its filesystem, so a scratch repo on another mount can fold case differently.
# --template= with an empty directory, core.excludesFile=/dev/null and a carried core.ignorecase
# close all three.
#
# WHAT THE TWO TOGETHER ESTABLISH, exactly: git ignores each listed path, and of the paths git knows
# about here and has not committed, the block's text names none that git can still see. Neither is a
# statement about the patterns in general, and no install-time check could be one. A directory
# created after this run, a file created after it, and any later edit to any .gitignore are all
# outside both -- nothing here would notice a sub/.gitignore added tomorrow, and nothing re-asks any
# of this afterwards except the pre-deploy runner, which asks about its own verdict path and no
# other. For a wildcard line, check
# TWO is the ONLY thing that speaks for it, so what is established about `.env.*` is bounded to the
# uncommitted paths that exist at this moment and nothing else. A credential that was ALREADY
# COMMITTED before this block existed is outside both checks, and that is a decision rather than an
# oversight: .gitignore does not apply to a tracked file (gitignore(5)), so the block neither covers
# such a file nor failed on it, and a check that reported one would name a defeat that did not happen.
# It would also stop a run for a reason the block cannot fix: measured 2026-08-22 with a producer
# widened to every path differing from HEAD, a project that had committed a path this block names
# exited 19 on a run made while that path differed from HEAD, and 0 on a run made when it did not.
# Removing such a file from the working tree does not remove it from history either, and this script
# says nothing about that case.
#
# A git that returns an error instead of an answer stops the run: a check that did not run has not
# passed.
IGNORE_PROBE=frc-baseline-probe
# Holds the place of a newline inside a filename while NUL-separated output is converted to
# one-record-per-line below. This byte is NOT forbidden in a pathname -- POSIX forbids only NUL and
# `/` in a component, and a file named with a 0x01 byte was created successfully on this machine
# (measured 2026-08-22) -- it is one that does not occur in practice. If one ever did, the COUNT
# below is still right, because the substitution happens before the record split; only the display
# would be wrong, showing that byte as \n.
NEWLINE_MARK=$'\001'
IGNORE_WORK=""
trap 'if [ -n "$IGNORE_WORK" ]; then rm -rf "$IGNORE_WORK"; fi' EXIT

# The directories that exist here now, root included. `find` frames its output with NUL, and the two
# `tr` calls move any newline inside a name out of the way and then turn the NUL separators into
# newlines — the same idiom CHECK TWO uses below on git's NUL-separated answers, for the same
# reason. One record per line, and every record that survives carries the bytes that are on disk.
#
# WHY NOT `find ... -print` CAPTURED DIRECTLY, WHICH IS WHAT THIS WAS. That form frames on newlines,
# and command substitution then strips every trailing newline off what it captured, so a directory
# whose NAME ENDS IN A NEWLINE lost the only byte that would have shown it: `find` emitted `./zz`,
# newline, newline; the strip removed the second one and the empty-record skip below removed what
# was left, and this walk read the real directory `zz<newline>` as `zz`. Measured 2026-08-22 against
# 8a645ae in a scratch repository holding directories `normal` and `zz<newline>`, with a
# `zz<newline>/.gitignore` line `!.env`: the run exited 0, printed `Unlabs AI Toolkit for FRC 2027 Season Teams <version>
# installed.` and the `git add` commit instruction, and reported that it had asked git about 9 paths
# across 3 directories and that git ignores every one of them. The third of those directories is
# `zz<newline>`; the path this walk actually derived for it, `zz/.env`, does not exist, and
# `git check-ignore --no-index` on the real `zz<newline>/.env` exited 1 while `git status` reported
# it untracked. Reproduced identically under a real bash 3.2.57.
#
# WHAT THIS DOES AND DOES NOT DO. It does not teach the rest of this check to carry a newline in a
# pathname: the comparison below matches git's answers against the sent paths one per LINE, so such
# a path would break that framing too. It makes the run STOP rather than report a clearance covering
# a directory it never asked about. NEWLINE_MARK is 0x01, so a directory name that already contains
# a 0x01 byte reaches the same stop; the message names both bytes rather than asserting which it was.
#
# Every record is either `.` or begins with `./`, because a path component cannot contain a `/`. A
# record that is neither — the EMPTY record included, which this walk used to skip — is a framing
# break and stops the run.
#
# A leading double quote used to be refused here as well, because 'git check-ignore --stdin' without
# -z reads one as the start of a quoted path. The paths are handed to git NUL-separated below, and in
# that form git quotes nothing and parses nothing, so that refusal was removed rather than kept as a
# guard against a hazard this code no longer has. Measured 2026-08-22 under git 2.43.0: a directory
# named `"quoted` made the non-`-z` form exit `fatal: line is badly quoted`, and made the `-z` form
# return the path unchanged.
tree_dirs=$(find . -name .git -prune -o -type d -print0 | tr '\n' "$NEWLINE_MARK" | tr '\0' '\n') \
  || die 19 "the managed .gitignore block was NOT checked — listing this project's directories failed, so the paths to ask git about could not be built. Nothing further was written."
dir_count=0
while IFS= read -r walk_dir; do
  case "$walk_dir" in
    *"$NEWLINE_MARK"*)
      die 19 "the managed .gitignore block was NOT checked — a directory name in this project contains a newline or a 0x01 byte, so the list of directories to ask git about could not be framed. Nothing further was written."
      ;;
    .) ;;
    ./*) ;;
    *)
      die 19 "the managed .gitignore block was NOT checked — this project's directory list held a record that is neither the repository root nor a path under it, so the list of directories to ask git about could not be framed. Nothing further was written."
      ;;
  esac
  dir_count=$((dir_count + 1))
done <<< "$tree_dirs"

# The derivation, and what it refuses to guess at. A leading `/` is dropped, because the probe is
# evaluated from the directory that `/` anchors to; a trailing `/` gets a probe filename appended.
# A line carrying a gitignore metacharacter is counted and skipped, not turned into a path.
ANCHORED_PROBES=()
UNANCHORED_PROBES=()
anchored_n=0
unanchored_n=0
wild_n=0
while IFS= read -r frag_line || [ -n "$frag_line" ]; do
  case "$frag_line" in ''|'#'*|'!'*) continue ;; esac
  case "$frag_line" in
    *'*'*|*'?'*|*'['*|*']'*|*'\'*) wild_n=$((wild_n + 1)); continue ;;
  esac
  probe=${frag_line#/}
  case "$probe" in */) probe="${probe}${IGNORE_PROBE}" ;; esac
  case "${frag_line%/}" in
    */*) ANCHORED_PROBES[anchored_n]="$probe"; anchored_n=$((anchored_n + 1)) ;;
    *)   UNANCHORED_PROBES[unanchored_n]="$probe"; unanchored_n=$((unanchored_n + 1)) ;;
  esac
done < "$FRAGMENT"
probe_count=$((anchored_n + unanchored_n * dir_count))

# Working files live inside .git/: `find` prunes it and `git ls-files` never lists it, so this check
# cannot see its own scratch files, and a TMPDIR pointing inside the project cannot inject one into
# the candidate list. `mktemp -d` creates the top-level directory atomically; only after that succeeds
# is its path assigned to IGNORE_WORK, so the EXIT trap above removes only a directory this invocation
# created.
IGNORE_GITDIR=$(git rev-parse --git-dir 2>/dev/null) \
  || die 19 "the managed .gitignore block was NOT checked — this project's git directory could not be located, so the check had nowhere to put its working files. Nothing further was written."
ignore_work_created=$(mktemp -d "$IGNORE_GITDIR/frc-baseline-ignore-check.XXXXXX") \
  || die 19 "the managed .gitignore block was NOT checked — a unique working directory for the check could not be created atomically under .git/. Nothing further was written."
IGNORE_WORK="$ignore_work_created"
mkdir -p "$IGNORE_WORK/tmpl" \
  || die 19 "the managed .gitignore block was NOT checked — a working directory for the check could not be created under .git/. Nothing further was written."

# The list is STREAMED rather than accumulated in a variable. Growing one shell string by thousands
# of appends is quadratic: on a project carrying a build tree (3067 directories, 9204 paths) the
# accumulating version took 23 seconds under bash 5 and 74 under bash 3.2, and a check slow enough
# that a student kills it is a check that did not run.
emit_probes() {
  ep_i=0
  while [ "$ep_i" -lt "$anchored_n" ]; do
    printf '%s\0' "${ANCHORED_PROBES[ep_i]}"
    ep_i=$((ep_i + 1))
  done
  [ "$unanchored_n" -gt 0 ] || return 0
  while IFS= read -r ep_dir; do
    [ -n "$ep_dir" ] || continue
    if [ "$ep_dir" = "." ]; then ep_pfx=""; else ep_pfx="${ep_dir#./}/"; fi
    ep_i=0
    while [ "$ep_i" -lt "$unanchored_n" ]; do
      printf '%s\0' "$ep_pfx${UNANCHORED_PROBES[ep_i]}"
      ep_i=$((ep_i + 1))
    done
  done <<< "$tree_dirs"
}

# The paths go to git NUL-separated and come back NUL-separated. WITHOUT -z, git check-ignore
# C-QUOTES any path it prints that contains a tab, a backslash, a double quote or a byte above ASCII
# -- so the comparison below, which matches git's output against the raw paths that were sent, read
# every such path as one git had NOT answered about. Measured 2026-08-22 against the round-3 bytes:
# twelve directories whose names contain a tab, plus one genuinely trackable `zz-victim/.env`,
# produced 49 paths reported as not ignored; all ten the message displayed were tab-named paths that
# git does in fact ignore, and the one real credential was pushed past the 10-path cap and never
# displayed at all. Measured 2026-08-22 under git 2.43.0: with -z the same path comes
# back as the raw bytes that were sent. The probes themselves contain no newline -- the walk above
# stops the run on a directory name that does, and a fragment line is read a line at a time -- so
# converting the two NUL-separated files to lines for the comparison below is lossless here.
emit_probes > "$IGNORE_WORK/probes0"
tr '\0' '\n' < "$IGNORE_WORK/probes0" > "$IGNORE_WORK/probes"
check_rc=0
git check-ignore -z --stdin --no-index < "$IGNORE_WORK/probes0" > "$IGNORE_WORK/ignored0" 2>/dev/null \
  || check_rc=$?
# check-ignore answers 0 when at least one path given to it is ignored and 1 when none is. Anything
# above that is an error rather than an answer, and an error is not a pass.
[ "$check_rc" -le 1 ] \
  || die 19 "the managed .gitignore block was NOT checked — git check-ignore exited $check_rc instead of answering, so the check did not run. Nothing further was written."
tr '\0' '\n' < "$IGNORE_WORK/ignored0" > "$IGNORE_WORK/ignored"
# In this form check-ignore prints one line for each path it was given that git ignores, and nothing
# at all for one it does not. A path re-included by a negation pattern is a path git does not ignore,
# and it is omitted here rather than reported as a match -- which is why this counts the answers
# rather than reading the pattern that matched. Equal counts means every path came back ignored.
ignored_n=$(wc -l < "$IGNORE_WORK/ignored")
ignored_n=${ignored_n// /}
if [ "$ignored_n" -ne "$probe_count" ]; then
  # Naming what is not ignored is ONE pass over two lists, not one git process per path. Round 2 ran
  # a git call per path and grew a shell string by append: on a 3067-directory project that took 11
  # seconds and printed 3632 lines at a student. Both are defects, not costs. The printed list is
  # bounded and says how much it left out.
  awk 'NR==FNR { seen[$0] = 1; next } !($0 in seen)' \
      "$IGNORE_WORK/ignored" "$IGNORE_WORK/probes" > "$IGNORE_WORK/unignored"
  unignored_n=$(wc -l < "$IGNORE_WORK/unignored")
  unignored_n=${unignored_n// /}
  # The two passes must agree. If the count says some path is not ignored and the comparison cannot
  # find one, this run has no answer to report, and no answer is not a pass.
  [ "$unignored_n" -gt 0 ] \
    || die 19 "the managed .gitignore block was NOT checked — git check-ignore reported $ignored_n of the $probe_count paths as ignored, but comparing the two lists found no path it does not ignore. The two answers disagree, so this run has no usable answer. Nothing further was written."
  unignored_shown=$(head -n 10 "$IGNORE_WORK/unignored" | sed 's/^/    /')
  unignored_more=""
  if [ "$unignored_n" -gt 10 ]; then
    unignored_more="
    ... and $((unignored_n - 10)) more. $unignored_n path(s) are not ignored in total; this list stops
    at the first 10 on purpose, because one re-included line in a large project produces one path per
    directory and a message thousands of lines long is not a message."
  fi
  die 19 "git does NOT ignore the following path(s), each of which an exclusion line of the managed .gitignore block names:
$unignored_shown$unignored_more

gitignore is last-match-wins, and a .gitignore in a lower directory overrides a higher one, so a line AFTER the ones this block installs is re-including them. Look for that line in .gitignore itself — below the managed block or pasted inside it — and in any .gitignore in a directory on the way down to a path named above. Remove it, then run this again. The full block is $FRAGMENT."
fi

# CHECK TWO. The candidate list is collected BEFORE the scratch repository exists, so nothing this
# check creates can appear in it.
#
# WHAT IS ON THE LIST, and why it took three builds to get here. The question is which paths git
# knows about in this project that it has NOT committed, and `git status` answers all of it in one
# call. The first build asked `git ls-files --others --exclude-standard`, which returns paths that
# are not in the index (git-ls-files(1)), so a path put INTO the index escaped it -- including one
# recorded by `git add -N`, which adds a contentless index entry whose content a later `git add .`
# still stages (git-add(1)). Measured 2026-08-22: create .env.production, run
# `git add -N .env.production`, install the intact block with a later `!.env.production`, and that
# build exits 0 and prints the banner and the commit instruction while `git add .` stages the
# credential. The next build added `git diff --diff-filter=A HEAD` beside it, closed that one, and
# missed two more -- both measured on 2026-08-22 handing the credential to a plain `git commit`:
# a path staged and then DELETED from the working tree (`git add .env.production; rm .env.production`
# -- the working-tree diff emits nothing, and `git commit` recorded the staged blob), and a
# `git mv team-notes.txt .env.production` of an already-tracked file onto a name the block excludes
# (reported as a rename, so the addition filter emitted nothing, and `git commit` created
# HEAD:.env.production holding the credential).
#
# THE STATUS CODES ARE WHAT SELECT THE LIST, and they are read as COLUMNS rather than matched as a
# fixed set of pairs. Porcelain v1 prints two per path: the first compares the INDEX against HEAD,
# the second compares the WORKING TREE against the index (git-status(1)). `A` in the FIRST column
# says "git has this and HEAD does not" whatever the second column says, EXCEPT where that pair is
# one of git's unmerged codes, which are taken out first -- so `A `, `AM`, `AD` and `AT` are all on
# the list, and a code of that shape this git does not print yet would be too. `??` is an untracked
# path git does not ignore. ` A` is the intent-to-add entry above. The codes left over describe a
# modification, a deletion or a type change of a path git already tracks, so HEAD contains it and
# putting one on the list would name a defeat that did not happen. Matching a fixed set of pairs
# instead would be the same mistake as inventing a probe filename: it would answer only for the
# codes someone thought of.
#
# UNMERGED codes are skipped, and this is the one place the list is deliberately short. While any
# path is unmerged git will not make a commit at all -- measured 2026-08-22 at git 2.43.0,
# `git commit` with an unmerged .env.production present exited 128 and recorded nothing, and the
# same commit succeeded the moment the conflict was resolved with `git add` -- so an unmerged path
# is not one commit away from being carried, which is the question this check asks. It is not
# covered either: that `git add` is what makes it committable, and only a run made after it would
# see the result. That is a residual this check states rather than closes, and the fixture asserts
# git's refusal rather than assuming it, so a git that stopped refusing would turn the leg red.
#
# `--no-renames` IS NOT COSMETIC. With rename detection on, a renamed path is printed as `R ` and
# then TWO NUL-separated fields rather than one, so a reader taking one record at a time reads the
# old pathname as the next record and mis-frames every record after it. Measured 2026-08-22 at git
# 2.43.0: `git mv team-notes.txt .env.production` printed `R  .env.production`, NUL,
# `team-notes.txt`, NUL. With detection off the same state prints as `D  team-notes.txt` and
# `A  .env.production`, which is what this list wants anyway. The third byte of a porcelain v1
# record is a space; a record whose third byte is not a space is a framing break rather than a path,
# and it stops the run instead of being parsed. That guard is a backstop for exactly the case above
# -- measured catching it at git 2.43.0 -- and it is not a general parser: a mis-framed record that
# happens to carry a space in that position would pass it.
#
# A path already IN HEAD is deliberately NOT on this list, and that is the residual this check states
# rather than covers. .gitignore does not apply to a file git already tracks (gitignore(5)), so the
# block did not fail on it and there is no defeat to report. Measured 2026-08-22 with the producer
# widened to every path differing from HEAD (`--diff-filter=d`): a project that had committed a path
# this block names exited 19 on a run made while that path differed from HEAD, and 0 on a run made
# when it did not -- so the widened form reports a defeat that did not happen, and reports it or not
# depending on whether the tree happens to be dirty.
#
# The whole list is ONE git process and one pass of shell builtins over its output -- no process per
# path, and no shell string grown by append. It is not free, and the cost is stated here rather than
# buried. Measured 2026-08-22 on a project of 3,667 directories carrying 10,804 uncommitted paths:
# the status call 0.02s and the loop below 0.14s under bash 5.2.21 and 0.40s under bash 3.2.57,
# taking a whole install from 0.33-0.47s to 0.49-0.58s under bash 5.2.21 and from 0.43-0.47s to
# 0.85-0.99s under bash 3.2.57. On the same project with everything committed the loop has nothing
# to read and the install is not slower at all. The cost is linear in the number of uncommitted
# paths, and it is what seeing a STAGED credential costs.
cand_rc=0
git status --porcelain=v1 -z --untracked-files=all --no-renames \
    > "$IGNORE_WORK/status0" || cand_rc=$?
[ "$cand_rc" -eq 0 ] \
  || die 19 "the managed .gitignore block was NOT checked — listing the paths in this project that git knows about and has not committed failed (exit $cand_rc), so those paths could not be compared against the block. Nothing further was written."
# One record per path, NUL-terminated, so a pathname containing a space, a tab, a newline or a byte
# that is not valid UTF-8 arrives as the bytes it really is. The offsets below are into the two
# status columns and the single space after them, which are ASCII whatever the pathname holds.
cand_parse_rc=0
while IFS= read -r -d '' status_record; do
  [ "${#status_record}" -ge 4 ] || { cand_parse_rc=2; break; }
  [ "${status_record:2:1}" = " " ] || { cand_parse_rc=2; break; }
  status_xy=${status_record:0:2}
  status_path=${status_record:3}
  case "$status_xy" in
    DD|AU|UD|UA|DU|AA|UU) ;;
    '??'|' A'|A?) printf '%s\0' "$status_path" ;;
  esac
done < "$IGNORE_WORK/status0" > "$IGNORE_WORK/candidates"
[ "$cand_parse_rc" -eq 0 ] \
  || die 19 "the managed .gitignore block was NOT checked — git status returned a record this run could not frame as a path, so it has no usable answer about which of this project's files the block names. Nothing further was written."
# The size of the list is printed, so a run that compared nothing says so rather than reading as a
# comparison that found nothing.
cand_n=0
covered_n=0
if [ -s "$IGNORE_WORK/candidates" ]; then
  cand_n=$(tr '\n' "$NEWLINE_MARK" < "$IGNORE_WORK/candidates" | tr '\0' '\n' | wc -l)
  cand_n=${cand_n// /}
  # Ask git itself for `false` when the key is unset. Any nonzero result is therefore a failure to
  # answer, not an absent value, and must stop the run rather than change the comparison's case
  # semantics. `--bool` must also produce one of its two documented canonical values; an empty or
  # malformed answer is not a usable answer.
  ignore_case_rc=0
  ignore_case=$(git config --get --bool --default=false core.ignorecase 2>/dev/null) || ignore_case_rc=$?
  [ "$ignore_case_rc" -eq 0 ] \
    || die 19 "the managed .gitignore block was NOT checked — reading core.ignorecase failed (exit $ignore_case_rc), so the block could not be compared against this project's files with this repository's case semantics. Nothing further was written."
  case "$ignore_case" in
    true|false) ;;
    *) die 19 "the managed .gitignore block was NOT checked — git config did not return a boolean core.ignorecase value, so the block could not be compared against this project's files with this repository's case semantics. Nothing further was written." ;;
  esac
  ( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
    git init -q --template="$IGNORE_WORK/tmpl" "$IGNORE_WORK/scratch" ) >/dev/null 2>&1 \
    || die 19 "the managed .gitignore block was NOT checked — a scratch repository for comparing the block against this project's files could not be created. Nothing further was written."
  cp "$FRAGMENT" "$IGNORE_WORK/scratch/.gitignore" \
    || die 19 "the managed .gitignore block was NOT checked — $FRAGMENT could not be read, so there was nothing to compare this project's files against. Nothing further was written."
  covered_rc=0
  ( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
    git -C "$IGNORE_WORK/scratch" -c core.excludesFile=/dev/null -c core.ignorecase="$ignore_case" \
        check-ignore -z --stdin --no-index < "$IGNORE_WORK/candidates" ) > "$IGNORE_WORK/covered" 2>/dev/null \
    || covered_rc=$?
  [ "$covered_rc" -le 1 ] \
    || die 19 "the managed .gitignore block was NOT checked — git check-ignore exited $covered_rc instead of answering which of this project's files the block names, so the check did not run. Nothing further was written."
  if [ -s "$IGNORE_WORK/covered" ]; then
    # git answered NUL-separated, and a filename may itself contain a newline. Converting NUL
    # straight to newline would split one such name across two displayed lines and count it as two
    # files. Each embedded newline is moved out of the way FIRST, so one line here is one file both
    # for the count and for the display, and the display puts the two characters \n where the
    # newline was rather than presenting a name that is not the one on disk.
    tr '\n' "$NEWLINE_MARK" < "$IGNORE_WORK/covered" | tr '\0' '\n' > "$IGNORE_WORK/covered_lines"
    covered_n=$(wc -l < "$IGNORE_WORK/covered_lines")
    covered_n=${covered_n// /}
    covered_shown=$(head -n 10 "$IGNORE_WORK/covered_lines" | sed "s/$NEWLINE_MARK/\\\\n/g; s/^/    /")
    covered_more=""
    if [ "$covered_n" -gt 10 ]; then
      covered_more="
    ... and $((covered_n - 10)) more. $covered_n file(s) in total; this list stops at the first 10."
    fi
    die 19 "git does not ignore the following path(s), git has not committed them, and the managed .gitignore block's own text names them:
$covered_shown$covered_more

What it takes to get one of these into a commit depends on how git is holding it right now, and this list does not distinguish them: a path already staged with content is recorded by the very next commit, and one that is only present in the working tree, or recorded only by 'git add -N', is one 'git add' away from that. Both were measured on 2026-08-22. Either way, the block is not what is keeping it out.

Two things put a path in that list, and this check cannot tell them apart. Either something is re-including it — gitignore is last-match-wins and a .gitignore in a lower directory overrides a higher one, so look for a negation line, one starting with '!', in .gitignore below the managed block, pasted inside it, or in any .gitignore in a directory on the way down to a file named above. Or it was put into git's index deliberately, which 'git add -f' does to a file that IS ignored; 'git status --short' shows such a path as added, and 'git rm --cached' takes it back out. Resolve it, then run this again. The full block is $FRAGMENT."
  fi
fi
say "  .gitignore     git was asked about $probe_count path(s) derived from the exclusion lines that"
say "                 name a path literally — the anchored ones at this repository's root, the rest"
say "                 once in each of the $dir_count directory/directories that exist here now — and it"
say "                 ignores every one of them. $wild_n line(s) carry a wildcard and were NOT turned"
say "                 into a path; for those, and for every other line, the $cand_n path(s) git knows"
say "                 about here and has not committed were compared against the block's own text,"
say "                 and it names none of them. That is the whole of the check. It"
say "                 establishes nothing about a file or a directory created after this run, nothing"
say "                 about a later edit to any .gitignore, and nothing about a path already committed."

# ============================================================================================
STEP="baseline files"
# ============================================================================================
mkdir -p .claude/frc

# An existing path used to be reported as "unchanged" and counted as a successful install without
# anything establishing that it was this baseline's file at all. These are
# verbatim copies, so the confirmation available is the strongest one: byte equality with the source.
# A path that is not byte-identical is left exactly as found, named, and carried to the end of the
# run as NOT CONFIRMED -- the message asserts no reason for the difference, because this test cannot
# tell a hand-edited file from a comparison that could not be made.
install_if_absent() { # src dst
  case "$2" in
    */*) refuse_symlink_components "${2%/*}" ;;
  esac
  if [ -e "$2" ] || [ -L "$2" ]; then
    if [ ! -L "$2" ] && [ -f "$2" ] && cmp -s "$1" "$2"; then
      say "  ${2}  exists — byte-identical to the copy this baseline ships"
    else
      say "  ${2}  exists — left unchanged, NOT confirmed to be the copy this baseline ships"
      note_unconfirmed "$2 (compared against $1)"
      record_exit 20
    fi
  else
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    say "  ${2}  installed"
  fi
}

install_if_absent "$SRC_DIR/baseline/skills/current-wpilib-2027/SKILL.md" \
                  .claude/skills/current-wpilib-2027/SKILL.md
for r in namespaces ref-divergence commands gradle-tasks; do
  install_if_absent "$SRC_DIR/baseline/skills/current-wpilib-2027/references/$r.md" \
                    ".claude/skills/current-wpilib-2027/references/$r.md"
done

install_if_absent "$SRC_DIR/baseline/skills/current-claude-models/SKILL.md" \
                  .claude/skills/current-claude-models/SKILL.md

install_if_absent "$SRC_DIR/baseline/skills/frc-pre-deploy/SKILL.md" \
                  .claude/skills/frc-pre-deploy/SKILL.md
install_if_absent "$SRC_DIR/baseline/skills/frc-pre-deploy/scripts/run-pre-deploy.sh" \
                  .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh
# The mode is changed ONLY on this baseline's own regular, non-symlink copy of the runner: the one
# just written, or a regular, non-symlink file already here that compares equal to it. Every other
# pre-existing path was reported left unchanged and carried to the end of the run as NOT confirmed,
# and the closing message says it was left exactly as found -- so changing its mode would make that
# report false. Measured 2026-08-22 against the round-3 bytes: a differing pre-existing runner at
# mode 0644 exited 20, remained at mode 0644, and was listed under "Left exactly as found". A
# directory fails `-f`; a symlink fails `! -L`; neither reaches `cmp` or has its mode changed.
#
# The chmod's exit status is not what is reported: on a filesystem that does not store a Unix
# executable bit, chmod can exit 0 while changing nothing (measured on a CIFS mount, vers=3.0,
# file_mode=0664: chmod exited 0, the mode did not change, and `-x` stayed false). So the BIT is
# tested after the attempt, and a bit that did not take WARNS and proceeds — the same policy as the
# jq/gradlew warnings above. `-x` is a permission test only; it does not establish that execution
# succeeds on every filesystem. Proceeding must not read as "the runner is executable".
if [ ! -L .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh ] \
   && [ -f .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh ] \
   && cmp -s "$SRC_DIR/baseline/skills/frc-pre-deploy/scripts/run-pre-deploy.sh" \
             .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh; then
  chmod +x .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh 2>/dev/null || true
  if [ ! -x .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh ]; then
    say "WARNING: .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh did not take the executable bit (this filesystem may not store one). Invoke it as: bash .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh"
  fi
else
  say "  .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh  its mode was not changed either. Invoke it as: bash .claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh"
fi
install_if_absent "$SRC_DIR/baseline/agents/frc-docs-checker.md" .claude/agents/frc-docs-checker.md

# The compile-probe driver and its static init script. THE DRIVER IS THE PRIVILEGE BOUNDARY: the
# permission template pre-approves running it, so it must arrive through this installer with the
# rest of the baseline. A driver that appears in a project by any other route is an unexplained
# pre-approved executable, and an assistant that refuses to run one is behaving correctly.
install_if_absent "$SRC_DIR/baseline/tools/frc-docs-probe.sh" .claude/tools/frc-docs-probe.sh
install_if_absent "$SRC_DIR/baseline/tools/frc-docs-probe.init.gradle" \
                  .claude/tools/frc-docs-probe.init.gradle
# The session-start update check. The settings template runs it as `bash <path>`, so it needs no
# execute bit and gets no chmod: nothing here changes a mode on a file this run did not create.
install_if_absent "$SRC_DIR/baseline/tools/frc-version-check.sh" .claude/tools/frc-version-check.sh
# SAME THREE GUARDS AS THE RUNNER ABOVE, AND FOR A STRONGER REASON. This chmod used to test only
# `-f` and `! -x`. A pre-existing driver that DIFFERS from the shipped one is recorded exit 20 and
# reported "Left exactly as found -- contents and modes both", yet this line made it executable
# anyway; and a symlink here was followed, changing an external target's mode. Both contradict
# the documented promise that a pre-existing file is left "exactly as found -- contents and
# modes both".
# The driver is the privilege boundary the note above describes, so making an UNVERIFIED one
# executable is the worst version of this defect. Found 2026-09-08.
if [ ! -L .claude/tools/frc-docs-probe.sh ] \
   && [ -f .claude/tools/frc-docs-probe.sh ] \
   && cmp -s "$SRC_DIR/baseline/tools/frc-docs-probe.sh" .claude/tools/frc-docs-probe.sh; then
  chmod +x .claude/tools/frc-docs-probe.sh 2>/dev/null || true
  if [ ! -x .claude/tools/frc-docs-probe.sh ]; then
    say "WARNING: .claude/tools/frc-docs-probe.sh did not take the executable bit (this filesystem may not store one). Invoke it as: bash .claude/tools/frc-docs-probe.sh"
  fi
elif [ -e .claude/tools/frc-docs-probe.sh ]; then
  # NO "invoke it as" HERE, DELIBERATELY. This branch is reached only for a path that is NOT this
  # baseline's driver -- a differing file, a symlink, or a directory -- and the permission template
  # pre-approves RUNNING this exact path. Telling anyone how to execute an unverified binary that
  # is already pre-approved is the wrong advice to give at the privilege boundary.
  say "  .claude/tools/frc-docs-probe.sh  left as found, mode unchanged. It is NOT this baseline's driver (it differs, or is a symlink or directory). The permission template pre-approves running this path, so compare it against baseline/tools/frc-docs-probe.sh before anything runs it."
fi
install_if_absent "$SRC_DIR/baseline/skills/frc-behavior-first/SKILL.md" \
                  .claude/skills/frc-behavior-first/SKILL.md

for c in $COMMANDS; do
  install_if_absent "$SRC_DIR/baseline/commands/$c.md" ".claude/commands/$c.md"
done

install_if_absent "$SRC_DIR/baseline/manifest.yml" .claude/frc-baseline-manifest.yml

# Commercial-use notices name COMMERCIAL-LICENSE.md. The destination for this copy is the
# repository top level, so a confirmed install makes that bare project-root path resolve from the
# working directory this script requires. It makes no claim about resolving the bare name relative
# to a nested artifact.
#
# The SOURCE IS baseline/, NOT the checkout's top level. A release is vendored as setup/, baseline/
# and docs/ — measured by test-scaffold.sh's vendored fixture, which copies exactly those three —
# so an installer that reads a top-level file exits 14 inside a vendored copy and installs nothing.
# A first attempt at this change did precisely that and the fixture caught it. The top-level copy
# stays where GitHub serves it and README.md links to it, and CI-26 holds the two byte-identical.
install_if_absent "$SRC_DIR/baseline/COMMERCIAL-LICENSE.md" COMMERCIAL-LICENSE.md

# CLAUDE.md carries the version, install date and baseline source ref in its first-line header,
# outside the marked blocks. For a new file, the installer renders that header from the template.
# For an existing file, the installer confirms the template-defined header shape, current baseline
# version and current source-ref value, while accepting its existing decimal YYYY-MM-DD date text.
# This confirms text, not authorship, committed source bytes or publication of the ref.
#
# An existing CLAUDE.md is still left exactly as found. The check is narrow, and is reported as
# narrow: the first-line header and the three marked blocks this template ships are checked.
# Everything else -- which includes anything a team added -- is NOT compared, which is also why a
# team's own edits do not trip it.
if [ -L CLAUDE.md ]; then
  claude_md_problem="the path is a symbolic link; its target was not read or written"
  say "  CLAUDE.md      exists — left unchanged. This baseline's content was NOT confirmed:"
  say "                 $claude_md_problem."
  note_unconfirmed "CLAUDE.md ($claude_md_problem; compare a regular project file against $CLAUDE_MD_TEMPLATE_PATH)"
  record_exit 20
elif [ -e CLAUDE.md ]; then
  claude_md_problem=""
  if ! claude_header_matches "$CLAUDE_MD_TEMPLATE_PATH" CLAUDE.md \
         "$BASELINE_VERSION" "$SOURCE_REF"; then
    claude_md_problem="its first-line header was not confirmed to have the template's structure, current baseline version, current source-ref value and decimal YYYY-MM-DD install-date shape"
  fi
  claude_md_absent=""
  for blk in FRC-SAFETY FRC-FIELD-DEFECTS FRC-BEHAVIOR-FIRST; do
    # Both blocks are extracted to ordinary files under the already EXIT-trapped $IGNORE_WORK.
    # This preserves trailing newlines and NULs without shell-variable capture, and — unlike process
    # substitution — lets this shell observe each producer's status before `cmp` runs. A malformed
    # baseline template is a source error (exit 14); a malformed project CLAUDE.md is left untouched,
    # reported as unconfirmed, and carried to exit 20 with an ordinary content difference.
    #
    # `cmp` exits nonzero for a difference and also for trouble reading its inputs. Both land the
    # path in the unconfirmed list and exit 20, so a run that could not answer the comparison reports
    # no confirmation either way.
    tpl_block_file="$IGNORE_WORK/claude-$blk-template"
    have_block_file="$IGNORE_WORK/claude-$blk-project"
    extract_block "$CLAUDE_MD_TEMPLATE_PATH" "$blk" > "$tpl_block_file" \
      || die 14 "baseline source files missing or unreadable — the $blk block could not be extracted from $CLAUDE_MD_TEMPLATE_PATH, so the CLAUDE.md already here was NOT checked against it"
    tpl_block_bytes=$(tr -d '[:space:]' < "$tpl_block_file" | wc -c | tr -d '[:space:]') \
      || die 14 "baseline source files missing or unreadable — the $blk block from $CLAUDE_MD_TEMPLATE_PATH could not be counted, so the CLAUDE.md already here was NOT checked against it"
    [ "$tpl_block_bytes" -gt 0 ] \
      || die 14 "baseline source files missing or unreadable — the $blk markers yielded an EMPTY block in $CLAUDE_MD_TEMPLATE_PATH, so the CLAUDE.md already here was NOT checked against them"
    if extract_block CLAUDE.md "$blk" > "$have_block_file"; then
      cmp -s "$tpl_block_file" "$have_block_file" \
        || claude_md_absent="$claude_md_absent $blk"
    else
      claude_md_absent="$claude_md_absent $blk"
    fi
  done
  if [ -n "$claude_md_absent" ]; then
    [ -z "$claude_md_problem" ] || claude_md_problem="$claude_md_problem; "
    claude_md_problem="${claude_md_problem}marked block(s) not confirmed byte-identical:$claude_md_absent"
  fi
  if [ -n "$claude_md_problem" ]; then
    say "  CLAUDE.md      exists — left unchanged. This baseline's content was NOT all confirmed:"
    say "                 $claude_md_problem."
    note_unconfirmed "CLAUDE.md ($claude_md_problem; compare against $CLAUDE_MD_TEMPLATE_PATH)"
    record_exit 20
  else
    say "  CLAUDE.md      exists — unchanged. Its copies of this baseline's marked blocks are"
    say "                 byte-identical to the template's. Its first-line header has the template's"
    say "                 structure, current baseline version and current source-ref value; only its"
    say "                 decimal YYYY-MM-DD install-date text was accepted as existing text. This"
    say "                 confirms the header text, not who wrote it. Nothing else was compared —"
    say "                 do that by hand against $CLAUDE_MD_TEMPLATE_PATH."
  fi
else
  sed -e "s/__BASELINE_VERSION__/$BASELINE_VERSION/" \
      -e "s/__INSTALL_DATE__/$INSTALL_DATE/" \
      -e "s|__SOURCE_REF__|$SOURCE_REF|" \
      "$CLAUDE_MD_TEMPLATE_PATH" > CLAUDE.md
  say "  CLAUDE.md      installed — fill in the Team conventions section before generating code"
fi

# ============================================================================================
STEP="settings"
# ============================================================================================
# For an existing regular file or directory, leave-it-alone. The one hook v1.0 ships (the update
# check) is informational, so nothing here must be merged into a file a team already owns; the run
# reports when the supplied hook cannot be confirmed in an existing file. A symbolic link at the
# settings path is left untouched and unconfirmed; neither a resolving nor a dangling link is followed.
# What round 2 of this change set altered is what gets REPORTED when one is already there: the old branch
# said "exists -- unchanged" and the run ended in the same success banner whether the existing file
# was a real team config, an empty `{}`, a directory, or text that does not parse as JSON at all.
#
# The question asked here is STRUCTURAL -- membership in .permissions.deny -- not a text search. A
# settings.json listing all four deploy-deny strings under permissions.allow, with no deny array at
# all, satisfied a substring search, was reported as a full count, and exited 0 (B1, measured
# 2026-08-21 against the round-2 bytes). Answering it needs jq; where jq is absent the question is
# not asked, and the run says so and exits 18 rather than reporting a confirmation it did not make.
#
# The question is also asked about EVERY entry of the template's deny array, not only the four naming
# `deploy`. A settings file carrying those four and none of the secret or toolchain path denies used
# to be reported as an install, under a line that said the other rules were not checked. "Not checked" in a message does not stop a team recording the baseline as installed.
SETTINGS_PROBLEM=""
SETTINGS_CREATED=0
if [ -L .claude/settings.json ]; then
  SETTINGS_PROBLEM="the path is a symbolic link; its target was not read or written"
elif [ ! -e .claude/settings.json ]; then
  cp "$SRC_DIR/baseline/templates/settings.json.template" .claude/settings.json
  SETTINGS_CREATED=1
  say "  .claude/settings.json  installed"
elif [ ! -f .claude/settings.json ]; then
  SETTINGS_PROBLEM="the path exists but is not a regular file (for example, a directory)"
elif [ "$HAVE_JQ" -ne 1 ]; then
  SETTINGS_PROBLEM="JSON syntax and permissions.deny membership were not checked because jq is absent from this machine"
else
  json_parse_rc=0
  jq empty .claude/settings.json >/dev/null 2>&1 || json_parse_rc=$?
  case "$json_parse_rc" in
    0) : ;;
    4|5) SETTINGS_PROBLEM="it does not parse as JSON" ;;
    *) SETTINGS_PROBLEM="JSON syntax and permissions.deny membership were not checked because jq exited $json_parse_rc instead of parsing the file" ;;
  esac

  if [ -z "$SETTINGS_PROBLEM" ]; then
    json_single_rc=0
    jq -e -s 'length == 1' .claude/settings.json >/dev/null 2>&1 || json_single_rc=$?
    case "$json_single_rc" in
      0) : ;;
      1) SETTINGS_PROBLEM="it does not contain exactly one top-level JSON value" ;;
      *) SETTINGS_PROBLEM="the number of top-level JSON values and permissions.deny membership were not checked because jq exited $json_single_rc without answering" ;;
    esac
  fi

  if [ -z "$SETTINGS_PROBLEM" ]; then
  # The expected strings are read at run time out of the deny array of the template this repository
  # ships, rather than retyped into this script a second time. They are that array's entries -- rules
  # this repository itself authored -- and not an attempt to enumerate every way a settings file
  # could be unsafe. What is reported below is whether the existing file's permissions.deny array
  # lists each of them. Its permissions.allow array, and every other key in that file, are not
  # examined, and the message below says so rather than leaving it to be assumed.
  deny_raw_rc=0
  deny_raw=$(jq -c -s '
      if length != 1 then error("expected exactly one top-level JSON value")
      else
        .[0].permissions.deny
        | arrays
        | map(select(type == "string"))
        | unique
        | .[]
      end' "$SETTINGS_TEMPLATE_PATH" 2>/dev/null) || deny_raw_rc=$?

  if [ "$deny_raw_rc" -ne 0 ]; then
    SETTINGS_PROBLEM="permissions.deny membership was not checked because jq exited $deny_raw_rc while reading the deny rule strings from the pinned template $SETTINGS_TEMPLATE_PATH"
  elif [ -z "$deny_raw" ]; then
    SETTINGS_PROBLEM="permissions.deny membership was not checked because jq returned no deny rule strings from the pinned template $SETTINGS_TEMPLATE_PATH"
  else

  # Bash 3 compatible on purpose. This installer runs on macOS, where this project's calibration
  # record measured the system bash at 3.2.57. Round 2 built this list with `mapfile`, which that
  # round's independent validation identified as a Bash 4.0 builtin; no 3.2 shell was available to
  # run either version here, so the list is built the portable way instead.
  #
  # `if` rather than `[ -n "$pat" ] && ...` keeps the loop body's last command at status 0 under
  # `set -e`. The list is read back by numeric index rather than by expanding `"${array[@]}"`, whose
  # behaviour on an EMPTY array under `set -u` differs by bash version and was not measured here.
  DENY_STRINGS=()
  denies_total=0
  deploy_denies=0
  while IFS= read -r pat; do
    if [ -n "$pat" ]; then
      DENY_STRINGS[denies_total]="$pat"
      denies_total=$((denies_total + 1))
      case "$pat" in *deploy*) deploy_denies=$((deploy_denies + 1)) ;; esac
    fi
  done <<< "$deny_raw"
  # deploy_denies is report-only here. The complete settings template was checked against this
  # release's canonical SHA-256 pin before any project file was written.

  denies_found=0
  membership_complete=1
  i=0
  while [ "$i" -lt "$denies_total" ]; do
    pat=${DENY_STRINGS[i]}
    membership_rc=0
    jq -e --argjson pat "$pat" '.permissions.deny | arrays | index($pat) != null' \
       .claude/settings.json >/dev/null 2>&1 || membership_rc=$?
    case "$membership_rc" in
      0) denies_found=$((denies_found + 1)) ;;
      1|4) : ;;
      *)
        SETTINGS_PROBLEM="permissions.deny membership was not checked because jq exited $membership_rc instead of answering for rule $((i + 1)) of $denies_total"
        membership_complete=0
        break
        ;;
    esac
    i=$((i + 1))
  done

  if [ "$membership_complete" -eq 1 ] && [ "$denies_found" -lt "$denies_total" ]; then
    SETTINGS_PROBLEM="$((denies_total - denies_found)) of the $denies_total deny rule strings this baseline ships were not found in its permissions.deny array (found $denies_found of $denies_total)"
  elif [ "$membership_complete" -eq 1 ]; then
    say "  .claude/settings.json  exists — unchanged. Its permissions.deny array lists all"
    say "                         $denies_total deny rule strings this baseline ships, the"
    say "                         $deploy_denies deploy ones among them."
    say "                         Its permissions.allow array and every other key in it were NOT"
    say "                         checked — compare those by hand against"
    say "                         $SETTINGS_TEMPLATE_PATH."
  fi
  fi
  fi
fi
# Informational only. A template copied by this run has already passed the SHA-256 preflight, so only
# an existing file needs this independent SessionStart check. The notice never changes the exit code
# and never writes the settings file.
if [ "$SETTINGS_CREATED" -eq 0 ] && [ -f .claude/settings.json ] && [ ! -L .claude/settings.json ]; then
  if [ "$HAVE_JQ" -eq 1 ]; then
    # shellcheck disable=SC2016 # This is the literal command stored in JSON, not an expansion here.
    update_hook_command='bash "${CLAUDE_PROJECT_DIR}/.claude/tools/frc-version-check.sh"'
    if ! jq -e --arg command "$update_hook_command" '
      if (.hooks.SessionStart | type) != "array" then false
      else
        any(.hooks.SessionStart[];
          (.matcher | type) == "string"
          and any(.matcher | split("|")[]; . == "startup" or . == "resume")
          and (.hooks | type) == "array"
          and any(.hooks[];
            .type == "command"
            and (.command | type) == "string"
            and .command == $command
          )
        )
      end
    ' .claude/settings.json >/dev/null 2>&1; then
      say "  NOTE: the supplied update hook could not be confirmed in this .claude/settings.json."
      say "        To use it,"
      say "        copy the \"hooks\" block from $SETTINGS_TEMPLATE_PATH into it."
    fi
  else
    say "  NOTE: the supplied update hook could not be confirmed because jq is unavailable."
    say "        The settings file was left unchanged. Compare its \"hooks\" block against"
    say "        $SETTINGS_TEMPLATE_PATH."
  fi
fi
if [ -n "$SETTINGS_PROBLEM" ]; then
  record_exit 18
  note_unconfirmed ".claude/settings.json ($SETTINGS_PROBLEM)"
  say "  .claude/settings.json  exists — left unchanged, not confirmed"
  say ""
  say "WARNING: an existing .claude/settings.json could not be confirmed to carry this baseline's"
  say "permissions.deny rule strings — $SETTINGS_PROBLEM."
  say "The file was left as found. This step writes nothing to a .claude/settings.json that exists."
  say "Compare it by hand against $SETTINGS_TEMPLATE_PATH."
fi

# ============================================================================================
STEP="done"
# ============================================================================================
# Printed ONLY on success, so a student never sees a commit instruction after a failure. A run that
# recorded a nonzero EXIT_CODE stops HERE, above that banner. Round 2 of this change set put its
# `exit "$EXIT_CODE"` at the BOTTOM of the file instead, which printed "installed." and the git
# commit line and only then exited 18 -- the exact sequence the comment above forbids.
if [ "$EXIT_CODE" -ne 0 ]; then
  say ""
  say "Install incomplete — exit $EXIT_CODE. The warning(s) above name what could not be confirmed."
  if [ -n "$UNCONFIRMED" ]; then
    say ""
    say "Left exactly as found — contents and modes both — and NOT confirmed to carry the content this baseline ships:$UNCONFIRMED"
  fi
  say ""
  say "No commit instruction is printed for a run that did not finish as an unqualified success."
  say "Resolve what the warning above names, then run this again."
  exit "$EXIT_CODE"
fi

say ""
say "Unlabs AI Toolkit for FRC 2027 Season Teams $BASELINE_VERSION installed."
say ""
say "The permission rules in this baseline need Claude Code v$CLAUDE_VERSION_FLOOR or later; below that"
say "version the vendor's permissions documentation does not establish that a write to a path they"
say "deny is checked. Confirm with: claude --version"
say ""
say "THIS BASELINE DOES NOT GATE DEPLOYS. There is no deploy guarantee in v1.0."
say "Run /frc-pre-deploy before deploying and read the verdict — it reports, it does not enforce."
say "/deploy MUST NOT DEPLOY: it walks the checks and prints the command for you to run."
say ""
say "Start every Claude Code session from this repository top level."
say "Claude Code does not load this root .claude/settings.json from a parent when started below it."
say "In the session, run /permissions to confirm the expected deny rules and their source."
say "Run /status to confirm that project settings are active."
say ""
say "Ten commands installed: /subsystem /command /auto /robot-debug /tune /test"
say "                        /vision-integrate /explain /robot-review /deploy"
say "Next: fill in the Team conventions section of CLAUDE.md, then review git status --short."
say "Stage only individual baseline paths you have reviewed from the per-path results above;"
say "do not stage .claude as a directory. Review git diff --cached before committing:"
say ""
say "  git commit -m 'Add Unlabs AI Toolkit for FRC 2027 Season Teams $BASELINE_VERSION'"

# Reached only with EXIT_CODE at 0: the "done" step above returns any nonzero value before the
# banner. Written as a literal 0 so this line cannot become a second, later exit path.
exit 0
