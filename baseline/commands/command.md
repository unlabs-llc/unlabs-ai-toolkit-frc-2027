---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: command
description: Scaffold a Java command class against an existing subsystem, wired to that subsystem's requirements.
arguments: NAME SUBSYSTEM
argument-hint: [name] [subsystem]
disable-model-invocation: true
---

# /command

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

Create the command `$NAME` acting on the subsystem `$SUBSYSTEM`.

> **Why this command keeps a positional `arguments:` declaration when most do not.** A named argument
> binds ONE whitespace-separated token. That is correct here and only here-and-in-`/subsystem`,
> because every value this command binds becomes or names a **Java class**, and a Java class name
> cannot contain a space. Commands whose argument is a description rather than an identifier —
> `/tune` a mechanism, `/test` a target, `/auto` a routine, `/vision-integrate` a pipeline — take
> `$ARGUMENTS` instead, after three separate sweeps mis-sorted them by guessing from the placeholder
> name. Sort by what the value BECOMES, not by what it is called.


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
framework split and the pinned refs for this library build. The command framework is one of the
areas that moved between seasons. **The host's namespace table is a map, not an inventory.**

**Establish which command framework this project is on before you write a loop.** The schema host
establishes that 2027 ships Commands v2 and Commands v3 side by side and gives their package roots;
take the project's framework from its own imports. If the project does not establish it, ask the
team and stop until they answer. Do not take the declaration kind from the host's commands
reference: the pinned WPILib `Command.java` sources establish that Commands v2 declares an abstract
class and Commands v3 declares an interface. On Commands v3 a command body that loops must yield
the coroutine backing it on every pass of that loop: that pinned v3 source warns that a loop which
does not "will prevent anything else in your robot code from running". That omission is valid Java,
so a successful `compileJava` run does not establish that the loop yields. Write no v3 loop without
that yield, and say in your report which framework you established and what established it.

**The test is membership, not familiarity.** Any name not already in this project's source and not
pinned in the host goes through the **`frc-docs-checker`** subagent before you write it. "Already
in this project's source" means in code the project compiles — a name that appears only in a
comment, or only in a file that does not compile, goes through the checker like any other. `FOUND`
clears the import or class name it names, and nothing more: write an import or class on nothing
short of `FOUND`. A method, field, or constructor is reported `UNVERIFIED` by design because the
checker does not test members, and `UNVERIFIED` is not permission to write it. Before writing a
library member, establish its exact declaration and the behavior this command relies on from
primary API documentation or source for the exact dependency version installed in this project;
for a project-defined member, read its declaration and implementation in this project's source. If
that evidence is unavailable or does not establish the needed behavior, stop and name the member
and missing evidence. Any other answer for an import or class, or no answer at all, also means stop
and say so to the team. A fabricated name feels familiar, so a trigger that fires on "names I do
not recognise" fires late.

**Read `$SUBSYSTEM` before writing against it.** If the subsystem does not exist in this project,
stop and say so. Do not create it as a side effect — that is `/subsystem`, and a subsystem invented
to satisfy a command is a subsystem nobody designed.

**Ask what this command must physically make the mechanism do.** `$NAME` is a label, not a
specification: a name like `RaiseArm` does not say how far, how fast, in which direction, or what
tells it to stop. Ask the team for the motion in their own words, for the condition that ends it,
and for what the mechanism must be left doing when it ends or is interrupted. If the team has not
answered, stop before writing the file and say what is missing. Do not read the behaviour off the
name — a name you can picture is not a behaviour the team chose.

## What to produce

1. **Requirements declared.** The command must require `$SUBSYSTEM`. This is the whole point of the
   framework: it is what stops two commands driving one mechanism in opposite directions.
2. **Use the lifecycle of the command framework established above.** Do not impose Commands v2's
   four-phase model on Commands v3. Account in the code and report for the command's path from
   scheduling through natural completion or interruption. **The interruption path is the one that
   gets skipped and the one that breaks robots.** A command that leaves a motor running when
   interrupted will keep running it. So the interruption path is not satisfied by describing what
   the code happens to do: write the state the team established as safe for this mechanism, and if
   they have not established one, stop before writing the file and say the safe interruption state
   is unestablished. Leaving the mechanism as it is counts as an answer only when the team has said
   that is safe for this mechanism. An interruption path you do not write does nothing: at the
   pinned ref, in Commands v2 and in Commands v3 alike, the default body for it is empty.
3. **A finish condition that can actually become true, including when a sensor fails.** If physical
   motion ends on a sensor, require an independent ending or cancellation path that still works when
   that sensor is absent, stale, or impossible, and trace that path into the physical state the team
   established as safe. Take every duration, travel bound, or other physical value from this
   project's code or from the team; never choose one. If no independent path and safe resulting
   state are established, stop before writing. A deliberately continuous command is an exception
   only when the team explicitly establishes that its commanded state may remain active indefinitely
   and the command makes no claim of sensor-based completion. If it ends only on a timeout, say that
   in a comment.
4. **No hardware access that bypasses the subsystem.** The command talks to `$SUBSYSTEM`, not to the
   motor controller. A command reaching past its subsystem defeats the requirement system.

## What not to do

- **Do not bind it to a button.** Binding is a driver-station decision, made once the command works.
- **Do not compose it into a group here.** One command, one job.
- **Do not swallow an exception to make the command "safe".** A command that catches everything and
  continues reports success while the mechanism does nothing.
- **Do not invent a number that controls physical behaviour or completion.** Take each such value
  from this project's code or from the team. If neither provides one, ask for it and stop until the
  team answers. The compiled program does not record where a numeric value came from, so do not
  treat a successful run as evidence that the team chose it.

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

State the interruption behaviour in one sentence: name the physical state the team established as
safe for this mechanism, and say what in the command puts the mechanism into it. If the command can
end and leave the mechanism somewhere else, it is not finished. Say that and hand it back. A note
recording the difference is not a finished command.
