#!/usr/bin/env bash
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
#
# frc-pre-deploy — runs the five validation stages and writes ONE machine-readable verdict.
#
# Upstream: current-wpilib-2027
# Last verified: 2026-09-03
#
# ============================================================================================
# THIS SCRIPT IS THE VERDICT WRITER. ITS READER IS A WITHDRAWN DEPLOY-GATE HOOK RETAINED ONLY IN
# THE BASELINE SOURCE REPOSITORY; THE READER IS NOT INSTALLED ON TEAM MACHINES.
# ============================================================================================
# The two halves were specified in different requests and their schemas DID NOT MATCH: the writer
# spec names `verdict` / `commit` / `timestamp`, the reader requires `pass` / `tree_hash` /
# `timestamp_epoch` / `schema_version`. Only `stages` was common. That is the mutual-deferral
# failure the writer spec explicitly warns about — each half believing the other covered it.
#
# RESOLVED BY EMITTING THE UNION, which is compliant with both: the writer spec says its schema is
# what the file contains "at minimum", so a superset satisfies it, and the reader's required fields
# are all present. `pass` is derived from `verdict`, never set independently — one source of truth
# for the same fact.
#
# A contract test retained only in the baseline source repository exercises compatibility on its
# fixture. It does not establish identical hashing for every valid repository. This writer has
# pathname handling the withdrawn reader lacks; reconcile the implementations before reviving a
# reader.
#
# WHY A SCRIPT AND NOT SKILL PROSE: a verdict a model composes by hand is free text wearing a JSON
# costume. The stage results and the tree hash must be computed, not narrated.

set -u

VERDICT_PATH="${FRC_VERDICT_PATH_OVERRIDE:-.claude/frc/pre-deploy-verdict.json}"
SCHEMA_VERSION=1

# MEASURED 2026-08-09. A real simulation launch confirmed startup in 4.62s (warm cache) on a
# 10-core Apple Silicon Mac, 34 GB, macOS 26.5.2, JDK 26.0.1. The same run proved the task does NOT
# exit on its own: still running at 180.64s.
#
# The ceiling below is ~20x that measurement, because the measurement came from fast hardware and a
# student laptop is the machine that matters. A ceiling calibrated on fast hardware false-fails a
# donated laptop, and a validation step that cries wolf gets skipped.
#
# It is a budget for the startup LINE TO APPEAR, not a run-to-completion time. A simulation has no
# natural end.
SIM_STARTUP_BUDGET_SECONDS="${FRC_SIM_STARTUP_BUDGET_SECONDS:-90}"

# The WORDS INSIDE the line WPILib prints when the robot program is up. Verified at
# v2027.0.0-alpha-6, 2026-08-07, from real output; re-verified UNCHANGED at
# v2027.0.0-alpha-7 on 2026-09-03 in wpilibj-java-2027.0.0-alpha-7-sources.jar
# (TimedRobot.java:88 and OpModeRobot.java:772).
#
# THIS IS NOT WHAT THE STAGE MATCHES ON THE DEFAULT PATH. SIM_READY_LINE below is. Two things read
# this value: a run that overrides it through FRC_SIM_READY_PATTERN, which matches on these words
# alone; and the words-only count, which reports how many lines carried these words while not being
# SIM_READY_LINE.
#
# THIS IS A PRODUCT FACT WITH A REF, NOT A CONSTANT. If WPILib changes the wording, this stage
# reports TIMEOUT rather than pass: fail-closed, correct, and it will look like the tool is broken.
# Re-verify it on any WPILib bump -- that is what the Upstream line at the top of this file is for.
SIM_READY_PATTERN_DEFAULT="Robot program startup complete"
SIM_READY_PATTERN="${FRC_SIM_READY_PATTERN:-$SIM_READY_PATTERN_DEFAULT}"

# THE WHOLE LINE THE FRAMEWORK PRINTS, DECORATION INCLUDED. The words above are what that line
# CONTAINS; this is what the line IS, and the stage below requires the line, not the words.
#
# WHY. A substring test is satisfied by any line that mentions the words anywhere, and the project's
# own code runs BEFORE the framework prints this line. Verified at source in WPILib at commit
# 878da3d54cbc6b64d663bded17d87d5bed040ed9 -- the annotated tag object 440f2eb500... is a TAG, not a
# commit, and dereferences to that commit: Java RobotBase.java:326 prints "Robot program starting"
# and constructs the team's robot at :330; TimedRobot.java:83 calls the team-overridable
# simulationInit() and prints this line only at :87. C++ is the same shape --
# wpilibc/src/main/native/cppcs/RobotBase.cpp:50, and TimedRobot.cpp:23 then :27. So a line printed
# out of the project reaches the log first and satisfies a substring search. MEASURED 2026-08-21
# against this script before this constant existed: a stub whose only output was
# "TEAM-CONSTRUCTOR: Robot program startup complete (framework banner never reached)" produced
# verdict PASS, exit 0, simulate pass, detail beginning "startup confirmed in ~0s".
#
# WHAT IT BUYS AND WHAT IT DOES NOT. Requiring the whole line rejects a line that merely mentions
# the words. It does NOT establish which process printed the line: a project that prints this exact
# line still matches, and no test over log text can separate the two. That is why
# sim_startup_provenance in the verdict reads "not-established" on every run -- this is a stronger
# match, not provenance.
#
# NOT SETTABLE FROM THE ENVIRONMENT, deliberately: a second override would be a second D-051
# surface. When FRC_SIM_READY_PATTERN has a non-default value, the banner is, by the caller's own
# assertion, no longer the shipped one, so the whole-line requirement is not applied for that run --
# and that run already
# writes sim_ready_pattern_overridden: true, which /deploy treats as not clean.
SIM_READY_LINE="********** Robot program startup complete **********"

# Emitted by the generated Gradle init script immediately before the exact, application-backed root
# `run` task executes. This marks task dispatch only -- it is log text, which carries no author --
# and SIM_READY_LINE remains the simulation result.
SIM_TASK_STARTED_LINE="FRC_PRE_DEPLOY: exact application-backed root run task started"

# THE OVERRIDE IS STAMPED INTO THE VERDICT. D-031: pointing this variable at a string the log always
# contains makes a simulation that never started report PASS, exit 0 -- measured. The override has a
# legitimate use (WPILib does change the banner), so it stays; what it must not do is produce a
# verdict indistinguishable from an honest one.
#
# A verdict written with a non-default pattern now says so, in the JSON and in the summary. That
# closes the ENV-VAR path: an FRC_SIM_READY_PATTERN that differs from the shipped default is
# disclosed, never silent. (Set to the exact default, it changes nothing and is not flagged.)
#
# IT DOES NOT CLOSE THE OTHER PATH. SIM_PATTERN_OVERRIDDEN is computed by comparing the effective
# pattern to SIM_READY_PATTERN_DEFAULT, a constant in THIS SAME FILE. Editing that constant directly
# -- never touching the env var -- moves both sides of the comparison together, so the flag stays
# false: a verdict indistinguishable from an honest one, again. No constant this script could compare
# against would fix that -- any baseline it carries is exactly as editable as the default it would be
# policing. This script cannot verify that SIM_READY_PATTERN matches what WPILib actually prints; it
# can only disclose what pattern was used and how it was sourced. Defect D-051 is recorded in the
# baseline source repository, whose defect register is not installed on a team machine.
SIM_PATTERN_OVERRIDDEN=false
[ "$SIM_READY_PATTERN" = "$SIM_READY_PATTERN_DEFAULT" ] || SIM_PATTERN_OVERRIDDEN=true

# A stop leaves NO verdict for this run. A reader finding nothing is fail-closed; a reader finding
# an earlier run's PASS is the incident (D-052). Every stop path routes through here, including the
# preconditions below — a precondition stop that left a stale PASS on disk was reachable until
# 2026-08-17.
#
# GATE_PASSED_ONCE preserves the ORIGINAL rule unchanged: a stop from before the gate below has
# ever succeeded removes nothing, because removing an unvetted override path is exactly what the
# gate is there to stop, and this flag is the only thing that knows whether that has happened yet
# — verdict_path_ok itself cannot, since it answers "is this path safe right now", not "has this
# script decided to trust it". What changes is what happens once the flag IS set: every removal
# from here on re-runs verdict_path_ok FRESH, rather than trusting the flag as a permanent
# all-clear. A stage can replace the verdict path's immediate parent with a symlink to an outside
# directory holding a file with the verdict file's basename AFTER the gate first passed; trusting
# the flag alone at that point would authorise `rm -f` to follow the symlink and delete the outside
# file. Re-checking here, every time, is what catches that swap — the same way the pre-`mv`
# re-check further down catches it for a run that reaches the write.
GATE_PASSED_ONCE=0
stop_no_verdict() {
  [ "$GATE_PASSED_ONCE" -eq 1 ] && verdict_path_ok && rm -f -- "$VERDICT_PATH" 2>/dev/null
  if [ -e "$VERDICT_PATH" ] || [ -L "$VERDICT_PATH" ]; then
    printf 'STOPPED: %s — and something remains at %s that was not removed (possibly a verdict from an EARLIER run); do not read it as the result of this run\n' "$1" "$VERDICT_PATH" >&2
  else
    printf 'STOPPED: %s%s\n' "$1" "${2:-}" >&2
  fi
  exit 3
}

die() { stop_no_verdict "$1"; }

command -v jq  >/dev/null 2>&1 || die "jq available not met"
command -v git >/dev/null 2>&1 || die "git available not met"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "a git working tree not met"

