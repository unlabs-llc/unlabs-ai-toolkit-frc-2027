---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: auto
description: Draft or revise a Java autonomous routine as a composition of existing commands, and check its assumptions.
disable-model-invocation: true
---

# /auto

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

Build or revise the autonomous routine named in `$ARGUMENTS`. If that is empty, ask which
routine — do not guess.

## Before writing anything

**This command writes Java.** Before writing, require a git repository containing a Gradle robot
build with an executable `./gradlew`, exactly one project applying the Java plugin, and an installed,
readable `current-wpilib-2027` schema host. If any requirement is missing, stop and say so. Before
changing a file, run that Java project's `compileJava` task through the wrapper and record its
result for comparison with the post-edit run. Describe `frc-docs-checker` no more strongly than the record supports:
disclose that the subagent runs a shipped probe driver and authors no build code of its own — the
driver creates a probe directory under `TMPDIR` (default `/tmp`), a location it does not check
against the project path, and compiles a scratch class against this project's real dependency tree,
using a static init script that ships beside it — and that this path was exercised end to end once,
on Linux, 2026-09-04, in a project generated from the WPILib extension's own alpha-7 template and
installed by this scaffold. It has NOT been exercised on Windows, nor in a project that already had
a `.claude/settings.json`; the installer cannot tell whether such a file permits the driver call,
and that file's own rules decide — a deny or ask rule that matches it comes first, the exact allow
works only when none does, and a call no rule matches falls to the session's permission mode, a
prompt by default and `UNVERIFIED` when it is refused. `docs/LIMITATIONS.md` gives the line to add.

**Read the schema host first** — the `current-wpilib-2027` skill owns the package roots, the
framework split and the pinned refs for this library build. **Its namespace table is a map, not an inventory.**

**The test is membership, not familiarity.** Any name not already in this project's source and not
pinned in the host goes through the **`frc-docs-checker`** subagent before you write it. "Already
in this project's source" means in code the project compiles — a name that appears only in a
comment, or only in a file that does not compile, goes through the checker like any other. `FOUND`
clears the import or class name it names, and nothing more: write an import or class on nothing
short of `FOUND`. A method, field, or constructor is reported `UNVERIFIED` by design because the
checker does not test members, and `UNVERIFIED` is not permission to write it. Before writing a
library member, establish its exact declaration and the behavior this routine relies on from
primary API documentation or source for the exact dependency version installed in this project;
for a project-defined member, read its declaration and implementation in this project's source. If
that evidence is unavailable or does not establish the needed behavior, stop and name the member
and missing evidence. Any other answer for an import or class, or no answer at all, also means stop
and say so to the team. A fabricated name feels familiar, so "check anything new" checks nothing.

**An autonomous routine composes commands that already exist and already work.** If a step needs a
command this project does not have, stop and name it. Do not write the mechanism logic inline inside
the routine — a routine is a sequence, not a place to hide a subsystem.

## What to produce

1. **The routine as a composition** of existing commands, in the order the robot performs them.
2. **A stated starting pose** — where on the field the robot must be placed for this to work, in
   terms a student can reproduce with the robot in their hands. "Against the wall, bumper on the
   line, facing the driver station" is usable. A raw coordinate triple is not, on its own.
3. **A time budget.** State how long the routine takes and what happens if it runs long. The
   period ends whether the routine is finished or not. Take the budget from the team's own timing
   of the steps; if they have not timed them, say the budget is unknown rather than estimating one.
4. **Every step's failure behaviour and independent bound.** For each step, determine whether any
   failure can leave it scheduled indefinitely and what physical output remains active while it is
   stuck. Do not assume the robot stands still. Every step that can remain scheduled indefinitely,
   whether it waits on a sensor or not, needs an independent ending or cancellation path whose bound
   comes from this project's code or from the team; never pick the value yourself. The only exception
   is a terminal hold for which the team explicitly establishes that the commanded state is safe for
   the rest of the autonomous period and after interruption; no later step may depend on that hold
   finishing. A timeout ends a step but does not by itself put the mechanism anywhere. Trace every
   such cancellation path through the subsystem methods it calls and include any code that takes
   control afterward in the state you evaluate. If that path can leave the robot in a state the team
   has not established as safe for what follows and for the end of the period, stop: name the step
   and command, and do not write the routine with a note about the aftermath. Do not repair the child
   command inside `/auto`; stop and hand that separate change back to the team.
5. **Hooked into however this project already selects its autonomous routine.** Find where the
   existing routines are registered, ensure this one is registered there exactly once, and note
   what the default selection is.
   If you cannot find that place, or the project does not have one, stop and say so — wiring up
   autonomous selection is an architecture decision the team makes, not a side effect of adding a
   routine.

## What not to do

- **Do not tune drivetrain or mechanism gains here.** That is `/tune`. A routine that only works at
  one set of gains will stop working when someone tunes them.
- **Do not assume the field is symmetric** unless this project's code already establishes that and
  you can point at where. Alliance handling is a real decision, not a mirror operation you can
  assume.
- **Do not invent field or robot values.** Take each such value from this project's code or from
  the team. If neither provides it, ask for it and stop until the team answers.

## Before you finish

**Compile the finished change in place, and prove each changed source reached the compiler.** For
every Java file you changed, confirm that it belongs to the source set compiled by the selected
`compileJava` task and identify one exact derived `.class` path that compiling that source produces
in that source set's class-output directory. If either fact cannot be established, stop and report
that file as not compilation-verified. Remove only those identified derived `.class` files if they
exist, then run the same task through the wrapper with `--rerun-tasks --no-build-cache`, with every
changed file in the tree. Report the before-edit and closing results. A zero exit or
`BUILD SUCCESSFUL` is not enough: if the task reports `SKIPPED`, `NO-SOURCE`, `UP-TO-DATE`, or
`FROM-CACHE`, or any identified `.class` is absent
afterward, stop and say the affected source was not shown to have reached the compiler. Fix each new
compiler failure attributable to your edit before you finish; if you cannot, quote its compiler
message and hand it over. Do not call a failure pre-existing unless the recorded before-edit result
shows it. A successful executed compile does not make the code right and changes nothing else in
this checklist; member evidence remains a separate requirement.

List every assumption the routine makes about the field and the robot's starting state, as a short
checklist a student can walk before a match. That list, not the code, is what gets used in the pit.
