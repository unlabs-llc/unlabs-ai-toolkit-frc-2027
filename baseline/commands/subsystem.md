---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: subsystem
description: Scaffold a Java robot subsystem from team-supplied hardware details and idle behaviour, stating its simulation path.
arguments: NAME
argument-hint: [name]
disable-model-invocation: true
---

# /subsystem

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

Create the subsystem `$NAME`.

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

**Read the schema host first.** The `current-wpilib-2027` skill owns the package roots, the framework
split, the Gradle task families and the pinned refs for this library build. **Its namespace table
is a map, not an inventory** — it says so itself — and the host disclaims VENDOR APIs (CTRE, REV,
PhotonVision) entirely. Those vendors' motor-controller classes therefore come from the vendordep
actually present in this project, not from the host.

**WPILib's own motor-controller classes are a different matter and ARE in the host**, under
`org.wpilib.hardware.motor` in its namespace table — the PWM controllers among them. A mechanism
wired to a PWM controller needs no vendordep at all, which is the common kit-of-parts case; do not
send a team looking for a vendor library for a device WPILib already covers. Check the host's table
before concluding a controller class is not there.

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

**The test is membership, not familiarity.** Any name — WPILib or vendor (CTRE, REV, PhotonVision) —
that is not already in this project's source, and for a WPILib name is not pinned in the schema
host, must be confirmed through the **`frc-docs-checker`** subagent before you write it into a file.
"Already in this project's source" means in code the project compiles — a name that appears only
in a comment, or only in a file that does not compile, goes through the checker like any other.
The schema host disclaims vendor APIs, but `frc-docs-checker` does not stop there: its evidence is
this project's installed vendordeps and its own compilation, so a motor-controller class goes
through the same compile-it check as a WPILib one. `FOUND` clears the import or class name it
names, and nothing more: write an import or class on nothing short of `FOUND`. A method, field, or
constructor is reported `UNVERIFIED` by design because the checker does not test members, and
`UNVERIFIED` is not permission to write it. Before writing a library member, establish its exact
declaration and the behavior this subsystem relies on from primary API documentation or source for
the exact dependency version installed in this project; for a project-defined member, read its
declaration and implementation in this project's source. If that evidence is unavailable or does
not establish the needed behavior, stop and name the member and missing evidence. Any other answer
for an import or class, or no answer at all, also means stop and say so to the team.
Remembering a name confidently is not membership — **a fabricated name feels familiar**, which is
exactly why "check anything unfamiliar" fails at the moment it is needed. The names have moved
between library builds; the host is pinned to the current one.

## What to produce

1. **Ask what the hardware actually is** before generating anything — motor controllers and their
   CAN IDs, sensors, gear ratio, and the physical limits of travel. **Do not invent a number that
   describes the hardware or bounds its motion** — a CAN ID, a gear ratio, a conversion factor, a
   travel limit, a current limit, any of them. Take each from the team, and echo every one back in
   your report. If the team has not provided a required value, or gives one hedged as a guess ("maybe
   50:1", "about 90 degrees"), stop before writing the file and say exactly what is missing.

   A hedged answer is a missing answer here. These values become named constants that look
   established, feed every unit conversion, and set the soft limits — a wrong gear ratio or travel
   bound is what drives a mechanism into its hard stop. Naming IDs alone would read as permission for
   everything the list omits.
2. **One subsystem class**, in this project's existing package and matching its existing style.
3. **Constants in one place**, named for the physical thing they describe — not `kP1`, `kP2`.
4. **The subsystem's idle behaviour, established as safe by the team before you write.** Ask the
   team what this mechanism must physically be doing when no command is using the subsystem, and
   have them establish why that is safe for this mechanism. Implement it only after both are
   established, and say whether a default command is what implements it. If the team has not
   established either one, or says they do not know, stop before writing the file and say that the
   idle behaviour is unestablished: do not choose it yourself, and do not satisfy this item by
   describing an idle behaviour nobody established. A mechanism no command is controlling does not
   necessarily stop — what it does depends on the mechanism and on what it was last commanded — and
   a successful compile does not establish that this idle behaviour is safe.
5. **The simulation path, stated either way.** If this project contains an existing simulation
   path, extend it to this subsystem. Otherwise, report that no existing simulation path was found
   and do not add simulation scaffolding. That means the subsystem's full hardware interaction
   cannot be exercised in simulation; it does not prevent unit tests of logic that can be separated
   from the hardware. Preserve or add those tests where the project has such a separation, and do
   not report them as a test of the missing hardware path.

## What not to do

- **Do not add the subsystem to a command group, an autonomous routine or a button binding.** Wiring
  it in is a separate decision the team makes when the mechanism actually works.
- **Do not set PID gains.** Ship the fields at zero with a comment pointing at `/tune`. Gains copied
  from another robot or from a previous season look like a head start and behave like a fault.
- **Do not write a unit conversion inline.** Name it, put it with the other constants, and state the
  unit in the name.

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

Say which parts you generated from the project's own code, and which parts you asked the team about.
The student needs to know which lines are theirs to check.