# --- the verdict-path gate -----------------------------------------------------------------------
# FRC_VERDICT_PATH_OVERRIDE is an environment variable, and this script removes and replaces
# whatever is at VERDICT_PATH. Ungated, that made the tool an arbitrary-file delete/overwrite
# (point it at src/Robot.java) — and an ignored DIRECTORY at the path was worse: `mv` into a
# directory succeeds, so the run printed `verdict: PASS` and `written:` with no verdict file at
# the documented path.
#
# Called fresh every time something is about to act on VERDICT_PATH — here, every stop_no_verdict
# removal once GATE_PASSED_ONCE is set, on_interrupt's removal, and again immediately before the
# final `mv` — never
# memoised as a standalone all-clear, because a symlink swap between two of those calls is exactly
# what re-evaluating is for:
#   - `git check-ignore -q --` must accept the path (`--` keeps an option-shaped path literal).
#     check-ignore answers from git's exclusion rules (not only .gitignore) AND the index: a
#     tracked path is not ignored and is refused, and so is a path outside this repository — so
#     the verdict cannot land on tracked content and cannot appear in the ignore-respecting
#     enumerations that feed tree_hash below.
#   - nothing may sit at the final path except a regular file (an earlier run's verdict);
#   - neither the final path nor its immediate parent may be a symlink. Deeper ancestors are NOT
#     resolved: this checks the path and its parent, nothing above them.
#
# VERDICT_DIR IS DERIVED ONCE, HERE, and every later use reads that one value. The write phase used
# to re-derive it with `dirname "$VERDICT_PATH"` — no `--`, and its exit status discarded. With
# FRC_VERDICT_PATH_OVERRIDE=--version that ran `dirname --version`, which prints dirname's own
# version text and exits 0; the run then created a directory tree named after that text inside the
# student's repository and left this run's temporary verdict inside it, where the NEXT run's
# git-clean stage finds it as an untracked file. Measured 2026-08-21. Deriving once also means the
# directory this gate vets for a symlink is the same one the write phase creates in and moves out
# of, rather than two values that can disagree.
VERDICT_DIR=$(dirname -- "$VERDICT_PATH") || \
  stop_no_verdict "the verdict path's parent directory could not be determined: $VERDICT_PATH"
verdict_path_ok() {
  git check-ignore -q -- "$VERDICT_PATH" 2>/dev/null || return 1
  [ -L "$VERDICT_PATH" ] && return 1
  if [ -e "$VERDICT_PATH" ] && [ ! -f "$VERDICT_PATH" ]; then return 1; fi
  [ -L "$VERDICT_DIR" ] && return 1
  return 0
}
verdict_path_ok || stop_no_verdict "the verdict path is refused: $VERDICT_PATH must be a path git ignores (add it to your ignore rules if it is not), nothing but a regular file may already sit at it, it must not be a symlink, and its parent must not be a symlink"
GATE_PASSED_ONCE=1

[ -x ./gradlew ] || die "a gradle wrapper at ./gradlew not met"

# Integer tests below cannot distinguish a malformed operand from a completed simulation scan. Reject
# an unsupported budget before any stage so a could-not-run scan never becomes a simulation `fail`.
case "$SIM_STARTUP_BUDGET_SECONDS" in
  ''|*[!0-9]*) die "FRC_SIM_STARTUP_BUDGET_SECONDS must be a non-negative whole number supported by this shell" ;;
esac
[ "$SIM_STARTUP_BUDGET_SECONDS" -ge 0 ] 2>/dev/null || \
  die "FRC_SIM_STARTUP_BUDGET_SECONDS must be a non-negative whole number supported by this shell"

# The tool that hashes the Git-derived project identity, resolved BEFORE the stages run: stopping here costs
# nothing, while discovering the gap after the gradle stages costs the whole run. Prefer sha256sum;
# fall back to `shasum -a 256`; with neither resolvable, stop. An unresolved tool must never fall
# through to the hash pipeline, where its absence reads back as an empty tree_hash (D-054). Which
# of the two a platform ships is resolved here at runtime, not assumed at authoring time. The
# withdrawn reader requires sha256sum and carries no shasum fallback; reconcile its resolver before
# reviving it.
HASH_CMD="sha256sum"
if ! command -v sha256sum >/dev/null 2>&1; then
  if command -v shasum >/dev/null 2>&1; then HASH_CMD="shasum -a 256"
  else die "a SHA-256 tool (sha256sum or shasum) available not met"; fi
fi

# --- temporary files and interrupt handling ------------------------------------------------------
# Every temporary this script creates, initialised together so the stop paths and the interrupt
# handler can remove whatever exists at the moment they run. SIM_TASK_CHECK holds the Gradle init
# script that verifies and marks execution of the exact application-backed root `run` task. SIMPID
# holds the simulation's process-group id from launch until teardown has been attempted.
# SIM_LAUNCHING is narrower: true only for the instant between starting that background job and
# SIMPID capturing its pid (see the launch site below) — the one window where the simulation is
# running but SIMPID does not know it.
VERDICT_TMP=""
HASH_LIST_TMP=""
STAGE_LIST_TMP=""
SIMLOG=""
SIM_TASK_CHECK=""
SIMPID=""
SIM_LAUNCHING=0
TREE_ID_RESULT=""

# VERDICT_TMP is created in VERDICT_DIR. Re-check the same gate that admitted that directory
# immediately before removing the temporary: a stage can replace the parent with a symlink after
# the first check, and rm would otherwise follow that parent to a same-named outside file. This
# narrows but cannot close the check/remove race against a process that can mutate the directory
# concurrently; such a process already has this user's filesystem authority. If the check refuses,
# leave the genuine temporary in place rather than remove through a parent that is no longer vetted.
remove_verdict_tmp() {
  [ -n "$VERDICT_TMP" ] || return 0
  verdict_path_ok || return 0
  rm -f -- "$VERDICT_TMP" 2>/dev/null
}

# INT/TERM: kill the simulation group, remove this run's temporaries, remove the verdict at the
# path — so an EARLIER run's PASS cannot be read as this interrupted run's result — then re-raise
# the signal with the default handler restored, so the exit status is the honest signal death.
# This is BEST-EFFORT, not a guarantee: a signal that lands before these lines install the
# handler, a SIGKILL (which no handler can catch), or a removal that fails leaves the filesystem
# as it was — which can mean an earlier run's verdict is still sitting at the path. The handler
# tests for exactly that and warns rather than announcing a cleanup it cannot show. Deliberately
# NOT trapped on EXIT: every normal exit path does its own cleanup, and an EXIT trap would re-run
# removals on states those paths already handled. kill_group is defined further down; that is
# safe, because SIMPID cannot become non-empty before the definition has been read. The verdict
# removal below re-runs verdict_path_ok fresh rather than trusting any earlier check, for the same
# stale-flag reason stop_no_verdict does above — a stage can swap the path's parent for a symlink
# after this script last vetted it.
on_interrupt() {
  trap - INT TERM
  local pid="$SIMPID"
  # SIMPID can still be empty here if the interrupt landed between the simulation's launch and
  # this script's own next statement capturing its pid (see SIM_LAUNCHING above). Bash's job
  # table already knows the job by the moment `&` returns, before this script could reach either
  # that statement or this trap, so fall back to it for exactly that window. SIM_LAUNCHING is
  # cleared right after SIMPID is captured and never set again, so this cannot resurrect a pid the
  # kernel has since recycled after the deliberate clear once the simulation stage is done.
  [ -z "$pid" ] && [ "$SIM_LAUNCHING" -eq 1 ] && pid=$(jobs -p 2>/dev/null | tail -n 1)
  [ -n "$pid" ] && kill_group "$pid"
  remove_verdict_tmp
  [ -n "$HASH_LIST_TMP" ] && rm -f -- "$HASH_LIST_TMP" 2>/dev/null
  [ -n "$STAGE_LIST_TMP" ] && rm -f -- "$STAGE_LIST_TMP" 2>/dev/null
  [ -n "$SIMLOG" ] && rm -f -- "$SIMLOG" 2>/dev/null
  [ -n "$SIM_TASK_CHECK" ] && rm -f -- "$SIM_TASK_CHECK" 2>/dev/null
  verdict_path_ok && rm -f -- "$VERDICT_PATH" 2>/dev/null
  if [ -e "$VERDICT_PATH" ] || [ -L "$VERDICT_PATH" ]; then
    printf 'INTERRUPTED — something remains at %s that was not removed (possibly a verdict from an EARLIER run); do not read it as the result of this run\n' "$VERDICT_PATH" >&2
  else
    printf 'INTERRUPTED — no verdict from this run remains\n' >&2
  fi
  kill -s "$1" $$
}
trap 'on_interrupt INT' INT
trap 'on_interrupt TERM' TERM

# --- stage bookkeeping ---------------------------------------------------------------------------
# Stages that never ran are recorded as `not-run`. They are NEVER recorded as passed: a verdict that
# summarises four passes and one skip as mostly-passed is worse than no verdict, because the team
# stops reading stages.
STAGE_NAMES=(compile test simulate warnings git-clean)
# PARALLEL INDEXED ARRAYS, NOT ASSOCIATIVE ONES — this is a portability fix, not a style choice.
# `declare -A` requires bash >= 4. macOS ships bash 3.2.57 at /bin/bash, this script's shebang is
# `#!/usr/bin/env bash`, and WPILib supports macOS. On 3.2 the declare fails silently (there is no
# `set -e`) and the very next subscript assignment then dies on `set -u` with a bare
# "unbound variable" — a cryptic crash that bypasses this script's own documented STOPPED:
# precondition contract entirely. Reproduced 2026-08-11.
STAGE_RESULT=(); STAGE_DETAIL=()
for i in "${!STAGE_NAMES[@]}"; do STAGE_RESULT[i]="not-run"; STAGE_DETAIL[i]=""; done

# Index of a stage name. Five stages, so a linear scan is the right shape.
stage_idx() {
  local i
  for i in "${!STAGE_NAMES[@]}"; do
    [ "${STAGE_NAMES[i]}" = "$1" ] && { printf '%s' "$i"; return 0; }
  done
  die "internal: unknown stage '$1'"
}

VERDICT="FAIL"
FIRST_FAILURE=""
BUILD_OUT=""   # stages 1-2 output, kept for the warnings stage (D-030)

# What the test stage found in Gradle's JUnit XML. A number means the scan completed, including
# numeric zero; JSON null means no successful count exists because the stage did not run, the test
# task failed, stale evidence could not be removed, or the result files could not be read as the
# Gradle suite shape documented below.
TESTS_EXECUTED=null

