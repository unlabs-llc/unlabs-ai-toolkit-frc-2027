---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: vision-integrate
description: Wire a vision pipeline's output into a subsystem, handling the no-target and bad-target cases first.
disable-model-invocation: true
---

# /vision-integrate

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

Integrate a vision pipeline into a subsystem, both named in `$ARGUMENTS`.

**Establish which is which before writing anything, and say so back.** Neither name is created by
this command — both already exist in the project — and neither is required to be a single word. If
`$ARGUMENTS` is empty, or you cannot tell the pipeline from the subsystem, ask. Do not guess, and do
not assume the first word is the pipeline: generated vision code written against the wrong subsystem
compiles and then reports poses for the wrong part of the robot.

## Before writing anything

**Read the schema host** — the `current-wpilib-2027` skill owns the package roots, the framework
split and the pinned refs for this library build. **Its namespace table is a map, not an inventory.** Vision
code is dense with pose, transform and geometry names, and they are exactly the names a model
reconstructs incorrectly. Confirm each one through the `frc-docs-checker` subagent before it goes
in a file. `FOUND` clears the import or class name it names, and nothing more — not a method, not a
constructor, not a units or coordinate convention. A method, field, or constructor is reported
`UNVERIFIED` by design — so clear the class it belongs to the same way, and name the member to the
team as unverified when you write it. A units or coordinate convention is not a name the checker
can decide: if this project's own code, or a document the team gives you, does not establish it,
stop and ask the team. Any other answer for an import or class, or no answer at all, means stop and
say so to the team.

**For a name sent to the checker, `FOUND` is necessary and is evidence of compilation.** The checker
permits `FOUND` only after locating its scratch class's own `.class` file under that probe's output
directory; a successful Gradle invocation without that file is `UNVERIFIED`, not evidence that the
scratch source reached the compiler. `FOUND` establishes that the scratch import resolved through
the project compile route the checker tested. It does not establish a member's behaviour or prove
that separate vision code you write reached the compiler. After writing the name, report its
integration as unverified until a project compile that could not have succeeded without resolving
that occurrence. A successful build whose relevant compile task was skipped or had no source does
not settle it.

**The checker attempts to settle this by compiling Java.** Its evidence is a scratch Java source file added to this
project's Gradle build and a Java compile task run over it. If this project's robot code is not built
that way, the checker cannot decide a name for it, and this command names no other route to one:
write nothing whose name this project's own compiled source does not already establish, say which
names could not be checked and that a build of this project with them in is what would establish
them, and stop rather than writing an unchecked name.

**Ask what the camera actually is and where it is mounted.** The mounting transform — position and
orientation relative to the robot origin — is a measured physical quantity. **Do not invent it, and
do not stand a placeholder number in for it.** A transform is an input to arithmetic, and a wrong
one produces confident wrong answers rather than an error anyone can see. A zero
offset reads as a camera mounted at the robot origin, and the poses computed through it can pass
all four cases below while displaced by the whole unmeasured offset; an oversized sentinel yields
off-field poses whose rejection reads as bad vision data, not as a missing measurement. If the team
has not measured the transform, say so, tell them what to measure — the camera's position and
orientation relative to the robot origin — and stop before writing code that computes robot pose
from camera output or drives the robot from that pose. Where the constant would go, leave a comment
naming the missing measurement — a comment, not a number: a comment cannot be consumed by pose
arithmetic, and a number, whatever it is, can be. A guessed camera transform produces a pose
estimate that is confidently wrong, which is the worst thing vision can give you.

**Do not assert a vendor's API from memory.** If the pipeline is a third-party coprocessor pipeline,
its client library is not part of WPILib and the schema host does not own it. The vendordep actually
present in this project tells you which vendor libraries are installed, and at which versions — it
cannot tell you that a class name resolves. A vendor class name goes through the same
`frc-docs-checker` check as a WPILib one: its evidence is this project's installed vendordeps and
its own compilation.

## Write the failure cases first

This is the whole discipline of the command. A vision integration that only handles the good case
will drive the robot at a target it cannot see.

1. **No target in view.** Write this case first; nothing here establishes how often it happens, and
   nothing has to. What does the subsystem do — hold, stop, fall back to odometry? Answer it
   explicitly.
2. **A stale reading.** Every measurement needs a timestamp and an age check. A frozen pipeline
   returns its last good answer forever, and it looks exactly like a valid reading.
3. **An implausible reading.** A pose off the field, a distance beyond the camera's range, a jump
   larger than the robot can physically have moved. Reject it and say you rejected it.
4. **Ambiguity**, where the pipeline reports more than one solution or a low-confidence one. Decide
   what confidence is required and enforce it.

Only once those four are written does the good path get written.

**Do not invent a rejection threshold or stand a placeholder number in for one.** Use a threshold
only when you can name evidence the team can inspect that establishes it. A guess or placeholder
number is not evidence.
If the threshold is not established, say what is missing, tell the team what would establish it, and
stop before handing a vision measurement to the drivetrain's pose estimator.

## What not to do

- **Do not feed a raw vision pose straight into the drivetrain's pose estimator.** Filter first,
  along the four cases above.
- **Do not tune the alignment loop here.** That is `/tune`.
- **Do not test it only in simulation.** Record which failure modes the simulator this project uses
  actually models, exercise those in simulation, and state what remains to be verified on the
  physical robot.

## Before you finish

State where the measurement timestamp came from and how its time basis was established. If code
derives that timestamp from a latency figure, state the evidence behind that figure. State the
rejection thresholds you chose and the evidence behind them. If a number needed for the estimator
handoff is not established, say what is missing and stop before handing the vision measurement to
the drivetrain's pose estimator.
