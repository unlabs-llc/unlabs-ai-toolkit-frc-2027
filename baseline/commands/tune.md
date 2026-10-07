---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: tune
description: Run a closed-loop tuning session on one mechanism, one gain at a time, recording what each change did.
disable-model-invocation: true
---

# /tune

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

Tune the closed loop on `$ARGUMENTS`.

## Read this before touching a gain

**Tuning happens on a real, powered robot that can move.** Treat every step below as a physical
event unless the step itself says otherwise.

- **Is the mechanism clear?** Nobody's hands in it, nothing in the path of travel, and the robot
  either on blocks or restrained if it drives.
- **Does the mechanism have working limits** — soft limits in code, hard stops in hardware, or both?
  A gain that is wrong can carry the mechanism further or faster than intended, and the limits are
  what is left when it does. They are a backstop for a bad value, not somewhere the mechanism is
  meant to arrive: if it reaches one, end the run and disable rather than watching what happens next.
- **Is somebody on the enable switch** who is watching the mechanism and not the laptop?

If any answer is no, or is not known, stop and say so.

**This checklist is per-enable, not per-session.** A tuning session is a loop, and people reach into
the mechanism between iterations — which is exactly when it gets enabled again. **Re-confirm all
three before every enable**, not once at the start. Asking a safety question once, at the beginning
of a process defined by repetition, is how a checklist becomes decoration.

**State how a new gain reaches the robot before the first change** — a live dashboard value, or a
redeploy each iteration. These are different physical procedures with different risks, and a session
that never says which one it is using will mix them.

**This command does not deploy anything and cannot make the robot safe.** It tells you what to change
and what to watch.

**Do not deploy from this session.** Not to push the next gain, not to test a hypothesis, not with a
warning attached, not after announcing it. Deploying is a physical act with a robot that can move,
and the decision belongs to the team standing next to it. If a new gain reaches the robot by
redeploy, the team runs that redeploy themselves, every iteration — see `/deploy`.

## Method

**Read the schema host** — the `current-wpilib-2027` skill owns the package roots, the framework
split and the pinned refs for this library build. **Its namespace table is a map, not an inventory,
and the host disclaims vendor APIs entirely** — so for a CTRE or REV controller, where the gains are
configured
comes from this project's source and that vendor's vendordep, not from the host and not from memory.

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

This applies to every name written into this project's constants during a tuning session, whatever
kind of name it is.

**Before changing any gain, record the rollback values.** Note the values currently in this
project's constants, and the values currently active on the robot for this session's transport —
the dashboard values, the constants in the code the team last deployed, or both. If those two sets
differ, or either is unknown, stop and ask the team which values are the rollback before changing
anything.

Then, in this order:

1. **Establish the resting behaviour — in simulation, not on the powered robot.** With all gains
   at zero, what does the mechanism do? If it falls, or drifts, note it. That is what feedforward
   has to hold, and no feedback gain will fix it cleanly. Zero gains means no control effort holding
   a gravity-loaded mechanism. The limit checks above are backstops, not permission to observe
   uncontrolled motion — make this observation in simulation, or reason it out from the mechanism
   itself. If the team ever makes it on the real robot, the mechanism must be mechanically supported
   against a fall — supported, **and** the run bounded by a hold-to-run control with a stated maximum
   duration and a hand on the enable switch. Not one or the other. Releasing the control and
   commanding disable both take control effort away; neither one is under the mechanism holding it
   up. If the mechanism cannot be supported, this observation is not made on the real robot at all —
   say so and stop. (The rule below about simulation-derived gains still stands: this step
   observes, it does not tune.)
2. **Feedforward before feedback**, for anything gravity or velocity dominated. Establish the
   mechanism-specific feedforward for predictable gravity or velocity effects first. Then tune
   feedback, including derivative damping when the observed response justifies it, around the
   remaining error.
