---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: deploy
description: Walk the pre-deploy checks and hand you the deploy command to run yourself; it must not run the deploy task.
disable-model-invocation: true
---

# /deploy

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

> ## THIS COMMAND MUST NOT DEPLOY, AND IT IS NOT A GATE
>
> It reads the verdict of the validation checks the TEAM runs — checks which **build, launch a
> bounded simulation, and write a verdict file on this machine** — and then **prints the deploy
> command for a human to run**. This session runs neither the checks nor the deploy. It must not
> invoke the deploy task, and it must never be changed to. That is a rule, not a guarantee — what a
> Gradle invocation does is decided by the project's build files, not by this command's text, which
> is why the physical requirements in step 1 come before anything is run.
>
> **Why it is built this way.** This baseline has **no deploy gate**. One was designed, built, and
> **withdrawn** after three independent adversarial reviews — the command layer cannot carry a deploy
> guarantee, because instruction text does not reliably determine what gets executed. The withdrawal
> record is kept in this baseline's source repository; the installer does not copy it into this
> project.
>
> So if this command invoked the deploy task, **it would be the only thing between a student and a
> moving robot — and it is not a control.** A checklist that also pushes the button reads as
> approval. Anything that can be talked out of stopping is not a stop.
>
> **Nothing in this baseline can prevent a deploy.** A student can deploy from the WPILib extension,
> from Gradle, or by asking this assistant directly in the next message. This command informs a
> decision that remains entirely the team's.

## What to do

### 1. Require the physical procedure the checks cannot perform

This comes first — before the validation run, not after it. The validation stages are
project-controlled Gradle tasks, and build-file wiring can change what a Gradle task does without
changing its name.

**This command does not contain or claim a complete physical-safety checklist.** Ask the team and a
mentor to apply the team's applicable procedure to the current deployment setup, and require them
to state that it was completed for the correct robot in its current surroundings. If the team has
no applicable procedure, any required condition is unknown, or the mentor does not agree, stop here
and say why.

The robot must be disabled before any validation command runs and must remain disabled through the
human-run deployment; enabling afterward is a separate deliberate team action. Deployment also must
not begin until the team establishes that controller power will remain uninterrupted for the whole
deployment. If either condition is false or unknown, stop here. Re-check both after validation and
before printing the deploy command.

### 2. Require the robot-code review, then ask the team to run the validation skill

**First ask the team to invoke `/robot-review` with arguments that identify the robot code about to be
deployed, using enough invocations to cover all of it, then read every report.** An invocation with no
arguments reviews only uncommitted changes, so do not assume that default covers the code about to be
deployed. Each review must complete after the last possible change to the code it covers. Require every
reported finding to be resolved or rejected with evidence recorded in the handoff, and require every
part of that robot code which a report says was not reviewed to be covered by another current report
before continuing. If a review or a check it delegates could not complete, stop and name what did not
run and why. Do not call code defective when the review or check could not read it, and do not treat
missing output as a clean review.

**Then ask the team to run `/frc-pre-deploy` themselves, and read the verdict it wrote.** That skill
carries `disable-model-invocation: true`, which prevents implicit model invocation of the skill; it
does not remove this session's Bash capability. This session must not launch the installed runner by
Bash or any other route on the team's behalf. Wait for the team's explicit invocation and then read
the verdict it wrote.

**A verdict is fresh only if a new `/frc-pre-deploy` invocation completed after the last possible
change to the code the team is about to deploy.** Use the verdict written by that just-completed run.
Do not substitute a clean `git status` and unchanged `HEAD` for comparing the recorded `tree_hash`:
those observations can miss worktree bytes hidden by index flags and therefore do not establish a
hash match. If any file could have changed after the run, ask the team to invoke the skill again and
use only the new verdict. **That run's tree identity covers the outer repository only.** It does not
read the working-tree bytes inside a git submodule, so on a project that uses submodules ask the team
whether any submodule contents changed; if that is not known, stop here. A verdict from before the
last possible edit is not evidence about the code on the robot.

**A run that printed `STOPPED:` and exited 3 wrote no verdict at all.** That is the one outcome where
a file can sit at the verdict path that this run did not write: a stop before the path gate passed
removes nothing, and the runner says so in its own output — it reports only that what remains is
*possibly* a verdict from an earlier run, because some of its stop paths can be reached after bytes
were already moved into place. It does not claim to know which. **Treat anything found at the path
after a STOPPED run as absent**, which is the instruction either way; do not try to date it.

