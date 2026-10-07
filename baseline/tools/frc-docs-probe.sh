#!/usr/bin/env bash
# Unlabs AI Toolkit for FRC 2027 Season Teams — compile probe driver.
#
# WHAT THIS IS FOR. It settles whether a fully-qualified Java name exists in THIS project's
# dependency tree, by compiling a scratch class that references it. It is the executable half of the
# frc-docs-checker subagent; the subagent supplies a name and reads a verdict, and authors no code.
#
# WHY IT IS A SHIPPED SCRIPT AND NOT A BLOCK OF SHELL IN A PROMPT. Two independent reviews of the
# previous design found the same thing: the assistant assembled a dozen shell subcommands and wrote
# a Gradle init script at run time, so permitting it meant permitting code that did not exist when
# the permission was reviewed, and no permission rule could match filenames that changed every run.
# Here the executed code is shipped and reviewable, and only the NAME varies. That is the difference
# between granting a capability and granting a blank cheque.
#
# WHAT THIS DOES NOT CONTAIN, STATED PLAINLY BECAUSE A REVIEWER RAISED IT AND WAS RIGHT.
# This driver runs the project's own `./gradlew`, so the project's `build.gradle` executes -- its
# plugins, its task graph, any `doFirst` a build file adds to `compileJava`, and any annotation
# processor on the compile classpath. The init script relocates three output locations; it does not
# sandbox build-script evaluation and cannot.
# That authority is NOT NEW and is not created by this file: the shipped permission template already
# grants `Bash(./gradlew build)`. `Edit(build.gradle)` ships denied as of 2026-09-05, which closes the
# direct-edit route and nothing else: `settings.gradle` and `buildSrc/` are not denied, and a path deny
# constrains the Edit tool rather than a subprocess -- so anything able to WRITE the build file by any
# route can still execute code through that grant. This driver is one more entry point to
# the same already-granted Gradle execution, not a widening of it.
# Nor does `Edit(.claude/tools/**)` make this file tamper-proof. A path-based Edit deny constrains
# the editing tool; it does not constrain a subprocess. A Gradle build can write to this path. The
# deny stops the casual case -- an assistant editing the driver directly -- and nothing more.
#
# Usage:  frc-docs-probe.sh <fully.qualified.Name>
#
# Exit codes and their meaning to the caller:
#   0  a verdict was reached      -> read VERDICT= in the output
#   2  usage error
#   3  the name is not a probeable fully-qualified Java name  -> UNVERIFIED
#   4  probe setup failed                                     -> UNVERIFIED
#   5  the toolchain could not run, or the positive control did not compile -> UNVERIFIED
#
# A NON-ZERO EXIT IS NEVER "NOT FOUND". Only a run whose positive control compiled can distinguish
# absence from a broken toolchain, and that distinction is the whole point of the control.

set -uo pipefail

SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
INIT_SCRIPT="$SELF_DIR/frc-docs-probe.init.gradle"

# emit() both PRINTS and RECORDS. The recorded copy is what later steps read to decide the verdict,
# so a step cannot act on something the caller never saw.
VERDICT_LOG=""
emit() {
  printf '%s\n' "$*"
  [ -n "$VERDICT_LOG" ] && printf '%s\n' "$*" >> "$VERDICT_LOG"
  return 0
}
fail() { emit "VERDICT=UNVERIFIED"; emit "REASON=$1"; exit "$2"; }

NAME=${1:-}
[ -n "$NAME" ] || { emit "usage: frc-docs-probe.sh <fully.qualified.Name>"; exit 2; }
[ -f "$INIT_SCRIPT" ] || fail "the shipped init script is missing at $INIT_SCRIPT" 4
[ -x ./gradlew ] || fail "no executable ./gradlew in this project" 5

# --- the name must be a probeable fully-qualified dotted Java name ------------------------------
# Arrays, primitives, void, wildcards, static-import expressions and unqualified names are not
# probeable by this template and are UNVERIFIED rather than guessed at.
# WHITESPACE AND CONTROL CHARACTERS ARE REJECTED BEFORE THE PATTERN TEST, and a NEWLINE especially.
# `grep -E '^...$'` matches LINE BY LINE, so a two-line argument whose second line happens to match
# passed validation and was then interpolated into the scratch source. Measured 2026-09-04 against
# this driver: `a.b<newline>c.d` reached a verdict. No shell injection was possible -- the name is
# never re-evaluated by the shell -- but it defeated the "one fully-qualified name" rule and would
# have reported NOT_FOUND for a malformed input, which is a wrong ANSWER rather than an UNVERIFIED.
case $NAME in
  *[![:print:]]*) fail "the name contains a control character or newline" 3 ;;
esac
case $NAME in
  *'['*|*']'*|*'*'*|*' '*|*';'*|*'&'*|*'|'*|*'>'*|*'<'*|*'('*|*')'*|*'{'*|*'}'*|*\\*)
    fail "not a probeable name (array, wildcard or expression): $NAME" 3 ;;
