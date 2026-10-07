---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: test
description: Write or extend tests for robot code that run on a laptop, with no robot and no network attached.
disable-model-invocation: true
---

# /test

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

Write or extend tests for `$ARGUMENTS`.

## Start from the agreed behaviour

Require, as input, the behaviour the student agreed: what the mechanism should do, its limits, and
how the student will know it worked. List every separate condition that statement names, show that
list to the student, and write no test until the student has confirmed it or corrected it. Keep the
student's meaning; do not merge conditions because one setup could exercise several of them.

If no behaviour has been agreed, say **no agreed behaviour was provided** and ask the student for
it. Do not infer the intended behaviour from the implementation or the tests that already exist.
`frc-behavior-first` owns stating that behaviour and getting it agreed; this command does not invent
or approve a replacement. Do not write tests until the agreed behaviour is supplied. A behaviour the
student states or confirms here is the agreed behaviour for this run. Behaviour the team established
when `/subsystem` or `/command` wrote the code under test counts as agreed for that code once the
student points to it.

## The constraint that shapes everything here

**The test must pass on a student's laptop with no robot attached.** For most of a season there is
no robot, or there is one robot and six people who need it. A test that requires hardware is a test
that runs once.

**Read the schema host** — the `current-wpilib-2027` skill owns the package roots, the framework
split, the Gradle task families and the pinned refs. **Its namespace table is a map, not an
inventory**, and the host does not pin a test-harness setup: how this project's tests are wired
comes from this project's own
build files and existing tests.

**The test is membership, not familiarity.** Any API name not pinned in the host goes through
**`frc-docs-checker`** before you write it unless an existing occurrence in this project's source
has already been resolved by the compiler. A source occurrence clears this gate only when the
project has built successfully since that occurrence's last edit *and the build could not have
succeeded without the compiler resolving that occurrence as a reference to the API it names*.
A successful build alone is not that evidence: the relevant compile task may have been `SKIPPED` or
`NO-SOURCE`, and a comment, an excluded source set, or a file that does not compile never establishes
resolution. Unless you can say why the compiler had to resolve the occurrence, send the name to the
checker. A fabricated name feels familiar.

For a name sent to the checker, `FOUND` clears the import or class name it names, and nothing more.
The checker permits `FOUND` only after locating its scratch class's own `.class` file under that
probe's output directory; a successful Gradle invocation without that file is `UNVERIFIED`, not
evidence that the scratch source reached the compiler. A method, field, or constructor is reported
`UNVERIFIED` by design — the checker does not test members — so clear the class it belongs to the
same way and name the member to the team as unverified when you write it. Any other answer for an
import or class, or no answer at all, means stop and say so to the team.

`FOUND` establishes that the scratch import resolved through the project compile route the checker
tested. It does not establish a member's behaviour or prove that separate code you write reached the
compiler. After writing the name, report its integration as unverified until a project compile that
could not have succeeded without resolving that occurrence. A successful build whose relevant
compile task was skipped or had no source does not settle it.

**The checker attempts to settle this by compiling Java.** Its evidence is a scratch Java source file added to this
project's Gradle build and a Java compile task run over it. If this project's robot code is not built
that way, the checker cannot decide a name for it, and this command names no other route to one:
write nothing whose name this project's own compiled source does not already establish, say which
names could not be checked and that a build of this project with them in is what would establish
them, and stop rather than writing an unchecked name.

## What to write

Give every condition in the agreed behaviour one separately named test — a new test, or an existing
test that covers exactly that condition — and state which one condition that test covers. A test
covers a condition only if breaking that condition makes it fail; the fixture rule below is how you
establish that. A test may exercise other code on its way to the assertion, but do not
use one test as the named test for several agreed conditions. The requirements below still apply;
if one of them exposes a response that the agreed behaviour does not state, ask what should happen
rather than choosing an answer from the implementation. Treat the student's answer as a further
agreed condition: add it to the list and give it its own named test and mapping row.

1. **Test the logic, not the framework.** A test asserting that a getter returns what a setter set
   proves nothing. Test the thing that would be wrong: the state machine's transitions, the
   conversion, the finish condition, the limit clamp.
2. **Test the boundaries.** Zero, the limits of travel, past the limits of travel, a negative value
   where only positive makes sense, and a sensor reading of exactly the threshold.
3. **Test what happens when a sensor lies.** Unplugged, stuck at one value, or reading impossible
   nonsense. On a real robot this happens, and the code's response to it is rarely the tested path.
4. **Test the interruption path** for commands. It is the path that is skipped in review and the one
   that leaves a motor running.

## Simulation-based tests

WPILib ships simulation classes — see the `current-wpilib-2027` schema host's package map for the
exact namespace at the ref this project is on — that let a test drive a simulated encoder, step a
simulated mechanism, and move the driver station
through disabled → autonomous → teleop, **on a laptop, with no robot**. That is squarely inside this
command's constraint, and it is where a whole class of defect lives: a scheduler that deadlocks on
enable, an autonomous that never finishes, a subsystem that behaves correctly at rest and wrongly
under load.

**Do not assume another part of this baseline has covered it.** `/frc-pre-deploy`'s simulation stage
launches the robot program, waits for a configured startup pattern to appear in the log, and then
deliberately kills it — its own comment calls that `a budget for the startup LINE TO APPEAR, not a
run-to-completion time.` The stage does not test what the program does after that pattern appears: a
robot whose autonomous drives into a wall still records `simulate: pass`.

So if this project simulates, write tests that assert **behaviour over time**, not just construction:
put the mechanism in a known state, step it, and assert where it ended up. Confirm the API names
through `frc-docs-checker` first — this is exactly the corner where a plausible-sounding simulation
class name will not exist.

*No dedicated `frc-sim-verifier` skill is installed. This section supplies guidance for writing
simulation-based tests; it does not execute a simulation or compute a behavioural verdict itself.*

## The rule that this project has already paid for

**A fixture must be capable of failing the way the real thing fails.** Before you accept a green
test, break the thing it claims to test and confirm the test goes red. A test suite that has never
been observed failing is a suite whose passing means nothing.

If you cannot make a test fail on purpose, say so. That is a finding, not a formality.

## What not to do

- **Do not weaken an assertion to make a test pass.** If the test is right and the code is wrong,
  the code is wrong. Say which one you concluded and why.
- **Do not write a test that needs the network.** It will fail in the pit.
- **Do not mock the thing under test.** A mock that returns the expected answer tests the mock.
- **Do not report a suite as clean.** Report what it measured — which behaviours are covered and,
  explicitly, which are not. "Tests pass" and "the code is correct" are different claims.

## Before you finish

Report a mapping from every agreed condition to the exact named test that covers it, or to the word
**uncovered**. Name a condition with no test explicitly; do not leave it out and make the reader
infer the gap from absence. For each test in the mapping, state which condition it covers.

If any agreed condition is uncovered, do not report the work as done. State that it is not complete,
name every uncovered condition, and say what laptop-only test would cover it, what testability
change is needed before that test can be written, or that no laptop-only test can cover it — in
which case leave it **uncovered** and say so; do not invent a change to make it look testable. A passing suite does not change that result.

State plainly which of the tests you wrote or extended, mapped or not, you actually watched fail
before they passed. Do not call
the suite clean; report only what it measured and every gap the mapping shows.