# What the simulate stage actually saw, carried to the verdict. Set here, not in the stage: a run
# that stops at stage 1 never reaches the stage, and `set -u` would kill the write instead of
# writing an honest verdict that records nothing was seen.
SIM_READY_LINE_SEEN=""      # the matching line, verbatim, truncated; "" when none was recorded
SIM_WORDS_ONLY_LINES=null   # count when measured; JSON null when no successful count exists

record() { local i; i=$(stage_idx "$1"); STAGE_RESULT[i]=$2; STAGE_DETAIL[i]=${3:-}; }

# Gradle's standard test task writes one JUnit XML file per suite under this path, with that suite
# as the file's root element. Read only the first <testsuite ...> tag in each file: counting later
# tags would count text printed inside CDATA, while a file with no suite tag is unavailable evidence.
# Symlinked result paths are rejected; every XML input must be a readable, non-empty regular file.
# No matching files is a completed count of zero.
#
# The addition is done as decimal strings one digit at a time. awk numbers cannot represent every
# large integer exactly, and silently rounding a count would replace an unknown enumeration with a
# wrong one. The caller separately checks that the result is representable by this shell before it
# uses an integer comparison.
test_xml_count() {
  local f
  local test_files=()
  [ -L build/test-results/test ] && return 2
  if [ -e build/test-results/test ]; then
    [ -d build/test-results/test ] && [ -r build/test-results/test ] || return 2
  fi
  for f in build/test-results/test/*.xml; do
    # With no match, bash 3.2 leaves the literal glob unchanged. Skip only that absent literal;
    # anything that does exist under an XML name must itself (not its target) be a readable,
    # non-empty regular file.
    if [ ! -e "$f" ] && [ ! -L "$f" ]; then continue; fi
    [ ! -L "$f" ] && [ -f "$f" ] && [ -r "$f" ] && [ -s "$f" ] || return 2
    test_files[${#test_files[@]}]=$f
  done
  if [ "${#test_files[@]}" -eq 0 ]; then
    printf '0 0 0\n'
    return 0
  fi

  awk '
    function decimal_add(a, b,    ai, bi, carry, digit, out) {
      ai=length(a); bi=length(b); carry=0; out=""
      while (ai > 0 || bi > 0 || carry > 0) {
        digit=carry
        if (ai > 0) { digit += substr(a, ai, 1); ai-- }
        if (bi > 0) { digit += substr(b, bi, 1); bi-- }
        out=(digit % 10) out
        carry=int(digit / 10)
      }
      sub(/^0+/, "", out)
      return (out == "" ? "0" : out)
    }
    function scan_file(data,    tag, raw) {
      if (match(data, /<testsuite[[:space:]][^>]*>/)) {
        tag=substr(data, RSTART, RLENGTH)
        if (!match(tag, /[[:space:]]tests="[0-9]+"/)) { bad=1; return }
        raw=substr(tag, RSTART, RLENGTH)
        sub(/^[[:space:]]*tests="/, "", raw)
        sub(/"$/, "", raw)
        total=decimal_add(total, raw)
        if (match(tag, /[[:space:]]skipped="[0-9]+"/)) {
          raw=substr(tag, RSTART, RLENGTH)
          sub(/^[[:space:]]*skipped="/, "", raw)
          sub(/"$/, "", raw)
          skipped=decimal_add(skipped, raw)
        }
        if (match(tag, /[[:space:]]failures="[0-9]+"/)) {
          raw=substr(tag, RSTART, RLENGTH)
          sub(/^[[:space:]]*failures="/, "", raw)
          sub(/"$/, "", raw)
          failed=decimal_add(failed, raw)
        }
        if (match(tag, /[[:space:]]errors="[0-9]+"/)) {
          raw=substr(tag, RSTART, RLENGTH)
          sub(/^[[:space:]]*errors="/, "", raw)
          sub(/"$/, "", raw)
          failed=decimal_add(failed, raw)
        }
      } else bad=1
    }
    BEGIN { total="0"; skipped="0"; failed="0" }
    FNR == 1 {
      if (seen_file) scan_file(xml)
      xml=""; seen_file=1
    }
    { xml=xml $0 "\n" }
    END {
      if (seen_file) scan_file(xml)
      if (bad) exit 2
      print total " " skipped " " failed
    }
  ' "${test_files[@]}"
}
simulation_error() {
  record simulate error "$1"
  [ -n "$SIMLOG" ] && rm -f -- "$SIMLOG" 2>/dev/null
  SIMLOG=""
  [ -n "$SIM_TASK_CHECK" ] && rm -f -- "$SIM_TASK_CHECK" 2>/dev/null
  SIM_TASK_CHECK=""
  SIM_WORDS_ONLY_LINES=null
  FIRST_FAILURE=simulate
}

# --- reading the simulation log ------------------------------------------------------------------
# ONE scanner, used by the wait loop and by the recording that follows it, so the loop cannot stop on
# one rule while the verdict records another.
#
# A line IS the framework's startup line when, after a trailing carriage return and any surrounding
# blanks are removed, it is EQUAL to SIM_READY_LINE. The carriage return is removed because a JVM on
# Windows writes CRLF and a whole-line comparison against the raw bytes would then never match; Git
# Bash on Windows is an environment WPILib supports. Removing it is what keeps the rule from being
# platform-dependent -- it is not a loosening of the whole-line comparison.
#
# awk, not grep: index() and == are literal, so a pattern beginning with a dash or holding a regex
# metacharacter is data here and can become neither an option nor a pattern. The strings are passed
# through the ENVIRONMENT rather than -v, because awk processes escape sequences in a -v value and
# FRC_SIM_READY_PATTERN is caller-supplied.
sim_ready_line_hit() {   # $1 = log. Prints the match. Exit 0 found, 1 not found, other could not scan.
  _SIM_LINE="$SIM_READY_LINE" awk '
    { l=$0; sub(/\r$/,"",l); sub(/^[ \t]+/,"",l); sub(/[ \t]+$/,"",l)
      if (l == ENVIRON["_SIM_LINE"]) { print $0; found=1; exit } }
    END { exit (found ? 0 : 1) }
  ' "$1" 2>/dev/null
}
# WHY THIS EXISTS RATHER THAN `tail -5`. The diagnostic for a failed simulation used the last five
# lines of the log. Measured 2026-09-03 on the case that matters most -- a project with no
# `application` plugin -- those five lines are Gradle's generic footer ("Run with --scan...",
# "BUILD FAILED in 3s") and the actual cause, `frc-pre-deploy: required Gradle application plugin is
# absent`, sits above them and never reaches the verdict. The message named THAT it failed and was
# silent on WHY, which is the shape of defect this whole file exists to avoid.
#
# So: prefer this script's own init-script diagnostic, then Gradle's stated cause, then the tail as a
# last resort. Every producer's status is captured; a log that cannot be read says so rather than
# yielding an empty reason that would read as "no reason given".
sim_failure_reason() {
  [ -n "$SIMLOG" ] && [ -r "$SIMLOG" ] || { printf '%s' "the simulation log was not readable, so no reason could be extracted"; return 0; }
  local own own_rc=0 cause cause_rc=0 tail_out tail_rc=0 degraded=""
  own=$(grep -m1 -a 'frc-pre-deploy: ' -- "$SIMLOG") || own_rc=$?
  [ "$own_rc" -le 1 ] || degraded="the own-diagnostic scan could not run (grep exited $own_rc)"
  if [ "$own_rc" -le 1 ] && [ -n "$own" ]; then
    printf '%s' "$(printf '%s' "$own" | tr '\n' ' ')"; return 0
  fi
  cause=$(grep -m1 -a -A1 '^\* What went wrong:' -- "$SIMLOG") || cause_rc=$?
  [ "$cause_rc" -le 1 ] || degraded="${degraded:+$degraded; }the stated-cause scan could not run (grep exited $cause_rc)"
  if [ "$cause_rc" -le 1 ] && [ -n "$cause" ]; then
    printf '%s' "$(printf '%s' "$cause" | tr '\n' ' ')"; return 0
  fi
  tail_out=$(tail -5 -- "$SIMLOG") || tail_rc=$?
  if [ "$tail_rc" -ne 0 ]; then
    printf '%s' "the simulation log could not be read for a reason (tail exited $tail_rc)${degraded:+; $degraded}"; return 0
  fi
  # An EMPTY result is never returned. A readable but empty log -- the producer killed before it
  # wrote anything -- would otherwise end the stage detail at a bare colon, which reads as "no reason
  # given" and is the exact shape this helper exists to remove.
  if [ -z "$tail_out" ]; then
    printf '%s' "the simulation log was empty, so the producer left no reason${degraded:+; $degraded}"; return 0
  fi
  printf '%s' "$(printf '%s' "$tail_out" | tr '\n' ' ')${degraded:+; $degraded}"
}

sim_task_started_hit() { # $1 = log. Exit 0 exact run task started, 1 did not, other could not scan.
  _SIM_TASK_STARTED_LINE="$SIM_TASK_STARTED_LINE" awk '
    { l=$0; sub(/\r$/,"",l); sub(/^[ \t]+/,"",l); sub(/[ \t]+$/,"",l)
      if (l == ENVIRON["_SIM_TASK_STARTED_LINE"]) { found=1; exit } }
    END { exit (found ? 0 : 1) }
  ' "$1" 2>/dev/null
}
sim_words_only_count() { # $1 = log. Prints how many lines carry the words but are NOT that line.
  _SIM_LINE="$SIM_READY_LINE" _SIM_WORDS="$SIM_READY_PATTERN" awk '
    { l=$0; sub(/\r$/,"",l); sub(/^[ \t]+/,"",l); sub(/[ \t]+$/,"",l)
      if (index(l, ENVIRON["_SIM_WORDS"]) > 0 && l != ENVIRON["_SIM_LINE"]) n++ }
    END { print n+0 }
  ' "$1" 2>/dev/null
}
# THE FIRST REJECTED LINE, VERBATIM. A count on its own tells a team that something printed the
# startup words and not what; on the one failure mode that is likely to be innocent -- output the
# whole line requirement did not expect -- the line itself is the whole diagnosis, and a stage that
# says only "1 line(s)" sends them to read a log this script has already deleted.
sim_words_only_first() { # $1 = log. Prints the first such line verbatim, or nothing.
  _SIM_LINE="$SIM_READY_LINE" _SIM_WORDS="$SIM_READY_PATTERN" awk '
    { l=$0; sub(/\r$/,"",l); sub(/^[ \t]+/,"",l); sub(/[ \t]+$/,"",l)
      if (index(l, ENVIRON["_SIM_WORDS"]) > 0 && l != ENVIRON["_SIM_LINE"]) { print $0; exit } }
  ' "$1" 2>/dev/null
}

# KILL THE WHOLE PROCESS GROUP IN ONE SHOT — not a recursive walk of the tree.
#
# The previous implementation snapshotted each level's children with `ps` and killed bottom-up. That
# has a TOCTOU window: a process forked during the ~0.2 s TERM/KILL grace between one level's
# snapshot and its parent's death is never rediscovered, and survives as an orphan once its parent
# goes. Measured 2026-08-11 against a stub that respawns a grandchild: ONE leaked ppid=1 process per
# run, 3 of 3. Gradle under --no-daemon really does fork helper subprocesses on that timescale, so a
# leak per validation run is the realistic outcome, not a contrived one.
#
# `set -m` puts the background job in its OWN process group whose id equals its pid, so a single
# `kill -- -PGID` reaches the processes that are IN that group when the signal is sent, without the
# level-by-level window above.
#
# WHAT IT DOES NOT REACH: a descendant that moved ITSELF out of that group. A process that calls
# setsid(2) or setpgid(2) — which a daemonising helper does deliberately — is in a different group,
# and no signal addressed to this one can find it. Measured 2026-08-21 with a stub whose simulation
# forked a `setsid` child: the child was still running after this function returned. Nothing this
# function can do would change that, so the simulation stage below reports a group-directed signal
# only when one succeeded and does not assert that everything the simulation started is gone.
#
# Deliberately NOT `setsid`: it is util-linux and absent on macOS, which WPILib supports. Job control
# is in bash itself, including bash 3.2.
KILL_GROUP_DETAIL=""
kill_group() {
  local pid=$1 group_term_rc group_kill_rc leader_term_rc=not-run leader_kill_rc=not-run
  local grace_rc members="" ps_rc=0 member_rc
  kill -TERM -- -"$pid" 2>/dev/null
  group_term_rc=$?
  if [ "$group_term_rc" -ne 0 ]; then
    kill -TERM "$pid" 2>/dev/null
    leader_term_rc=$?
  fi
  sleep 0.2
  grace_rc=$?
  kill -KILL -- -"$pid" 2>/dev/null
  group_kill_rc=$?
  if [ "$group_kill_rc" -ne 0 ]; then
    kill -KILL "$pid" 2>/dev/null
    leader_kill_rc=$?
  fi

  if [ "$grace_rc" -ne 0 ]; then
    KILL_GROUP_DETAIL="the simulation teardown grace wait could not run (sleep exited $grace_rc)"
    return 1
  fi
  if [ "$group_term_rc" -eq 0 ] || [ "$group_kill_rc" -eq 0 ]; then
    KILL_GROUP_DETAIL="The simulation's process group was then signalled. A descendant that moved itself out of that group is not reached by that signal"
    return 0
  fi

  # A simulation may print the line and exit before teardown. Do not reject that valid result merely
  # because there was no group left to signal. Conversely, a failed signal must not be accepted as
  # proof that the group is gone. Inspect group membership with a separate producer; failure to run
  # that inspection is stage `error`, not an invented content failure or a silent PASS.
  members=$(ps -axo pgid= 2>/dev/null) || ps_rc=$?
  if [ "$ps_rc" -ne 0 ]; then
    KILL_GROUP_DETAIL="no group-directed teardown signal was accepted, and process-group membership could not be checked (ps exited $ps_rc)"
    return 1
  fi
  awk -v target="$pid" '$1 == target { found=1 } END { exit(found ? 0 : 1) }' <<< "$members"
  member_rc=$?
  if [ "$member_rc" -eq 0 ]; then
    KILL_GROUP_DETAIL="no group-directed teardown signal was accepted while a process-group member remained (group TERM/KILL exited $group_term_rc/$group_kill_rc; leader TERM/KILL exited $leader_term_rc/$leader_kill_rc)"
    return 1
  elif [ "$member_rc" -eq 1 ]; then
    KILL_GROUP_DETAIL="No group-directed teardown signal was accepted; a subsequent process-group membership check found no remaining member. A descendant that had moved itself out of that group is not covered by that check"
    return 0
  fi
  KILL_GROUP_DETAIL="no group-directed teardown signal was accepted, and the process-group membership scan could not run (awk exited $member_rc)"
  return 1
}

# --- the five stages, in order -------------------------------------------------------------------
# Order matters: a compile failure makes the later stages meaningless and their output noise. The
# FIRST failing stage stops the pipeline.
run_stages() {
  local out

  # 1. compile
  #
  # BUILD_OUT IS KEPT. D-030: `out` was reassigned to the simulation log before the warnings stage
  # ran, so stage 4 scanned sim output and never saw a compiler warning at all -- and on a real
  # project `simulateJava`'s compileJava is up to date and re-emits nothing, so the stage passed
  # unconditionally. Measured fail-open.
  #
  # --rerun-tasks is deliberately NOT used. Forcing a full recompile on every pre-deploy would cost a
  # student minutes on a laptop, and the warning count is information, not a gate (see stage 4). An
  # up-to-date build legitimately emits nothing, and stage 4 says so rather than implying zero.
  if out=$(./gradlew compileJava 2>&1); then record compile pass
  else record compile fail "$(printf '%s' "$out" | tail -5)"; FIRST_FAILURE=compile; return; fi
  BUILD_OUT=$out

  # 2. unit tests
  #
  # Delete this project's ordinary default-result XML immediately before invoking the task. Thus,
  # any accepted files counted afterwards were written by this invocation; SKIPPED, NO-SOURCE and
  # UP-TO-DATE outcomes that write nothing cannot pass on stale evidence. Symlinked paths are rejected
  # rather than followed or removed. A positive count establishes that this invocation's default
  # JUnit XML reports at least one non-skipped test and no failures/errors. It does not establish that
  # every project test is represented or that its assertions are useful.
  local stale cleanup_rc=0
  if [ -L build/test-results/test ]; then
    record test error "Gradle test was not run because build/test-results/test is a symlink"
    FIRST_FAILURE="test"
    return
  fi
  if [ -d build/test-results/test ] && ! [ -r build/test-results/test ]; then
    record test error "Gradle test was not run because build/test-results/test is not readable"
    FIRST_FAILURE="test"
    return
  fi
  for stale in build/test-results/test/*.xml; do
    if [ ! -e "$stale" ] && [ ! -L "$stale" ]; then continue; fi
    if [ -L "$stale" ]; then
      record test error "Gradle test was not run because $stale is a symlink"
      FIRST_FAILURE="test"
      return
    fi
    if [ -f "$stale" ]; then
      rm -f -- "$stale" || cleanup_rc=$?
      if [ "$cleanup_rc" -ne 0 ]; then
        record test error "Gradle test was not run because stale JUnit XML could not be removed ($stale; rm exited $cleanup_rc)"
        FIRST_FAILURE="test"
        return
      fi
    fi
  done
  if out=$(./gradlew test 2>&1); then :
  else record test fail "$(printf '%s' "$out" | tail -5)"; FIRST_FAILURE="test"; return; fi
  BUILD_OUT="$BUILD_OUT
$out"
  local test_count_rc=0 counts counts_rest tests_reported tests_skipped tests_failed
  counts=$(test_xml_count 2>/dev/null) || test_count_rc=$?
  if [ "$test_count_rc" -ne 0 ]; then
    TESTS_EXECUTED=null
    record test error "Gradle test exited 0, but its JUnit XML count could not be established (scan exited $test_count_rc)"
    FIRST_FAILURE="test"
    return
  fi
  tests_reported=${counts%% *}
  counts_rest=${counts#* }
  tests_skipped=${counts_rest%% *}
  tests_failed=${counts_rest#* }
  case "$tests_reported$tests_skipped$tests_failed" in
    ''|*[!0-9]*)
      TESTS_EXECUTED=null
      record test error "Gradle test exited 0, but its JUnit XML scan returned no usable counts"
      FIRST_FAILURE="test"
      return
      ;;
  esac
  if ! [ "$tests_reported" -ge 0 ] 2>/dev/null \
     || ! [ "$tests_skipped" -ge 0 ] 2>/dev/null \
     || ! [ "$tests_failed" -ge 0 ] 2>/dev/null; then
    TESTS_EXECUTED=null
    record test error "Gradle test exited 0, but its JUnit XML count is not supported by this shell"
    FIRST_FAILURE="test"
    return
  fi
  if [ "$tests_skipped" -gt "$tests_reported" ]; then
    TESTS_EXECUTED=null
    record test error "Gradle test exited 0, but its JUnit XML reports more skipped tests than tests"
    FIRST_FAILURE="test"
    return
  fi
  TESTS_EXECUTED=$((tests_reported - tests_skipped))
  if [ "$tests_failed" -gt 0 ]; then
    record test fail "$tests_failed failure(s) or error(s) reported in Gradle JUnit XML although the task exited 0"
    FIRST_FAILURE="test"
    return
  fi
  if [ "$TESTS_EXECUTED" -eq 0 ]; then
    record test unconfirmed "Gradle test exited 0, but no JUnit XML suite under build/test-results/test reported a test (sum 0); no test execution was established"
    FIRST_FAILURE="test"
    return
  fi
  record test pass "$TESTS_EXECUTED executed test(s) reported in Gradle JUnit XML ($tests_reported tests minus $tests_skipped skipped); the counted files were written by this invocation's test task"

  # 3. THE SIMULATION STARTUP LINE.
  #
  # Measured 2026-08-09 on WPILib 2026: `./gradlew simulateJava` does NOT exit -- still running at
  # 180.64s. An earlier revision waited for it to exit and mapped the inevitable timeout to TIMEOUT,
  # so every healthy project reported TIMEOUT and the verdict could never be PASS (D-025).
  #
  # Measured 2026-09-03 on WPILib 2027: `simulateJava` no longer exists, but Gradle abbreviates that
  # name to `simulateExternalJava`, which exits in about a second after launching no robot program.
  # The 2027 launch task is `run`, supplied by Gradle's `application` plugin. That is a dependency,
  # not a claim that every project has `run`: the generated init script checks both the plugin and
  # the exact root task name in the SAME Gradle invocation, before task selection can silently
  # substitute an abbreviation, and marks when that exact task actually begins executing.
  #
  # So: launch, wait for SIM_READY_LINE to APPEAR in the log, then attempt teardown of the launched
  # process group. A `pass` here says that line appeared and nothing more -- not that the robot program
  # started, and not that everything the simulation started is gone (see kill_group above).
  # TIMEOUT means the line did not appear within the budget, which is a real distinct outcome
  # rather than "a simulation behaved normally"; `unconfirmed` separates the case where the WORDS
  # appeared on some line while that line never did.
  local waited=0 confirmed=0 scan_rc=0 scan_error=""
  SIM_TASK_CHECK=$(mktemp)
  scan_rc=$?
  if [ "$scan_rc" -ne 0 ]; then
    SIM_TASK_CHECK=""
    simulation_error "the exact simulation-task check could not be created (mktemp exited $scan_rc); the run task was not launched"
    return
  fi
  printf '%s\n' \
    'gradle.projectsEvaluated {' \
    '  def root = gradle.rootProject' \
    '  if (!root.pluginManager.hasPlugin("application")) {' \
    '    throw new GradleException("frc-pre-deploy: required Gradle application plugin is absent")' \
    '  }' \
    '  if (!root.tasks.names.contains("run")) {' \
    '    throw new GradleException("frc-pre-deploy: required exact root task run is absent")' \
    '  }' \
    '  root.tasks.getByName("run").doFirst {' \
    "    println('$SIM_TASK_STARTED_LINE')" \
    '  }' \
    '}' > "$SIM_TASK_CHECK"
  scan_rc=$?
  if [ "$scan_rc" -ne 0 ]; then
    simulation_error "the exact simulation-task check could not be written (printf exited $scan_rc); the run task was not launched"
    return
  fi
  SIMLOG=$(mktemp)
  scan_rc=$?
  if [ "$scan_rc" -ne 0 ]; then
    SIMLOG=""
    simulation_error "the simulation log could not be created (mktemp exited $scan_rc); the run task was not launched"
    return
  fi
  # `set -m` for this launch only: it makes the background job a process-group leader so the whole
  # tree can be signalled at once. Restored immediately — leaving job control on changes how later
  # background commands behave. SIM_LAUNCHING brackets the launch itself so on_interrupt has
  # something to fall back to if a signal lands before SIMPID=$! below has run — see its comment.
  set -m
  SIM_LAUNCHING=1
  ./gradlew --no-daemon --console=plain -I "$SIM_TASK_CHECK" run > "$SIMLOG" 2>&1 &
  SIMPID=$!
  SIM_LAUNCHING=0
  set +m

  while [ "$waited" -le "$SIM_STARTUP_BUDGET_SECONDS" ]; do
    if [ "$SIM_PATTERN_OVERRIDDEN" = true ]; then
      # The caller has asserted the banner is no longer the shipped one, so the whole-line
      # requirement does not apply to this run -- there is nothing left to compare the decoration
      # against. The run is stamped sim_ready_pattern_overridden: true either way.
      # -e binds the pattern as a PATTERN even when it starts with a dash. Without it,
      # FRC_SIM_READY_PATTERN=--help became a grep OPTION: grep exited 0 without reading the log,
      # and a simulation that never started recorded pass.
      grep -qF -e "$SIM_READY_PATTERN" "$SIMLOG" 2>/dev/null
      scan_rc=$?
      if [ "$scan_rc" -eq 0 ]; then confirmed=1; break
      elif [ "$scan_rc" -ne 1 ]; then
        scan_error="the caller-supplied startup-pattern scan could not run (grep exited $scan_rc)"
        break
      fi
    else
      sim_ready_line_hit "$SIMLOG" >/dev/null 2>&1
      scan_rc=$?
      if [ "$scan_rc" -eq 0 ]; then confirmed=1; break
      elif [ "$scan_rc" -ne 1 ]; then
        scan_error="the documented startup-line scan could not run (awk exited $scan_rc)"
        break
      fi
    fi
    # The scan at the configured boundary is part of the budget; do not begin another wait after it.
    [ "$waited" -ge "$SIM_STARTUP_BUDGET_SECONDS" ] && break
    # An exit before the signal is abnormal for a simulation: report it as a failure, with output.
    kill -0 "$SIMPID" 2>/dev/null || break
    sleep 1
    scan_rc=$?
    if [ "$scan_rc" -ne 0 ]; then
      scan_error="the simulation startup wait could not run (sleep exited $scan_rc)"
      break
    fi
    waited=$((waited+1))
  done

  # Capture liveness before teardown changes it. In particular, a process already dead when a
  # zero-second boundary scan finishes is a crash, while a process observed alive at that boundary
  # exhausted its startup budget even though the teardown below will normally make it dead.
  local sim_alive_before_teardown=0 sim_producer_rc=not-applicable
  kill -0 "$SIMPID" 2>/dev/null && sim_alive_before_teardown=1

  local teardown_error="" teardown_detail=""
  if kill_group "$SIMPID"; then teardown_detail=$KILL_GROUP_DETAIL
  else teardown_error=$KILL_GROUP_DETAIL
  fi
  # A producer that exited before teardown can be waited for without blocking. Capture its status
  # before clearing SIMPID; an intentionally torn-down long-running producer has no useful natural
  # exit status, and kill_group already captures each teardown producer's status.
  if [ "$sim_alive_before_teardown" -eq 0 ]; then
    wait "$SIMPID" 2>/dev/null
    sim_producer_rc=$?
  fi
  # Teardown has been attempted; a later interrupt must not signal a process-group id the kernel
  # may have recycled.
  SIMPID=""

  local task_started_error=""
  sim_task_started_hit "$SIMLOG" >/dev/null 2>&1
  scan_rc=$?
  if [ "$scan_rc" -eq 1 ]; then
    if [ "$sim_alive_before_teardown" -eq 1 ]; then
      task_started_error="the application-backed exact root run task did not report that it started before the startup budget expired; the Gradle producer remained alive until teardown, so the simulation could not be treated as having run"
    else
      task_started_error="the application-backed exact root run task did not report that it started (Gradle exited $sim_producer_rc); the simulation could not be run: $(sim_failure_reason)"
    fi
  elif [ "$scan_rc" -ne 0 ]; then
    task_started_error="the exact run-task start check could not be read (awk exited $scan_rc); the simulation could not be treated as having run"
  fi
  [ -n "$SIM_TASK_CHECK" ] && rm -f -- "$SIM_TASK_CHECK" 2>/dev/null
  SIM_TASK_CHECK=""

  if [ -n "$task_started_error" ]; then
    [ -n "$scan_error" ] && task_started_error="${task_started_error}; ${scan_error}"
    [ -n "$teardown_error" ] && task_started_error="${task_started_error}; ${teardown_error}"
    simulation_error "$task_started_error"
    return
  fi
  if [ -n "$scan_error" ]; then
    [ -n "$teardown_error" ] && scan_error="${scan_error}; ${teardown_error}"
    simulation_error "$scan_error"
    return
  fi
  if [ -n "$teardown_error" ]; then
    simulation_error "$teardown_error"
    return
  fi

  # WHAT THE SCAN SAW GOES INTO THE VERDICT, matched or not, so a reader is not left to infer it
  # from a stage word. The matched line is bytes out of a log this script does not control, so it is
  # bounded before it is carried anywhere.
  SIM_READY_LINE_SEEN=$(sim_ready_line_hit "$SIMLOG" 2>/dev/null)
  scan_rc=$?
  if [ "$scan_rc" -eq 1 ]; then SIM_READY_LINE_SEEN=""
  elif [ "$scan_rc" -ne 0 ]; then
    SIM_READY_LINE_SEEN=""
    simulation_error "the recorded startup-line scan could not run (awk exited $scan_rc)"
    return
  fi
  SIM_READY_LINE_SEEN=$(cut -c1-200 <<< "$SIM_READY_LINE_SEEN")
  scan_rc=$?
  if [ "$scan_rc" -ne 0 ]; then
    SIM_READY_LINE_SEEN=""
    simulation_error "the recorded startup-line bounding command exited $scan_rc"
    return
  fi
  SIM_WORDS_ONLY_LINES=$(sim_words_only_count "$SIMLOG" 2>/dev/null)
  scan_rc=$?
  if [ "$scan_rc" -ne 0 ]; then
    simulation_error "the words-only startup-line count could not run (awk exited $scan_rc)"
    return
  fi
  case "$SIM_WORDS_ONLY_LINES" in
    ''|*[!0-9]*)
      simulation_error "the words-only startup-line count returned a non-numeric result"
      return
      ;;
  esac
  local first_rejected=""
  if [ "$SIM_WORDS_ONLY_LINES" -gt 0 ]; then
    first_rejected=$(sim_words_only_first "$SIMLOG" 2>/dev/null)
    scan_rc=$?
    if [ "$scan_rc" -ne 0 ]; then
      simulation_error "the first words-only startup line could not be read (awk exited $scan_rc)"
      return
    fi
    first_rejected=$(printf '%s' "$first_rejected" | cut -c1-200)
    scan_rc=$?
    if [ "$scan_rc" -ne 0 ]; then
      simulation_error "the first words-only startup line could not be bounded (cut exited $scan_rc)"
      return
    fi
  fi

  if [ "$confirmed" -eq 1 ]; then
    # NOT "startup confirmed". What happened is that a line matching the framework's startup line
    # appeared in the output of a task this project's build files control. Which program printed it
    # is not established by anything this script can do -- see sim_startup_provenance. The
    # process-group limit is kept here unchanged: neither a group-directed signal nor a membership
    # check reaches a descendant that moved itself out of the group.
    local pass_detail
    if [ "$SIM_PATTERN_OVERRIDDEN" = true ]; then
      # This run did not require the documented whole line: the caller replaced the pattern and the
      # match was a substring test for whatever they supplied. Say THAT. Describing a comparison
      # this run never made would be a false detail on the one path that most needs an honest one.
      pass_detail="a line containing the caller-supplied startup pattern appeared after ~${waited}s; the documented framework startup line was NOT required on this run, and which program printed the matched line is not established"
    else
      pass_detail="a line matching the documented framework startup line appeared after ~${waited}s; which program printed it is not established"
    fi
    pass_detail="${pass_detail}. ${teardown_detail}"
    # The words-only count is reported HERE too, not only on the unconfirmed path below: otherwise a
    # reader of a PASS has a count in the verdict, no way to see what was counted, and a log this
    # script has already deleted. Worded as the count is DEFINED so it stays true on both paths.
    if [ "$SIM_WORDS_ONLY_LINES" -gt 0 ]; then
      pass_detail="${pass_detail}. ${SIM_WORDS_ONLY_LINES} line(s) in that output carried the pattern this run searched for without being the documented framework line; the first was: ${first_rejected}"
    fi
    record simulate pass "$pass_detail"
  elif [ "$sim_alive_before_teardown" -eq 1 ]; then
    if [ "$SIM_WORDS_ONLY_LINES" -gt 0 ]; then
      # Distinct from `timeout` on purpose: something printed the startup WORDS and the framework's
      # line never appeared. That is the counterfeit shape, and a reader who cannot tell it from a
      # silent simulation cannot act on it.
      record simulate unconfirmed "${SIM_WORDS_ONLY_LINES} line(s) carried the startup words but the documented framework startup line never appeared within ${SIM_STARTUP_BUDGET_SECONDS}s; the first of them was: ${first_rejected}"
    else
      record simulate timeout "the documented framework startup line did not appear within ${SIM_STARTUP_BUDGET_SECONDS}s"
    fi
    out=$(tail -20 "$SIMLOG"); rm -f "$SIMLOG"; SIMLOG=""
    FIRST_FAILURE=simulate; VERDICT=TIMEOUT; return
  else
    record simulate fail "the run task REPORTED that it started, but the simulation producer exited $sim_producer_rc before announcing startup: $(sim_failure_reason)"
    out=$(tail -20 "$SIMLOG"); rm -f "$SIMLOG"; SIMLOG=""
    FIRST_FAILURE=simulate; return
  fi
  rm -f "$SIMLOG"; SIMLOG=""
                    # $out is deliberately NOT reloaded here: the old stage 4 consumed it, and
                    # reassigning it was the D-030 defect. Nothing reads it after this point.

  # 4. COMPILER WARNINGS — COUNTED, NOT GATED. Scans the BUILD output (stages 1-2), not the sim log.
  #
  # Two defects fixed here, both D-030:
  #   (a) it scanned the wrong input entirely (see stage 1);
  #   (b) the pattern was line-anchored `^\s*(warning|note):`, which cannot match javac's dominant
  #       shape `File.java:12: warning: ...` -- so even against the right input it would have missed
  #       almost everything.
  #
  # IT REPORTS A COUNT AND DOES NOT FAIL THE VERDICT, and that is a deliberate product decision, not
  # timidity. FRC vendor libraries emit deprecation warnings constantly; a stage that failed on them
  # would make the verdict red for most teams on day one, and D-013 already established what happens
  # to a check that is red for everyone — it gets deleted, and the team loses the stages that matter.
  # A count is actionable. A permanent red is noise.
  # Case-INSENSITIVE, deliberately: javac writes `warning:` lower-case on a diagnostic line but
  # `Note:` capitalised at the start of its summary lines. Dropping the `-i` silently halves the
  # count. A contract fixture retained only in the baseline source repository asserts an exact
  # count of 3 rather than merely "non-zero" — a case-sensitive implementation counts 2 and fails.
  #
  # (This comment previously said the halving was "caught because the fixture emitted two lines and
  # the stage reported one". It was caught by an ad-hoc check in a scratch directory, and no such
  # fixture was in the tree; an independent audit flagged the wording as narrating coverage that did
  # not exist. The fixture named above now exists and was mutation-verified.)
  # grep's exit statuses are three-valued and the difference is load-bearing: 0 matched, 1 matched
  # nothing, >1 the scan itself failed. `|| true` collapsed all three, so a scan that could not run
  # recorded `pass` for a count that was never measured. An operational failure now records the
  # existing `error` state: disclosed in the stage table, and non-gating for the same D-013 reason
  # the count is non-gating.
  local warn_n grep_rc=0
  warn_n=$(grep -ciE '(^|[[:space:]])(warning|note):|:[0-9]+:[[:space:]]*(warning|note):' <<< "$BUILD_OUT") || grep_rc=$?
  # The count is validated BEFORE its value is trusted, and the order matters. A here-string bash
  # cannot materialise — the temp file backing the here-document is unwritable — returns status 1
  # with EMPTY output. Status 1 is also grep's "no match", so status alone cannot separate them, and
  # an unvalidated empty value reaches the numeric test below, fails it noisily on stderr, and falls
  # through to a recorded zero that was never measured. On bash 3.2, the floor this project builds
  # against, EVERY here-string uses a temp file, so the trigger is any input size.
  # ORDER MATTERS. A grep that genuinely errored (status >= 2) ALSO leaves the count empty, so the
  # established cause must be reported first; only when grep's own status does not explain the
  # emptiness does the here-string case apply.
  if [ "$grep_rc" -gt 1 ]; then
    record warnings error "the warning scan could not run (scan command exited $grep_rc; this is grep's status when grep ran) — the warning count for this build is unknown; reported, not gated"
  else
    case "$warn_n" in
      ''|*[!0-9]*)
        record warnings error "the warning scan produced no usable count (scan status $grep_rc, output '$warn_n'); a here-string that could not be materialised also returns status 1 with empty output, so the count is not established"
        ;;
      *)
        if [ "$warn_n" -gt 0 ]; then
          record warnings pass "$warn_n compiler warning/note line(s) in the build output — reported, not gated"
        else
          record warnings pass "no compiler warning/note lines in this build's output (an up-to-date build emits none)"
        fi
        ;;
    esac
  fi

  # 5. git cleanliness. Force submodule reporting on: otherwise diff.ignoreSubmodules=all can make
  #    a dirty submodule look clean. On a project with no submodules this option does not change the
  #    porcelain output; on a project with a dirty submodule, failing is the intended new behaviour.
  #
  # Read the exit status BEFORE the output. A `git status` that fails with nothing on stdout is
  # byte-identical, on stdout, to a clean tree — an output-only test records `pass` for a check
  # that never ran (D-053). Stage result `error` is distinct from `fail` on purpose: `fail` means
  # the tree IS dirty; `error` means cleanliness could not be determined. Neither is a pass, and
  # both fail the verdict.
  local dirty rc=0
  dirty=$(git status --porcelain --untracked-files=all --ignore-submodules=none 2>/dev/null) || rc=$?
  if [ "$rc" -ne 0 ]; then
    record git-clean error "git status exited $rc — cleanliness could not be determined"
    FIRST_FAILURE=git-clean; return
  fi
  if [ -n "$dirty" ]; then
    record git-clean fail "$(printf '%s' "$dirty" | head -5)"; FIRST_FAILURE=git-clean; return
  fi
  record git-clean pass

  VERDICT=PASS
}

# --- late stop: this run cannot produce a verdict ------------------------------------------------
# From here on, a failure means THIS run has no honest verdict to write. Exit 3, the same code as
# a precondition stop — in both cases there is no verdict to read. Do not route these through a
# FAIL verdict: FAIL is a computed result, and a run that stopped here did not compute one.
write_stop() {
  remove_verdict_tmp
  [ -n "$HASH_LIST_TMP" ] && rm -f -- "$HASH_LIST_TMP" 2>/dev/null
  [ -n "$STAGE_LIST_TMP" ] && rm -f -- "$STAGE_LIST_TMP" 2>/dev/null
  [ -n "$SIMLOG" ] && rm -f -- "$SIMLOG" 2>/dev/null
  [ -n "$SIM_TASK_CHECK" ] && rm -f -- "$SIM_TASK_CHECK" 2>/dev/null
  stop_no_verdict "$1" " — no verdict was written"
}

GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || \
  write_stop "the git metadata directory could not be located"

# The Git-derived identity recorded in the verdict, into TREE_ID_RESULT. It is not an identity of
# the whole filesystem tree: paths Git ignores are outside it. That keeps ordinary ignored build
# outputs from changing the identity, but it also means PASS cannot establish that an ignored build
# input stayed unchanged. The withdrawn reader uses different pathname handling; the source-only
# contract fixture covers its fixture, not every valid repository.
#
# Count the paths listed against the lines the hasher returns, and stop on any shortfall. Preserve
# the withdrawn reader contract that every listed path must hash. Without the count, an
# unreadable path or a failing hash tool leaves $CONTENT short or empty while the final pipeline
# still emits 64 well-formed hex characters: a hash over nothing, indistinguishable from a hash
# over everything (D-054). ONE list, written once and then both counted and hashed, because
# counting a DIFFERENT invocation than the one that is hashed defeats the invariant: force both to
# fail empty and 0 == 0 passes the check. $HASH_CMD is expanded UNQUOTED on purpose — it can be a
# command plus flags (`shasum -a 256`); do not quote it.
tree_identity() {
  local rec tab hash_line
  tab=$'\t'
  TREE_ID_RESULT=""
  STAGE_LIST_TMP=$(mktemp "$GIT_DIR/.pre-deploy-index.XXXXXX") || \
    { STAGE_LIST_TMP=""; write_stop "a temporary index list could not be created in $GIT_DIR"; }
  HASH_LIST_TMP=$(mktemp "$GIT_DIR/.pre-deploy-files.XXXXXX") || \
    { HASH_LIST_TMP=""; write_stop "a temporary file list could not be created in $GIT_DIR"; }
  # Tracked entries WITH their index modes. A gitlink (mode 160000, a submodule) is excluded here,
  # BY ITS INDEX MODE: it is a directory operand the hash tools refuse (sha256sum: "Is a
  # directory"), so leaving it in stopped every run on a repository with an initialized submodule.
  # The submodule's recorded commit still reaches the hash through the `git submodule status
  # --recursive` section below, and submodule
  # modifications through the `--ignore-submodules=none` status section — the gitlink is excluded
  # from the file hashing, not from the identity. The filter keys on the index mode and never on
  # the filesystem: a worktree test like `[ -d ]` follows symlinks, so it would silently drop a
  # tracked symlink-to-directory — or a tracked file replaced by a directory — from the identity.
  # Those stay listed, and when the hash tool cannot read one, the count invariant stops the run.
  git ls-files -z --cached --stage > "$STAGE_LIST_TMP" 2>/dev/null || \
    write_stop "git ls-files failed — Git-visible project files cannot be enumerated"
  while IFS= read -r -d '' rec; do
    case "$rec" in "160000 "*) continue ;; esac
    printf '%s\0' "${rec#*"$tab"}" || \
      write_stop "a tracked pathname could not be written to the working-tree file list"
  done < "$STAGE_LIST_TMP" > "$HASH_LIST_TMP" || \
    write_stop "the working-tree file list could not be filtered"
  # Untracked-but-not-ignored files, appended: they are not index entries, so none is a gitlink.
  git ls-files -z --others --exclude-standard >> "$HASH_LIST_TMP" 2>/dev/null || \
    write_stop "git ls-files failed — Git-visible project files cannot be enumerated"
  EXPECTED_N=0
  while IFS= read -r -d '' rec; do
    EXPECTED_N=$((EXPECTED_N + 1))
  done < "$HASH_LIST_TMP"
  # A tracked pathname can be exactly "-"; sha256sum/shasum special-case a bare "-" as STDIN
  # rather than a filename — confirmed: they do so even placed after "--", so "--" does not
  # disambiguate it here. Hashing "-" this way still exits 0, so the two-snapshot identity below
  # cannot catch it: the file can change between snapshots and both compute the SHA-256 of empty
  # input regardless. A pathname merely STARTING with "-" (e.g. one named "-c") is instead parsed
  # as an OPTION by the same tools; confirmed for "-c"/"--check" specifically, that flips the
  # invocation into checksum-VERIFICATION mode, which in the ordinary case fails LOUDLY (a nonzero
  # exit this script already stops on) rather than silently — but no dash-led pathname belongs in
  # front of a hash tool's argument parser regardless of which way a given one happens to fail.
  # Prefixing ONLY a dash-led entry with "./" removes the ambiguity for every option parser while
  # leaving every other path's hashed bytes untouched, so tree_hash stays identical to before on
  # the trees the contract test and the quarantined reader assume (neither ships this filter — see
  # the porting note above). NUL-delimited, one record at a time, the same read idiom already used
  # for the gitlink filter above: an embedded space or newline in a pathname is not split.
  : > "$STAGE_LIST_TMP" || \
    write_stop "the temporary normalized-path list could not be reset"
  while IFS= read -r -d '' rec; do
    # Keep the patterns parenthesised for Bash 3.2 compatibility if this loop later returns to a
    # command substitution; the spelling selects identically on supported Bash versions.
    case "$rec" in
      (-*) printf './%s\0' "$rec" >> "$STAGE_LIST_TMP" || \
        write_stop "a dash-led pathname could not be written for hashing" ;;
      (*)  printf '%s\0' "$rec" >> "$STAGE_LIST_TMP" || \
        write_stop "a pathname could not be written for hashing" ;;
    esac
  done < "$HASH_LIST_TMP"
  UNSORTED_CONTENT=$(xargs -0 -r $HASH_CMD < "$STAGE_LIST_TMP" 2>/dev/null) || \
    write_stop "the Git-visible project files could not be fully hashed"
  CONTENT=$(LC_ALL=C sort <<< "$UNSORTED_CONTENT") || \
    write_stop "the working-tree hashes could not be sorted"
  local count_rc=0
  ACTUAL_N=$(grep -c . <<< "$CONTENT") || count_rc=$?
  [ "$count_rc" -le 1 ] || \
    write_stop "the working-tree hash count could not be checked (grep exited $count_rc)"
  case "$ACTUAL_N" in
    ''|*[!0-9]*) write_stop "the working-tree hash count returned a non-numeric result" ;;
  esac
  if { [ "$count_rc" -eq 0 ] && [ "$ACTUAL_N" -eq 0 ]; } || \
     { [ "$count_rc" -eq 1 ] && [ "$ACTUAL_N" -ne 0 ]; }; then
    write_stop "the working-tree hash count returned inconsistent output and status"
  fi
  [ "$EXPECTED_N" = "$ACTUAL_N" ] || \
    write_stop "the Git-visible project files could not be fully hashed ($ACTUAL_N of $EXPECTED_N paths)"
  rm -f -- "$STAGE_LIST_TMP" "$HASH_LIST_TMP" 2>/dev/null || \
    write_stop "the temporary working-tree file lists could not be removed"
  STAGE_LIST_TMP=""
  HASH_LIST_TMP=""
  STATUS_STATE=$(git status --porcelain --untracked-files=all --ignore-submodules=none 2>/dev/null) || \
    write_stop "git status failed while recording the tree state for tree_hash"
  SUBMODULE_STATE=$(git submodule status --recursive 2>/dev/null) || \
    write_stop "git submodule status failed while recording the tree state for tree_hash"
  # The here-string supplies the final newline after the two explicit separators, so the hasher
  # receives the same three newline-terminated sections without a pipeline producer whose failure
  # could be hidden by the hasher's status. $HASH_CMD remains unquoted for the documented fallback.
  hash_line=$($HASH_CMD <<< "$CONTENT"$'\n'"$STATUS_STATE"$'\n'"$SUBMODULE_STATE") || \
    write_stop "the tree hash could not be computed"
  TREE_ID_RESULT=${hash_line%% *}
  case "$TREE_ID_RESULT" in
    ''|*[!0-9a-f]*) write_stop "the tree hash could not be computed" ;;
  esac
  [ "${#TREE_ID_RESULT}" -eq 64 ] || \
    write_stop "the tree hash is malformed (${#TREE_ID_RESULT} of 64 characters)"
}

# The identity is taken ONCE BEFORE the stages and ONCE AFTER, and the two must agree. With only a
# post-run snapshot, the stages could validate tree A while a checkout landed clean tree B before
# the snapshot: every recorded stage pass, every identity field describing B — a current, clean
# verdict for code that was never validated. Divergence is a STOP, not a FAIL: FAIL asserts "this
# tree failed validation", and neither tree was both validated and hashed.
tree_identity
TREE_HASH_BEFORE=$TREE_ID_RESULT

run_stages
[ -n "$FIRST_FAILURE" ] && [ "$VERDICT" != TIMEOUT ] && VERDICT=FAIL

# --- identity of the code that was validated -----------------------------------------------------
# A commit that cannot be established is unavailable verdict metadata, not evidence that any of the
# five stages failed. Route it through the existing late STOPPED path without rewriting a stage.
# THE PRODUCER'S EXIT STATUS DECIDES, not the shape of what it printed. A git that prints a
# real-looking hash and then exits non-zero has not established the hash, and a successful producer
# that prints nothing or a malformed object ID has not established one either. Current Git object
# formats produce 40 lowercase hex characters for SHA-1 and 64 for SHA-256.
COMMIT=$(git rev-parse HEAD 2>/dev/null) || write_stop "HEAD could not be read"
case "$COMMIT" in
  ''|*[!0-9a-f]*) write_stop "HEAD did not resolve to a lowercase Git object ID" ;;
esac
case "${#COMMIT}" in
  40|64) : ;;
  *) write_stop "HEAD resolved to a malformed Git object ID (${#COMMIT} characters)" ;;
esac

tree_identity
TREE_HASH=$TREE_ID_RESULT
[ "$TREE_HASH" = "$TREE_HASH_BEFORE" ] || \
  write_stop "the Git-derived project state changed while the stages ran — the stage results describe a state that no longer exists (build outputs that are not git-ignored also trip this; check 'git status')"

# --- write the verdict ---------------------------------------------------------------------------
# Written to a temporary file in the SAME directory, then moved onto the final path; failures
# route to write_stop (D-052). Same directory, because a rename across filesystems is a copy, not
# a replace. Keep the summary's `written:` line below the mv — it must not print for a file that
# was not moved into place.
#
# Both timestamps are captured with their producer's exit status tested and their shape validated
# BEFORE jq sees them. `--argjson tse "$(date +%s)"` read only the text: a producer that emitted a
# plausible number and exited non-zero was accepted, and jq exited 0.
TIMESTAMP_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ) || write_stop "the UTC timestamp could not be read"
case "$TIMESTAMP_ISO" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) : ;;
  *) write_stop "the UTC timestamp is malformed: $TIMESTAMP_ISO" ;;
esac
TIMESTAMP_EPOCH=$(date +%s) || write_stop "the epoch timestamp could not be read"
case "$TIMESTAMP_EPOCH" in
  ''|*[!0-9]*) write_stop "the epoch timestamp is not a number: $TIMESTAMP_EPOCH" ;;
esac

# VERDICT_DIR was derived once at the path gate; do not re-derive it here. `--` because
# `mkdir -p --help` prints mkdir's usage, exits 0 and creates nothing — a success this `||` cannot
# see. POSIX requires `--` to end option parsing, and this file already relies on it for `rm`,
# `dirname` and `git check-ignore`.
mkdir -p -- "$VERDICT_DIR" || write_stop "the verdict directory $VERDICT_DIR could not be created"

stage_objects=""
for i in "${!STAGE_NAMES[@]}"; do
  s=${STAGE_NAMES[i]}
  stage_json=$(jq -n --arg n "$s" --arg r "${STAGE_RESULT[i]}" --arg d "${STAGE_DETAIL[i]}" \
     '{name:$n, result:$r, pass:($r=="pass"), detail:$d}') || \
    write_stop "the $s stage row could not be rendered as JSON"
  if [ -n "$stage_objects" ]; then
    stage_objects="$stage_objects
$stage_json"
  else
    stage_objects=$stage_json
  fi
done
stages_json=$(printf '%s\n' "$stage_objects" | jq -s '.') || \
  write_stop "the stage table could not be rendered as JSON"
stages_n=$(printf '%s' "$stages_json" | jq 'length' 2>/dev/null) || \
  write_stop "the stage table length could not be checked"
[ "$stages_n" = "${#STAGE_NAMES[@]}" ] || \
  write_stop "the stage table rendered ${stages_n:-0} of ${#STAGE_NAMES[@]} stages"

# A relative parent may begin with a dash. Prefix that spelling with `./` so mktemp receives a
# pathname-shaped template rather than an option-shaped argument; absolute and other relative
# spellings are already unambiguous.
VERDICT_TMP_DIR=$VERDICT_DIR
case "$VERDICT_TMP_DIR" in -*) VERDICT_TMP_DIR="./$VERDICT_TMP_DIR" ;; esac
VERDICT_TMP=$(mktemp "$VERDICT_TMP_DIR/.pre-deploy-verdict.XXXXXX") || \
  { VERDICT_TMP=""; write_stop "a temporary verdict file could not be created in $VERDICT_DIR"; }

jq -n \
  --argjson sv "$SCHEMA_VERSION" \
  --arg v "$VERDICT" \
  --argjson p "$([ "$VERDICT" = PASS ] && echo true || echo false)" \
  --arg c "$COMMIT" \
  --arg th "$TREE_HASH" \
  --arg ts "$TIMESTAMP_ISO" \
  --argjson tse "$TIMESTAMP_EPOCH" \
  --argjson stages "$stages_json" \
  --argjson te "$TESTS_EXECUTED" \
  --argjson spo "$SIM_PATTERN_OVERRIDDEN" \
  --arg srp "$SIM_READY_PATTERN" \
  --arg srl "$SIM_READY_LINE_SEEN" \
  --argjson swo "$SIM_WORDS_ONLY_LINES" \
  '{schema_version:$sv, verdict:$v, pass:$p, commit:$c, tree_hash:$th,
    timestamp:$ts, timestamp_epoch:$tse, stages:$stages, tests_executed:$te,
    sim_ready_pattern_overridden:$spo, sim_ready_pattern:$srp,
    sim_ready_line:$srl, sim_ready_pattern_only_lines:$swo,
    sim_startup_provenance:"not-established"}' > "$VERDICT_TMP" || \
  write_stop "the verdict JSON could not be generated"
jq empty "$VERDICT_TMP" >/dev/null 2>&1 || \
  write_stop "the verdict file did not parse back as JSON (truncated write?)"
# Re-checked at the last moment: an ignored DIRECTORY put at the path mid-run would otherwise
# swallow the `mv` — the temp file lands INSIDE it, `mv` returns 0, and the summary would print
# `written:` for a path holding no verdict file. The window between this test and the `mv` is
# narrowed, not closed.
#
# THE MOVE IS PROVEN, NOT ASSUMED. `mv` exiting 0 does not establish that this run's verdict is what
# now sits at the path. With FRC_VERDICT_PATH_OVERRIDE=--version, GNU `mv` parsed the destination as
# its own --version option, printed its version, exited 0 and moved nothing, while an EARLIER run's
# PASS stayed at the path byte-for-byte and this script printed `verdict: PASS` and `written:
# --version`. Measured 2026-08-21. `--` ends mv's option parsing; the hash below is what turns "mv
# said 0" into "the bytes at the path are the bytes this run generated".
#
# The digest is taken from STDIN on both sides (`< file`), a shell redirection with no argument
# parser, so neither read can be diverted by an option-shaped pathname. $HASH_CMD is the resolved
# SHA-256 tool and is expanded UNQUOTED on purpose — it can be `shasum -a 256`.
VERDICT_SHA_WRITTEN=$($HASH_CMD < "$VERDICT_TMP") || \
  write_stop "the generated verdict could not be hashed before the move"
VERDICT_SHA_WRITTEN=${VERDICT_SHA_WRITTEN%% *}
case "$VERDICT_SHA_WRITTEN" in
  ''|*[!0-9a-f]*) write_stop "the generated verdict hash is not a lowercase SHA-256 digest" ;;
esac
[ "${#VERDICT_SHA_WRITTEN}" -eq 64 ] || \
  write_stop "the generated verdict hash is malformed (${#VERDICT_SHA_WRITTEN} of 64 characters)"
verdict_path_ok || \
  write_stop "the verdict path $VERDICT_PATH is no longer acceptable — it changed while the stages ran"
mv -f -- "$VERDICT_TMP" "$VERDICT_PATH" || \
  write_stop "the verdict could not be moved into place at $VERDICT_PATH"
# `mv` reports success whenever ITS OWN target accepts the move — including a target that became a
# directory, or a symlink to one, in the window between the re-check just above and this line: the
# temp file lands INSIDE it under its own randomised name, and `mv` still returns 0. Assert the
# final path is a plain, non-symlink file right after the move, before anything below reports
# success on the strength of the `mv` exit status alone; a failed assertion here means no verdict
# exists at the documented path even though `mv` did not fail, and must STOP rather than let the
# summary print `written:` for a claim that was never true.
if [ ! -f "$VERDICT_PATH" ] || [ -L "$VERDICT_PATH" ]; then
  write_stop "the verdict path $VERDICT_PATH is not a plain file immediately after the move — do not read it"
fi
# ... and that plain file must be THIS RUN'S verdict. The test above establishes only that some
# regular non-symlink file is there; an earlier run's PASS satisfies it, which is exactly what a
# move that quietly did nothing leaves behind. Read the path back, validate the digest producer's
# output independently, and only then require the same digest.
VERDICT_SHA_ON_DISK=$($HASH_CMD < "$VERDICT_PATH") || \
  write_stop "the verdict at $VERDICT_PATH could not be read back after the move — do not read it"
VERDICT_SHA_ON_DISK=${VERDICT_SHA_ON_DISK%% *}
case "$VERDICT_SHA_ON_DISK" in
  ''|*[!0-9a-f]*) write_stop "the verdict read-back hash is not a lowercase SHA-256 digest — do not read the verdict" ;;
esac
[ "${#VERDICT_SHA_ON_DISK}" -eq 64 ] || \
  write_stop "the verdict read-back hash is malformed (${#VERDICT_SHA_ON_DISK} of 64 characters) — do not read the verdict"
[ "$VERDICT_SHA_ON_DISK" = "$VERDICT_SHA_WRITTEN" ] || \
  write_stop "the file at $VERDICT_PATH is not the verdict this run generated — do not read it"
# Cleared only NOW, once the file at the path has been matched to it. Cleared right after `mv` —
# as it was — a stop from
# either check above left write_stop with nothing to remove, and the temporary stayed in
# VERDICT_DIR. Under the default path that directory is git-ignored and it merely accumulates;
# under an override whose parent is the repository root it is an untracked file, which the NEXT
# run's git-clean stage then correctly fails on. On the success path the temporary no longer
# exists and `rm -f` on it is a no-op, so clearing late costs nothing.
VERDICT_TMP=""

printf 'verdict: %s\n' "$VERDICT"
for i in "${!STAGE_NAMES[@]}"; do
  printf '  %-10s %-8s %s\n' "${STAGE_NAMES[i]}" "${STAGE_RESULT[i]}" "${STAGE_DETAIL[i]}"
done
# THE OVERRIDE IS ANNOUNCED, not merely recorded in the JSON. A human reading this output is the
# audience that matters, and a verdict produced against a non-default startup banner is a verdict
# about a different question than the one the stage table describes (D-031).
if [ "$SIM_PATTERN_OVERRIDDEN" = true ]; then
  printf '\n  !! SIMULATION STARTUP PATTERN WAS OVERRIDDEN: %s\n' "$SIM_READY_PATTERN"
  printf '     This verdict does NOT assert that the robot program announced startup normally.\n'
  printf '     Set FRC_SIM_READY_PATTERN only to match a genuinely changed WPILib banner.\n\n'
fi
printf '  NOTE: sim_ready_pattern_overridden reports only whether this run used a pattern other than\n'
printf '  the default baked into this script. It does not detect a direct edit to SIM_READY_PATTERN_DEFAULT\n'
printf '  itself -- that edit moves both sides of the comparison together, so the flag stays false and\n'
printf '  the verdict is identical in shape to one using the shipped default. Check "sim_ready_pattern"\n'
printf '  in the verdict against the banner documented in SKILL.md before trusting a PASS. This gap\n'
printf '  is a defect recorded in the baseline source repository as D-051.\n\n'
printf '  NOTE: tree_hash is Git-derived, not an identity of the whole filesystem tree. Git-ignored\n'
printf '  paths are outside it; PASS does not establish that ignored build inputs stayed unchanged.\n\n'
printf '  NOTE: "tests_executed" sums tests="N" minus skipped="N" in regular, non-symlink JUnit\n'
printf '  XML written under build/test-results/test by this invocation. A positive count also requires\n'
printf '  zero reported failures/errors. It does not establish that every project test is represented\n'
printf '  or that the assertions are useful.\n\n'
printf '  NOTE: on the default path, the simulate stage requires the WHOLE line the framework\n'
printf '  prints, not just the words inside it, and writes that line to "sim_ready_line". A run with\n'
printf '  "sim_ready_pattern_overridden": true did not require that line and may leave\n'
printf '  "sim_ready_line" empty; read its simulate detail for what it matched. A whole-line match\n'
printf '  rejects a line that merely mentions the startup words, but is not evidence of which program\n'
printf '  printed it: this is a search over text in a log file, and text carries no author. So\n'
printf '  "sim_startup_provenance" reads "not-established" on every verdict, this one included, and a\n'
printf '  PASS here is not a statement that the robot program started.\n\n'
printf 'written: %s\n' "$VERDICT_PATH"

# 0 only on PASS; 1 when a FAIL or TIMEOUT verdict was written; stops exit 3. This run produces no
# verdict on a stop; if an earlier verdict could not be removed, the STOPPED line says it remains
# and must not be read. The caller must not treat a non-zero as "nearly passed".
[ "$VERDICT" = PASS ]