esac
case $NAME in
  void|boolean|byte|short|int|long|char|float|double)
    fail "a primitive type is not a class: $NAME" 3 ;;
esac
printf '%s' "$NAME" | grep -qE '^[A-Za-z_$][A-Za-z0-9_$]*(\.[A-Za-z_$][A-Za-z0-9_$]*)+$' \
  || fail "not a fully-qualified dotted Java name: $NAME" 3
SIMPLE=${NAME##*.}

# --- one probe directory, owned by this run, under ${TMPDIR:-/tmp} ------------------------------
# Nothing below checks that that path is outside the repository: a TMPDIR set to a path inside the
# checkout puts the probe directory inside the checkout.
PROBE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/frc-docs-probe.XXXXXX") || fail "could not create a probe directory" 4
mkdir "$PROBE_DIR/src" "$PROBE_DIR/out" "$PROBE_DIR/gen" "$PROBE_DIR/hdr" \
  || fail "could not create the probe subdirectories" 4
# Two separate tests on purpose: a FAILED listing and a NON-EMPTY listing are different aborts, and
# collapsing them reads a failed listing as an empty directory.
OUT_LISTING=$(ls -A "$PROBE_DIR/out") || fail "could not list the probe output directory" 4
[ -z "$OUT_LISTING" ] || fail "the probe output directory was not empty on creation" 4

VERDICT_LOG="$PROBE_DIR/verdict.txt"
SCRATCH="ScratchProbe_${$}_${RANDOM}"

# --- compile one scratch class and report whether its .class appeared ---------------------------
# $1 = source body, $2 = label. Echoes FOUND / NOTFOUND / ERROR plus the javac line-1 diagnostic.
probe_compile() {
  local body=$1 label=$2 log rc
  rm -f -- "$PROBE_DIR/src/$SCRATCH.java" "$PROBE_DIR/out/$SCRATCH.class"
  ( set -C; printf '%s\n' "$body" > "$PROBE_DIR/src/$SCRATCH.java" ) \
    || { emit "PROBE_${label}=ERROR"; emit "PROBE_${label}_REASON=could not write the scratch source"; return 1; }
  log=$(FRC_PROBE_DIR="$PROBE_DIR" ./gradlew --no-daemon --console=plain \
        compileJava --init-script "$INIT_SCRIPT" 2>&1); rc=$?
  printf '%s\n' "$log" > "$PROBE_DIR/$label.log"
  if printf '%s' "$log" | grep -q 'FRC-PROBE-'; then
    emit "PROBE_${label}=ERROR"
    emit "PROBE_${label}_REASON=the init script refused: $(printf '%s' "$log" | grep -m1 -o 'FRC-PROBE-[A-Z-]*.*' | cut -c1-160)"
    return 1
  fi
  # A CLASS FILE ALONE IS NOT A COMPILE. A task that never invoked javac but left a file at the
  # expected path made an absent type report FOUND -- demonstrated by an independent reviewer,
  # 2026-09-04, with a stub task that exited 42 and touched the file. FOUND now requires BOTH a
  # zero exit AND the class file.
  if [ "$rc" -eq 0 ] && [ -f "$PROBE_DIR/out/$SCRATCH.class" ]; then
    emit "PROBE_${label}=FOUND"; return 0
  fi
  if [ "$rc" -eq 0 ]; then
    emit "PROBE_${label}=ERROR"
    emit "PROBE_${label}_REASON=compile reported success but wrote no class file"
    return 1
  fi
  if [ -f "$PROBE_DIR/out/$SCRATCH.class" ]; then
    emit "PROBE_${label}=ERROR"
    emit "PROBE_${label}_REASON=compile failed but a class file exists; the result is not trustworthy"
    return 1
  fi

  # ABSENCE IS A CLASSIFIED DIAGNOSTIC, NOT MERELY A FAILED BUILD. Without this, every failure shape
  # became NOT FOUND -- and an independent reviewer showed that a member (java.lang.String.length),
  # an EXISTING package (java.util), and a syntax error (java.lang.class) all returned NOT FOUND.
  # Those are wrong answers, which is worse than no answer. Only a diagnostic attached to the import
  # on line 1 of THIS scratch file, in one of the two shapes javac uses for an absent type, is
  # absence. Anything else is UNVERIFIED with the diagnostic quoted.
  local diag
  diag=$(printf '%s' "$log" | grep -m1 -E "$SCRATCH\.java:1:" | cut -c1-300)
  emit "PROBE_${label}_DIAG=${diag:-<none on the import line>}"
  if [ -z "$diag" ]; then
    emit "PROBE_${label}=INCONCLUSIVE"
    emit "PROBE_${label}_REASON=the compile failed with no diagnostic on the import line"
    return 0
  fi
  case $diag in
    *"package "*" does not exist"*) emit "PROBE_${label}=PACKAGE_ABSENT"; return 0 ;;
    *"cannot find symbol"*)         emit "PROBE_${label}=SYMBOL_ABSENT";  return 0 ;;
    *) emit "PROBE_${label}=INCONCLUSIVE"
       emit "PROBE_${label}_REASON=the import-line diagnostic is not an absence shape"
       return 0 ;;
  esac
}