3. **One gain at a time — which bounds how many things change, not how hard the mechanism is
   driven.** Change it, observe, record. Then the next. Before each enable, state
   what the mechanism is expected to do at this value and what ends the run — the observation is
   made, a stated maximum duration is reached, or the mechanism does anything else — and disable
   the instant one of those happens. Disable before the next change, not after it.

   **This session does not supply the number.** It has nothing to derive one from: what is safe on a
   mechanism follows from that physical mechanism and the controller driving it, and neither is in
   front of this session. **Do not offer a value.** Not in any framing — if what this session hands
   the team contains a number they could type into a gain, this session supplied it, whatever was
   written around it. A number invented here is an unestablished number commanding a powered
   mechanism.

   **What the team must be able to answer before each enable is not a form to fill in.** Both
   questions below have substantive answers; a wrong answer stops the enable exactly as a missing
   one does, and answering them is not by itself permission — the physical checklist at the top of
   this command and the run plan above still stand.

   - **Why is this value safe on this mechanism?** Not where it is written, not what unit it is in —
     why it is safe *here*. A value somebody picked in order to have something to try has no answer
     to that question, and a value that was safe on a different mechanism has an answer to a
     different question. **If nobody present can say why the value is safe on this mechanism, that is
     a mentor's question, and the enable does not happen until it is answered.** Do not enable to
     find out.
   - **What stops this mechanism short of harm while that value is active, and where is it set in
     the code the robot is running?** It has to be a bound somebody chose for this mechanism and can
     point at. **What the controller can do at full output is not that bound** — it is what happens
     when nothing is bounding it, and reporting it as a ceiling makes an unbounded run look bounded.
     If the bound cannot be pointed at in the code the robot is running, stop before the enable and
     say so.

   **After the first value, each value is reached from one already observed on this mechanism in
   this session, by a step small enough that the team can say beforehand what it should change.** A
   step whose effect nobody can predict is not an observation — it is finding out what the mechanism
   does at a number nobody has reasoned about.
4. **Record every step** — everything the preceding gain step requires answered before the
   enable, the value before, the value after, and what the mechanism visibly did. At the end of the
   session that record is the deliverable, as much as the numbers.
5. **Know when to stop.** State the acceptance condition in physical terms before starting: settles
   within so many seconds, holds position under load, no visible oscillation. Tuning without a stated
   stopping point continues until the battery dies.

## What not to do

- **Do not change two gains between observations.** You will not know which one did it.
- **Do not carry gains over from another mechanism, another robot, or last season.** Different mass,
  different gearing, different sensor. They look like a starting point and behave like a fault.
- **Do not tune to a simulation and ship the result.** State clearly which numbers came from
  simulation, because those are a starting guess, not a tune.
- **Do not leave the session with a rejected value still in the code, or an accepted value only on
  the dashboard.** Writing a value into the code so the team can deploy and try it is part of the
  redeploy workflow; leaving it there after the mechanism failed the acceptance condition is not.
  If the values were accepted, write them into the code — the code is what gets deployed. Whether a
  value that lives only in a dashboard survives a power cycle depends on properties set on the topic
  it was published to, so it is not something to assume in either direction, and either way the team
  will believe the mechanism is tuned. If they were
  rejected, put the rollback values recorded before any gain was changed back in their place.

## Before you finish

If the mechanism met the acceptance condition, write the accepted gains into this project's
constants, and print the session record — every value tried and what it did.

If it did not, say so plainly — the mechanism is not acceptable yet — rather than leaving the last
value in place as though it were a result. Restore the rollback values recorded before any gain was
changed to this project's constants, and print the session record. If a rejected value is still
active on the robot — on the dashboard, or in code the team already deployed — the mechanism is not
to be enabled again, in this session or after it, until the rollback values are active on the
robot. Tell the team so, and tell them which rollback values replace what is there. If putting them
back takes a redeploy, the team runs that redeploy themselves — see `/deploy` — and the no-enable
condition ends when the rollback values are active on the robot, not when the session ends.