**If there is no fresh verdict, stop here.** Do **not** approximate its stages by running Gradle
commands yourself. An improvised run has none of what makes a verdict worth reading: the stage
ordering, the simulation budget, the fail-closed timeout semantics, or the verdict contract. A
summary you assembled by hand is not a verdict, and treating it as one is worse than having none.

**It reports; it enforces nothing.** Read every stage. A stage recorded `not-run` is not a pass —
the pipeline stops at the first failure, and everything after it was never evaluated. **Read the
verdict for what actually ran**, rather than assuming any stage list is current.

**The verdict is a file, not a stage list. Read all of it.** Fields that carry important evidence
and limits sit beside `stages`, not inside it, so reading every stage does not reach them — open the
verdict file and read what is there, rather than working from a list of field names that can go out
of date. If `sim_ready_pattern_overridden` is `true`, the simulation's
startup detection was replaced for this run, and the stage table describes a different question than
the one it looks like it answers — whatever the individual stages say. Carry that reading into step 3
and step 4 below.

**`tests_executed` is either a number or `null`.** A numeric zero means the JUnit XML count ran but
reported no non-skipped tests; the test stage records `unconfirmed`, and the verdict is not `PASS`.
`null` means no successful count was produced. Immediately before the test task, the runner removes
regular, non-symlink XML under `build/test-results/test`; a positive number is `tests` minus
`skipped`, summed from files that this invocation's test task wrote there. It permits the stage to
pass only when those files also report zero failures/errors. It does not establish that every
project test is represented or that the assertions are useful. Report the count without
strengthening it.

**`sim_ready_pattern_overridden: false` does not prove either startup constant is genuine.** That
flag reports only whether this run used a pattern other than the default baked into the script; it
cannot detect a direct edit to either baked-in value. On every run, compare `sim_ready_pattern` with
the words documented in `.claude/skills/frc-pre-deploy/SKILL.md` — `Robot program startup complete`
— and compare `sim_ready_line`, after removing a trailing carriage return and surrounding blanks as
that skill documents, with its exact whole line —
`********** Robot program startup complete **********`. Treat a missing value or either mismatch the
same way step 3 and Standing rules treat `sim_ready_pattern_overridden: true`.

**A `simulate` stage recorded `pass` did not confirm that the robot program started.** What that
stage did was look through the simulation's output for one line. The verdict records that line,
verbatim, in `sim_ready_line` — empty on a run that matched a caller-supplied pattern instead of the
documented line, which Standing rules already treat as not clean — and states in
`sim_startup_provenance` — which reads
`not-established` on every verdict, this one included — that which program printed that line was not
established. **Report what the stage matched. Do not report a confirmation**, and do not try to
repair the gap by asking the team whether their own code prints that line: an answer either way is a
recollection about source nobody has read line by line, and it settles nothing.

**`sim_ready_pattern_only_lines` is the field most likely to be skipped, and it is the one that
matters here.** It is either a number or `null`. When it is a number it is a count of lines and
that is all it is: how many lines of that simulation's output carried the words the run searched
for while not being the documented whole line. The shipped runner writes a numeric `0` only when
that count scan ran to completion and reported no such line — including a run where no line carried
those words at all. When it is `null`, no count was produced: the run stopped before the count or
the count scan could not run, the `simulate` stage records why (`error` when that evidence could not
be gathered, `not-run` when an earlier stage stopped the pipeline), and the verdict is not `PASS`.
**A number establishes nothing about which program printed any line**, and no value of it makes
the framework the author of anything. Any number other than `0` means something in that simulation
was printing those words on a line other than the documented whole line, which is the condition
under which a line matching the banner is worth least.
Standing rules below treat anything other than a numeric `0` as not clean.

### 3. State the verdict plainly

Report the result stage by stage. Do not summarise a mixed result as broadly fine. If any stage
failed or did not run, **say the robot should not be deployed and why**, in one sentence a student
can repeat to a mentor. **If `sim_ready_pattern_overridden` is `true`, say that too, by name, in the
same breath** — it is not a stage, so it will not appear if you only report stages.

### 4. Hand over the command

