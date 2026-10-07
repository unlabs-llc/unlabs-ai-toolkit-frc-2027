---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: robot-debug
description: Diagnose a described robot misbehaviour from evidence, and reach a cause before changing any code.
disable-model-invocation: true
---

# /robot-debug

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

> **Named `/robot-debug`, not `/debug`, because `/debug` is a Claude Code bundled skill.** A file
> named `debug.md` would collide with the product. This is not a stylistic choice and it must not be
> renamed back. The provenance prefix `frc-` is reserved for skills and subagents, so commands carry
> their provenance inside the file, as this one does.

The reported symptom: $ARGUMENTS — if that is empty, ask what the robot did, and start at step 1
below rather than guessing from recent changes.

## Work in this order. Do not skip to the fix.

The failure mode this command exists to prevent is a plausible fix applied to a cause nobody
confirmed. On a robot that is expensive, because the real fault is still there and now it is hidden
behind a change.

### 1. Establish what actually happens

Ask, and do not guess:

- **What did the robot physically do**, as opposed to what the code was supposed to make it do?
- **When** — enabled, disabled, autonomous, teleop, on the transition between them?
- **Every time, or sometimes?** An intermittent fault and a deterministic one have different causes
  and there is no point reasoning about the wrong one.
- **What changed since it last worked?** Code, wiring, battery, a different field, a new controller
  image. If the answer is "nothing", ask what was deployed most recently, because something changed.

### 2. Read the evidence before reading the code

Driver Station logs, the console output, and any on-robot telemetry this project publishes. State
what the evidence shows. **If there is no evidence, say so and say what to capture on the next run** —
that is a legitimate and often correct outcome for this step. Guessing harder is not.

### 3. Name candidate causes, then discriminate between them

List the causes consistent with the evidence. For each, name **the observation that would rule it
out**. Then get that observation. A cause that cannot be distinguished from another by any test you
can run is not yet a diagnosis.

**If getting the observation means enabling the robot, read this first.** The robot in this session
is misbehaving by definition — that is why this command was run. Do not assume it will fail the same
way twice, and do not assume the symptom it already showed is the worst thing it can do. Confirm,
before every enable — not once at the start, because people reach into a robot between test runs,
and that is exactly when it gets enabled again:

- **Is the robot clear?** Nobody's hands on it, nothing in the path of anything that can move, and
  the robot on blocks or restrained — until the cause is known, do not assume the fault stays in the
  mechanism it was seen in.
- **Do the mechanisms involved have working travel limits** in code or hardware? A limit whose
  failure is on the candidate list does not count as working.
- **Has the project or team established a mechanism-specific bound on the commanded force or motion
  for this test that prevents damage before a person can disable?** Physical restraint, a hard stop,
  and a maximum duration do not establish that bound. Name the code or controller setting that
  enforces it and its source; if the value or enforcement is unknown, do not enable.
- **Is somebody on the enable switch** who is watching the robot and not the laptop?

If any answer is no, or is not known, stop and say so. If the observation can be had with the robot
disabled or powered off, prefer that observation.

**State what ends the enable before you start it.** Name the observation you are enabling to get,
the physical behaviour, if any, the test needs the robot to produce, and the established bound that
limits that behavior while enabled. Use a hold-to-run control with a stated maximum duration. The
instant the observation is captured, the reported symptom reproduces, the robot begins any physical
behaviour other than the one named, the established bound is approached or exceeded, or the stated
maximum duration is reached, release the control and use the enable switch to command disable. Do
not keep the run going to see whether the behaviour gets worse: the symptom already reported is not
the only thing this robot can do.

This command cannot enable the robot and cannot make it safe — the checklist is for the people
standing next to it.

Do not stop at the first cause that fits. A story assembled before most of the evidence was in fits
the evidence that was in at the time, which is not the same thing as being the cause — put it through
the discriminating observation above like any other candidate.

### 4. Only now, propose a change

State the cause, the evidence for it, and the smallest change that addresses it. State what the
robot should do differently after the change — **before** it is applied, so the test is not written
to match the result.

<!-- FRC-API-MEMBERSHIP-BEGIN -->
**The test is membership, not familiarity.** A name recalled confidently and a name that actually
exists are not the same thing, and a fabricated name feels familiar. Any API name not pinned in the
`current-wpilib-2027` schema host goes through the **`frc-docs-checker`** subagent before it reaches
anything this session hands the team.

**A name already in this project's source is an exception only where the compiler resolved that
occurrence.** It clears this test when this project has built successfully since its last edit *and
the build could not have succeeded without the compiler resolving that occurrence as a reference to
the API it names*. An occurrence nothing in the build had to resolve is cleared by no build, however
many times the project has built. Unless somebody can say the compiler had to resolve this
occurrence, the name is not cleared here — send it to the checker.

**`FOUND` is necessary and not sufficient.** Nothing short of `FOUND` may be relied on for an import
or class name; that rule is unchanged and is not weakened by what follows. But the checker's own file
records that its operation inside a real robot project has not been demonstrated, so `FOUND`
establishes what the checker returned, not that the name resolves in this project. **Anything built
on `FOUND` stays unverified until this project compiles with it in.** Say so at the time, and say it
again at the end of the session if no build has happened since: the name is unverified, and a
successful build of this project is what would settle it.

A method, field, or constructor is reported `UNVERIFIED` by design — the checker does not test
members — so for a member, put the class it belongs to through the checker the same way, and name
the member to the team as unverified. Any other answer for an import or class, or no answer at all,
means stop and say so to the team.
<!-- FRC-API-MEMBERSHIP-END -->

This is exactly the moment a plausible-sounding fix gets proposed against an API that does not
resolve, so it applies to every name in the proposed change before the change is stated.

## Standing rules

- **Do not change more than one thing at a time.** Two simultaneous changes and an improvement tell
  you nothing about which one worked.
- **Do not delete or quiet a warning to make output cleaner.** The warning is evidence.
- **A code fault and a hardware fault look identical from the code.** Loose CAN wiring, a brownout,
  a sensor that has come unseated, and a bad battery all present as software misbehaving. Ask
  whether anyone has checked the physical robot before spending an hour in the source — **disabled,
  and powered off before anyone touches wiring, a connector or a battery.**
- **Do not deploy from this session.** Not to test a hypothesis, not with a warning attached, not
  after announcing it. Deploying is a physical act with a robot that can move, and the decision
  belongs to the team standing next to it. Say what should be deployed and what to watch for, then
  hand it over — see `/deploy`.

  *(This rule previously read "never deploy without saying so", which permitted exactly what it
  meant to forbid: announce, then deploy. A permission with a formality attached is a permission.)*