emit "PROBE_DIR=$PROBE_DIR"
emit "NAME=$NAME"

# --- the positive control decides whether this run can distinguish absence at all ---------------
CONTROL='import java.lang.String;
class '"$SCRATCH"' { static final java.lang.Class<?> FRC_PROBE_REF = String.class; }'
probe_compile "$CONTROL" CONTROL
# GATE ON THE CONTROL'S RESULT, NOT ONLY ON ITS CLASS FILE. `probe_compile` classifies a non-zero
# compile that nevertheless left a class file as PROBE_CONTROL=ERROR -- "the result is not
# trustworthy" in its own words -- and the old test here looked only for the file, so such a run
# proceeded to a verdict that then claimed the control had compiled. Two independent reviewers
# found the contradiction on 2026-09-08. Both conditions are now required.
CONTROL_RESULT=$(grep -m1 '^PROBE_CONTROL=' "$VERDICT_LOG" 2>/dev/null | cut -d= -f2)
if [ ! -f "$PROBE_DIR/out/$SCRATCH.class" ] || [ "${CONTROL_RESULT:-}" != FOUND ]; then
  emit "VERDICT=UNVERIFIED"
  emit "REASON=the positive control did not compile cleanly (result: ${CONTROL_RESULT:-none}), so absence cannot be distinguished from a broken toolchain"
  emit "EVIDENCE=$PROBE_DIR/CONTROL.log"
  exit 5
fi

# --- the name under test -------------------------------------------------------------------------
PRIMARY='import '"$NAME"';
class '"$SCRATCH"' {
  static final java.lang.Class<?> FRC_PROBE_REF = '"$SIMPLE"'.class;
  static final java.lang.Class<?> FRC_PROBE_FQ_REF = '"$NAME"'.class;
}'
probe_compile "$PRIMARY" PRIMARY || { emit "VERDICT=UNVERIFIED"; emit "EVIDENCE=$PROBE_DIR"; exit 4; }

PRIMARY_RESULT=$(grep -m1 '^PROBE_PRIMARY=' "$VERDICT_LOG" 2>/dev/null | cut -d= -f2)
case ${PRIMARY_RESULT:-} in
  FOUND)
    emit "VERDICT=FOUND"
    emit "EVIDENCE=$PROBE_DIR/PRIMARY.log" ;;
  SYMBOL_ABSENT|PACKAGE_ABSENT)
    # `cannot find symbol` and `package X does not exist` are two wordings of one fact, and which
    # one javac prints depends on what it has already loaded. Neither settles, on its own, whether
    # the name is an absent TYPE or an absent PACKAGE -- so confirm with a second probe that imports
    # the name as a package. If THAT also fails, the whole name is absent.
    DISAMB='import '"$NAME"'.*;
class '"$SCRATCH"' {}'
    probe_compile "$DISAMB" DISAMB
    D=$(grep -m1 '^PROBE_DISAMB=' "$VERDICT_LOG" | cut -d= -f2)
    if [ "$D" = FOUND ]; then
      emit "VERDICT=UNVERIFIED"
      emit "REASON=the name is a PACKAGE, not a type: importing it as a package compiled"
    elif [ "$D" != PACKAGE_ABSENT ] && [ "$D" != SYMBOL_ABSENT ]; then
      # ONLY AN EXPLICIT ABSENCE SHAPE MAY BECOME NOT_FOUND. This branch previously treated every
      # non-FOUND disambiguation result as absence -- ERROR, INCONCLUSIVE and an empty result
      # included -- so a disambiguation compile that failed for an UNRELATED reason produced a
      # confident wrong answer about an API. Found by two independent reviewers, 2026-09-08.
      emit "VERDICT=UNVERIFIED"
      emit "REASON=the disambiguation compile did not produce an absence diagnostic (result: ${D:-none}); absence is not inferred from a failure of another shape"
      emit "EVIDENCE=$PROBE_DIR"
      exit 0
    else
      emit "VERDICT=NOT_FOUND"
      emit "NOTE=the positive control compiled in this same run, and a package import of the same name also failed"
      # THIS PROBE ANSWERS ABOUT TYPES. `java.lang.String.length` is syntactically indistinguishable
      # from a nested type like `com.foo.Outer.Inner`, so the driver cannot tell a member from an
      # absent type and must not pretend to. NOT_FOUND here means "not a type by this name"; it is
      # NOT evidence that a method or field of that name is absent.
      emit "SCOPE=a verdict about the name as a TYPE. Members -- methods, fields, constructors -- are not tested by this probe, so NOT_FOUND is not evidence that a member is absent"
    fi
    emit "EVIDENCE=$PROBE_DIR" ;;
  *)
    emit "VERDICT=UNVERIFIED"
    emit "REASON=the compile failed in a way that does not establish absence; see the diagnostic above"
    emit "EVIDENCE=$PROBE_DIR" ;;
esac
exit 0