If and only if the required `/robot-review` reports are current for and collectively cover all robot
code about to be deployed, every reported finding is resolved or rejected with evidence recorded in
the handoff, the verdict is clean (see Standing rules), and every condition step 1 requires is both
known and still met — re-confirm them now; the validation run takes time, and hands move — print the
deploy command for the team to run themselves — the Gradle deploy task named in the
`current-wpilib-2027` schema host for this library build. Confirm the task name against the host; do
not write it from memory.

**Print it. Do not run it.**

## Standing rules

- **Never invoke the deploy task**, directly, through a script, or as a step inside anything else
  this command triggers. Not with a confirmation prompt, not "since the checks passed."
- **Never describe this command as a safety gate, a guarantee, or protection.** It is a checklist. A
  team that believes it is protected takes risks it would not otherwise take, which makes a
  misdescribed control worse than no control.
- **If the verdict is not clean, do not print the deploy command at all.** Printing it alongside a
  warning makes the warning advisory.
- **A verdict whose `tests_executed` is absent, `null`, zero, or not a number is not clean.** The
  shipped runner permits the test stage to pass only with a positive numeric count. Do not print the
  deploy command; quote the test stage's result and detail and tell the team to get a fresh verdict.
  A positive count establishes that this invocation wrote default-path XML reporting non-skipped
  tests with no failures/errors; it still does not establish that every project test is represented
  or that the assertions are useful.
- **A verdict with `sim_ready_pattern_overridden: true` is not clean, for this checklist's purposes,
  regardless of what the stage table shows.** This applies to the gate in step 4 and to the rule
  above. Do not print the deploy command; tell the team to re-run `/frc-pre-deploy` with the default
  `FRC_SIM_READY_PATTERN`. If the override was set because the WPILib startup banner itself changed,
  stop and refer that to a mentor — this checklist defines no clean-verdict path while the override
  stands.
- **The same "not clean" rule applies if either startup field fails the comparisons in step 2,
  even when `sim_ready_pattern_overridden` is `false`.** The pattern must equal
  `Robot program startup complete`; the normalized `sim_ready_line` must equal
  `********** Robot program startup complete **********`. The flag does not detect a directly
  edited baked-in default. Do not print the deploy command; tell the team to restore both startup
  constants in `.claude/skills/frc-pre-deploy/scripts/run-pre-deploy.sh` to the values documented in
  `.claude/skills/frc-pre-deploy/SKILL.md` and get a fresh verdict. If WPILib's actual startup banner
  no longer matches the documented one, stop and refer that to a mentor; this checklist defines no
  clean-verdict path for that state.
- **Never say the simulation confirmed that the robot program started.** It did not, and it cannot:
  the stage searched text in a log file, and text in a log file does not say who wrote it. Say what
  the stage matched — quote `sim_ready_line` when it is non-empty, and when it is empty quote the
  simulate stage's own `detail`, which is where a rejected line is recorded — and say that which
  program printed it was not established. Reporting a match as a confirmation is the specific thing
  this rule forbids.
- **A verdict whose `sim_startup_provenance` is absent, or reads anything other than
  `not-established`, is not clean.** The shipped script writes that field on every run with that one
  value. A verdict without it was produced by an older or altered script, and reading it as current
  is how a pre-fix verdict — one whose simulation stage accepted any line mentioning the startup
  words — gets treated as a fresh one. Do not print the deploy command; tell the team to re-run
  `/frc-pre-deploy` from the installed skill.
- **A verdict whose `sim_ready_pattern_only_lines` is anything other than a numeric `0` is not
  clean.** A number above `0` means something in that simulation printed the words the run searched
  for on a line that was not the documented framework line, and that is the shape a fabricated
  startup line makes; `null` means no count was produced, so the negative was never established.
  Do not print the deploy command in either case. For a number, say how many such lines there were,
  quote the simulate stage's `detail` — the shipped script names the first such line there on both
  the passing and the unconfirmed path — and refer it to a mentor: if the team's own code prints
  those words, the fix is in their code, because while it does, no line matching the banner tells
  anyone anything. For `null`, quote the simulate stage's `result` and `detail` — the shipped script
  records `error` there, naming what could not run, when the evidence could not be gathered — and
  tell the team to re-run `/frc-pre-deploy`; if it recurs, refer it to a mentor.
