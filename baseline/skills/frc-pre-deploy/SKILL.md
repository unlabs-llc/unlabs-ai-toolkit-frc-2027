---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: frc-pre-deploy
description: Use before deploying robot code to validate it — runs compile, unit tests, a bounded simulation launch, a warning check and a git-cleanliness check, then writes one machine-readable verdict for the team to read. Invoke it explicitly; it does not run on its own, because launching a simulation and writing a verdict are side effects a team should ask for.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/run-pre-deploy.sh)
disallowed-tools: Bash(*gradle*deploy*)
---

# frc-pre-deploy

**Last verified: 2026-09-04**

> **Confirmed against alpha-7 — 2026-09-04.** A GradleRIO `2027.0.0-alpha-7` project (Gradle 9.4.1,
> JDK 25.0.4, Linux aarch64) lists **`run`** and no task named `simulateJava`, which is why stage 3
> drives `run`. **The startup banner WAS re-measured at alpha-7 and is unchanged:** the run printed
> `********** Robot program startup complete **********`, matching the literal this skill documents.
> The alpha-6 TIMING figures below are retained as alpha-6 measurements and were not re-timed.
>
> Simulation requires the native and simulation dependencies to be declared; a build that declares
> only the Java ones fails in `RuntimeLoader` with `no wpiutiljni in java.library.path`. That is a
> misconfigured build, not an unavailable platform.

**Upstream: current-wpilib-2027**

> ## Status: measured and fixed — but its designed consumer is withdrawn
>
> Two things a reader must know before relying on this:
>
> 1. **The simulation stage is MEASURED and FIXED.** On real hardware (Apple Silicon, 10 cores,
>    macOS 26.5.2, WPILib 2027 alpha-6) `./gradlew simulateJava` **never exits** — still running at
>    180.64 s — and announced startup at **4.62 s**; this baseline's record of that run gives the
>    announcement as `********** Robot program startup complete **********`. The stage waits for that
>    whole line to appear and then attempts process-group teardown. A group-directed signal that
>    succeeds is reported as such; if no group-directed signal succeeds, the stage must establish
>    that no group member remains or record `error`. A descendant that moved itself out of that group
>    — anything that calls `setsid`/`setpgid` — is outside both operations, and neither the stage nor
>    the verdict claims it was reached. **Seeing that line is not the same
>    as knowing which program printed it**, and the stage does not claim otherwise — see *What the
>    stage watches for* below. The shipped budget is **90 s**, ~20× the
>    measurement, because that measurement came from fast hardware and a student laptop is the
>    machine that matters. Recorded as calibration data, never as a specification.
> 2. **The deploy gate designed to consume this verdict is WITHDRAWN from v1.0** after three failed
>    independent reviews (a history recorded in this baseline's source repository; the gate was
>    earlier marked DO NOT INSTALL, and that
>    notice is now the collapsed historical record). The verdict contract below is sound and was
>    reconciled against the gate mechanically — but the pair has never run end to end on a real
>    project, because one half is withdrawn and does not ship.

## What this does

Five stages, in this order, and the order is not cosmetic — **a compile failure makes every later
stage meaningless and their output noise**:

| # | Stage | Fails when |
|---|---|---|
| 1 | compile | `./gradlew compileJava` is non-zero |
| 2 | test | `./gradlew test` is non-zero or its JUnit XML reports failures/errors → `fail`; its JUnit XML count cannot be read → `error`; the executed count (`tests` minus `skipped`) is zero → `unconfirmed`. `pass` requires a positive executed count |
| 3 | simulate | the framework's startup line does not appear within the budget → **`TIMEOUT`**, recorded `timeout` when nothing resembling it appeared and `unconfirmed` when the startup *words* appeared without that line; the sim exits *before* printing it → `fail`; unavailable simulation-log, timing, or teardown evidence → `error`. **`pass` says that line appeared in the simulation's output and nothing more — not that the robot program started, and nothing about how it behaves afterwards** |
| 4 | warnings | **never** — it counts and reports; if its scan itself cannot run it records `error`, still without gating; see below |
| 5 | git-clean | the explicit `git status --ignore-submodules=none` check reports a change. The option prevents repository configuration from hiding submodule dirt. If `git status` itself fails, the stage records **`error`** — cleanliness could not be determined — and the verdict is `FAIL`: not knowing is not clean |

**The first failing stage stops the pipeline. Every stage that did not run is recorded `not-run`,
never `pass`.** A verdict summarising four passes and one skip as mostly-passed is worse than no
verdict, because the team stops reading stages.

### Stage 2 counts tests; zero is `unconfirmed`

Immediately before `./gradlew test`, the stage removes this project's regular, non-symlink
`build/test-results/test/*.xml` files. It rejects a symlinked results directory or XML file rather
than following it. After the task exits zero, it reads the first `<testsuite ...>` tag in each new
file — one suite per file as Gradle writes it — and sums decimal `tests="N"` minus `skipped="N"`.
A missing `skipped` attribute counts as zero. No matching result files is a measured count of zero.
A matching file without a usable root suite count, or an unreadable result path, is unavailable
evidence and records `error` with `tests_executed: null`; it is not silently treated as zero.

**A zero count records `unconfirmed`, sets the first failure, and stops the pipeline.** The Gradle
task did not fail, so `fail` would claim more than the evidence says. What the stage could not
establish is that any test ran. Both `unconfirmed` and `error` are gating outcomes, so neither can
produce an overall `PASS`.

The stage also sums `failures="N"` and `errors="N"`. Any non-zero total records `fail` even when a
build has configured Gradle to ignore test failures and the task exits zero.

**A positive `tests_executed` establishes that files written by this invocation's test task under
the default result path reported at least one non-skipped test and no failures or errors.** It does
not establish that every project test is represented there, that the assertions are useful, or
that a build file has not changed what the `test` task and its output mean. A project that writes
JUnit XML only to a non-default output directory fails closed with `unconfirmed` and must restore
the standard path before this stage can pass.

### Stage 4 counts warnings; it does not gate on them

It scans the **build** output from stages 1–2 and reports how many compiler warning or note lines it
saw. **It never fails the verdict**, and that is a decision rather than an oversight:

- FRC vendor libraries emit deprecation warnings constantly. A stage that failed on them would make
  the verdict red for nearly every team on day one.
- **A check that is red for everyone gets deleted** — this project BUILT one that blocked every
  ordinary build and withdrew it before release, because the certain response is that a team
  removes it — and the
  team then loses the stages that do matter.

**A zero count does not mean your code is warning-free.** Gradle skips work that is up to date, so a
build that compiled nothing legitimately emits nothing — and **the stage cannot tell those two cases
apart**. Its detail line says so rather than resolving it: distinguishing them would mean parsing
Gradle's up-to-date markers, which this stage does not do.

**The count is over the whole build output, stages 1–2**, so a unit test that prints the word
`warning:` to stdout is counted. That is why it reads "in the build output" rather than "from the
compiler".

**If the scan command cannot run** — its status is an operational error rather than grep's
"no matches" status — the stage records `error` instead of `pass`: the count was not measured,
and a stage that could not measure must not record that it passed. An `error` on this reporting-only
stage gates nothing, for the same reason the count gates nothing.

> *Corrected 2026-08-10.* This stage previously read the **simulation** log rather than the
> build output, and its pattern was line-anchored so it could not match javac's `File.java:12:
> warning:` shape anyway. It therefore passed unconditionally — one of five advertised stages doing
> nothing, in the fail-open direction. Both defects are fixed; the gating behaviour was deliberately
> not restored.

## Preconditions

- `jq` and `git` are available.
- A SHA-256 tool is available: `sha256sum` where present, otherwise `shasum` (run as
  `shasum -a 256`). With neither resolvable the script stops before running any stage — a
  `tree_hash` it cannot compute is a stop, not an empty field.
- The working directory is a git working tree.
- The verdict path — default or `FRC_VERDICT_PATH_OVERRIDE` — clears the path gate: git must
  ignore it, nothing but a regular file may already sit at it, and neither it nor its immediate
  parent may be a symlink. A refused path is a `STOPPED:` naming the rule, before anything is
  created or removed.
- A Gradle wrapper exists at `./gradlew` and is executable.
- The effective `FRC_SIM_STARTUP_BUDGET_SECONDS` value is a non-negative whole number that the
  running shell can represent in an integer comparison. An invalid value stops before any stage.
- The root project applies the Gradle `application` plugin and has an exact root task named `run`.
  **This one does NOT fail like the entries around it, and the difference matters to whoever reads
  the result.** The others stop the script before any stage runs and write no verdict. This is
  detected inside the stage-3 init script, which throws — so it is only reached if stages 1-2 pass.
  On that path the runner records `simulate: error` naming the missing piece, marks stages 4-5
  `not-run`, writes a verdict, and returns FAIL; a later failure in verdict writing itself can still
  stop without one. So in the ordinary case the team sees a failed verdict, not a silent stop — and a reader told to expect a stop will not
  recognise what is in front of them. It is listed here because it is a project requirement that
  must hold before the run is meaningful, not because it shares their failure mode.
  Stage 3 asserts both before selecting a task, and records a named cause if either is absent.
  (Java teams. C++ is out of scope for this skill as written.)

On a failed precondition the script emits exactly one line, first:

```
STOPPED: <precondition> not met
```

**On a stop, no verdict file is written.** Treat an absent verdict as no result; a half-written one
could be read as something.

A stop can also happen **after** the stages, when the run cannot produce an honest verdict file:
the Git-derived project identity could not be computed, the stage table or verdict JSON could not
be generated, or the file could not be moved into place. That identity is recorded once **before**
the stages and once **after**, and a disagreement is itself a stop — the stage results describe a
Git-visible state that no longer exists. It is not an identity of the whole filesystem tree:
Git-ignored paths are outside it. That keeps ordinary ignored build output from invalidating every
run, but it also means a `PASS` does not establish that ignored build inputs stayed unchanged.

Before a stop removes the verdict path or this run's verdict temporary, it re-runs the same
path-gate check, fresh, rather than trusting a flag recorded once when the gate first ran, and only
removes when that fresh check still passes. A stop from *before* the path has ever passed the check
removes nothing. A stop after the parent was replaced by a symlink also leaves the genuine
temporary behind rather than removing through the swapped parent. The check immediately before a
removal narrows but cannot close the check/remove race against a concurrent process with the same
user's filesystem authority. Whenever something is left sitting at the verdict path, the
`STOPPED:` line says so: do not read it. The verdict is written to a temporary file in the same
directory and moved onto the final path, so a failure mid-write is a missing verdict, not a
half-written one at the path a reader checks.

**On Ctrl-C (`SIGINT`) or `SIGTERM`, a handler attempts to signal the simulation's process group and remove this run's
temporary files, and — when that same fresh path-gate check still passes — removes the verdict at the path,
so an earlier run's `PASS` is not read as the interrupted run's result, before re-raising the
signal so the exit status reflects the interruption. That cleanup is best-effort, not a
guarantee:** a signal that lands before the handler is installed (installation happens right after
the preconditions), a `SIGKILL` (which no handler can catch), a fresh check that refuses — a
parent-directory swap is one cause of that, not the only one — or a removal that fails, leaves
the filesystem as it was. When something
remains at the path, the handler prints that it was not removed and must not be read.

### Exit codes

| Code | Meaning |
|---|---|
| `0` | verdict `PASS`, and the verdict file was moved into place |
| `1` | verdict `FAIL` or `TIMEOUT`, and the verdict file was moved into place |
| `3` | `STOPPED:` — no verdict was produced: a precondition was not met, the verdict path was refused, the Git-derived identity could not be computed or changed while the stages ran, or the file could not be written |

An interrupted run (`SIGINT`/`SIGTERM`) exits with the shell's signal status (for example 130),
not with a code from this table — see the interrupt paragraph above.

## The verdict — three values, and `TIMEOUT` is not a pass

`PASS` · `FAIL` · `TIMEOUT`

`PASS` only when compile, test, simulate and git-clean all pass — the fifth stage, warnings,
reports and never gates: its result is `pass`, or `error` when its scan itself could not run,
and neither changes the verdict. A gating stage that cannot run yields `FAIL` with the stage
named — never `PASS` with the stage skipped. Stage results are `pass` / `fail` / `timeout` / `error`
/ `not-run`, plus `unconfirmed` on the test and simulate stages: `fail` means the thing under test
failed; `error` means the stage's evidence could not be gathered; `unconfirmed` means the expected
evidence was absent without an observed failure — zero tests reported in stage 2, or startup words
without the framework's own line in stage 3. `fail`, `timeout`, `unconfirmed`, and an `error` on a
gating stage fail the verdict; a warnings-stage `error` remains non-gating.

## The verdict contract, and the conflict it had to resolve

**The writer and the reader were specified in different requests, and their schemas did not match.**
The writer's spec names `verdict` / `commit` / `timestamp`; the gate required `pass` /
`tree_hash` / `timestamp_epoch` / `schema_version`. Only `stages` was common.

That is precisely the mutual-deferral failure the writer's spec warned about — *"leaves the gate
silently unenforced while both halves believe the other covered it."*

**Resolved by emitting the union**, which is legitimately compliant with both: the writer spec
defines its fields as what the file contains *at minimum*, so a superset satisfies it, and every
field the reader requires is present.

```json
{
  "schema_version": 1,
  "verdict": "PASS",
  "pass": true,
  "commit": "<git HEAD>",
  "tree_hash": "<sha256 Git-derived project identity; ignored paths excluded>",
  "timestamp": "2026-08-07T00:00:00Z",
  "timestamp_epoch": 1785000000,
  "tests_executed": 12,
  "stages": [{"name": "compile", "result": "pass", "pass": true, "detail": ""}]
}
```

`pass` is **derived** from `verdict`, never set independently — one source of truth for one fact.
If `git rev-parse HEAD` exits non-zero or does not print a lowercase 40- or 64-hex-character Git
object ID, `commit` is treated as unread and the run is `STOPPED` without a verdict rather than
writing a `FAIL` against code it could not identify. Producer status and output shape must both
succeed.

**The block above is the minimum, not the whole file.** `tests_executed`, shown above, and five
further evidence fields sit beside `stages`; a reader that walks only `stages` never reaches any of
them:

| Field | Type | What it is |
|---|---|---|
| `tests_executed` | number or `null` | the sum of `tests="N"` minus `skipped="N"` on the first JUnit XML suite tag in each regular, non-symlink file written by this invocation's test task under `build/test-results/test/*.xml`. Gradle writes one root suite per file. Numeric `0` means the scan completed but established no non-skipped test; the test stage records `unconfirmed`, and the verdict is not `PASS`. A positive number permits the stage to pass only when the XML also reports zero failures/errors. `null` means no successful count exists because the stage did not run, the Gradle task failed, cleanup failed, or its XML evidence could not be read |
| `sim_ready_pattern_overridden` | boolean | whether this run used a pattern other than the one baked into the script |
| `sim_ready_pattern` | string | the pattern this run used |
| `sim_ready_line` | string | the simulation-log line that a successful scan matched **against the documented whole line**, verbatim and truncated at 200 characters. `""` means no line was recorded; read the simulate-stage result to distinguish a completed no-match scan from unavailable evidence. An overridden run that passed on the caller's own pattern also leaves this empty unless the documented line independently appeared, because the comparison recorded here is always against the shipped line |
| `sim_ready_pattern_only_lines` | number or `null` | when the count scan succeeds, how many lines of that run's simulation output carried the pattern this run searched for *without* being the documented whole line. A numeric `0` is emitted only when that scan measured no such line, including a run where no line carried the pattern at all; `null` carries no count and requires the simulate-stage result to explain why none was produced. A number counts lines and establishes nothing about which program printed any of them; its value on an overridden run depends entirely on the pattern the caller supplied, so it is not a detector for an override — `sim_ready_pattern_overridden` is |
| `sim_startup_provenance` | string | always `"not-established"`. Not a computed result: a fixed statement that this script searched text in a log and text carries no author |

`schema_version` stays `1`. These are additions to a superset the writer's own spec defines as what
the file holds *at minimum*, and every field the withdrawn reader requires is unchanged; bumping the
number would make that reader refuse a file it can still read correctly.

**A contract test in this baseline's source repository (not installed on a team machine) exercises
the withdrawn reader against the writer on its fixture.** It does not establish identical hashing
for every valid repository. The writer has pathname handling the withdrawn reader lacks; reconcile
the implementations before reviving a reader.

**The verdict path is gitignored.** A committed passing verdict can travel from one student's
machine to another's dirty tree, where it reads as a current pass for code that was never validated.

## This skill never deploys — and its shipped denies have different scopes

The requested safeguards have different scopes. **Report what each one actually establishes:**

| Layer | Status |
|---|---|
| `disallowed-tools` removes the deploy path | **SHIPPED AS A TURN-SCOPED DENY; RUNTIME NOT EXERCISED HERE.** The current skill frontmatter reference documents `disallowed-tools` and says it removes matching tools from the available pool while the skill is active, then clears the restriction on the next user message (Claude Code skills documentation, https://code.claude.com/docs/en/skills, read 2026-08-25). The shipped `Bash(*gradle*deploy*)` rule covers Bash command text containing `gradle` before `deploy`; that textual, skill-turn scope is the control claimed here. |
| No deploy invocation in the body | **PRESENT IN THE CURRENT SOURCE; CHECKED BY A STRUCTURAL CI SCAN.** In the build repository, a structural contract test classifies deploy-family candidates in this file and its `scripts/run-pre-deploy.sh` sibling. It requires the frontmatter deny, distinguishes that deny from an invocation, captures both scan producers' statuses, and fails the workflow's blocking pull-request step on an executable candidate or producer error. The installed skill includes the two scanned artifacts, so a team can inspect them, but that maintained test is not installed and **the installed skill cannot run it.** Nothing stops a team writing an equivalent check of its own. The scan does not attempt semantic analysis of prose beyond the candidate and invocation shapes. |
| The hook is the enforcement point | **WITHDRAWN in v1.0 — there is no hook-based enforcement.** This skill reports; nothing acts on its verdict. Separately, the scaffold installs four project-level, session-long deny rules from `baseline/templates/settings.json.template` — that is a source-repository path, not an installed one — into the team project's `.claude/settings.json`: `Bash(./gradlew deploy*)`, `Bash(./gradlew *deploy*)`, `Bash(gradle deploy*)`, and `Bash(gradle *deploy*)`. The frontmatter adds the turn-scoped deny above; the withdrawn hook and its history remain only in the baseline source repository. |

**`allowed-tools` GRANTS ONE COMMAND: THIS SKILL'S OWN RUNNER, with no trailing wildcard.**
Corrected 2026-08-28, and the reason is the sharpest thing in this file.

It previously also granted the three build tasks with a TRAILING WILDCARD after each task name. A
trailing wildcard pre-approves whatever follows it, and **Gradle accepts task-name abbreviations**: a
wrapper invocation naming the test task and then a two-letter abbreviation of the standalone deploy
task resolves to that deploy task. Measured in the alpha-6 fixture with a dry run, the resolved task
graph listed the standalone deploy task; a lone four-letter abbreviation resolved to the plain deploy
task. **Neither of those command lines contains the substring `deploy`**, so none of the four deny
rules the scaffold installs matches them, and neither does the `disallowed-tools` pattern in this
file's own frontmatter, which keys on the same substring. The result was that in the turn adjacent to
a deploy, a command that reaches the robot was pre-approved with no prompt.

The abbreviations are deliberately not spelled out here. The structural scan that guards this file
treats a runnable deploy invocation in its text as a defect, and it caught this paragraph's first
draft — correctly.

That is precisely the privilege the settings template removed on 2026-08-21 — see
`settings.json.README.md`, "There is deliberately no `Bash(./gradlew *)` grant" — silently re-granted
here by its twin. It was harmless for as long as this frontmatter was inert; it became live on
2026-08-28 when the copyright notice moved inside the fence, and an independent review found it
the same day. **A grant that costs nothing while it is ignored is not safe; it is dormant.**

The five removed grants served no documented step: the only run instruction in this file invokes the
runner, and the body never tells the model to call `./gradlew` or `git` directly. What the narrowing
costs is at most a permission prompt on a command this skill does not instruct.

**Do not read `allowed-tools` as the deny.** The `disallowed-tools` rule above is the scoped
frontmatter restriction; `allowed-tools` pre-approves matching tools and does not remove unlisted
tools. An unlisted tool follows the active permission mode: it may require
approval, be allowed, or be denied without a prompt in `dontAsk`. Separating the checks from the
action preserves a human approval step only when the active permission configuration requires one.

## Running it

```
${CLAUDE_SKILL_DIR}/scripts/run-pre-deploy.sh
```

It is **explicit-invocation only** (`disable-model-invocation: true`). Launching a simulation and
writing a verdict are side effects, and an autonomous run produces verdicts the team never asked for
and may not notice are stale.

The script exits `0` only on `PASS` — and only after the file at the verdict path has been read
back and its SHA-256 confirmed identical to the verdict this run generated. A `mv` that reports
success is not by itself treated as the file being in place. `1` means a
`FAIL` or `TIMEOUT` verdict was written; `3` means `STOPPED:` and this run produced no verdict. If
an earlier verdict could not be removed, the stop line says it remains (see the exit-code table
above). **A non-zero exit is not "nearly passed."**

## The simulation ceiling — measured, and why it is 20× the measurement

**Measured 2026-08-09** on an Apple Silicon Mac (10 cores, 34 GB, macOS 26.5.2, JDK 26.0.1) running
WPILib 2027 alpha-6 natively, warm Gradle cache:

| | |
|---|---|
| The startup line appeared at | **4.62 s** |
| Does `simulateJava` exit on its own? | **No** — still running at 180.64 s |
| Shipped budget | **90 s** (`FRC_SIM_STARTUP_BUDGET_SECONDS`) |

### Script-specific FRC controls

This table documents the skill's `FRC_` controls; it is not a complete inventory of inherited
environment. The invoking shell and external tools can consume other environment independently of
these controls. For example, noninteractive Bash reads startup code from the file named by
`BASH_ENV` before this script begins, so verdict-sensitive runs must also control their inherited
execution environment.

| Variable | Default | What it changes |
|---|---|---|
| `FRC_SIM_STARTUP_BUDGET_SECONDS` | `90` | Whole-second startup polling budget. The stage scans immediately after launch and again after each completed one-second wait through the configured boundary. The effective value must contain only decimal digits and be representable in an integer comparison by the running shell; otherwise the run is `STOPPED` before any stage. |
| `FRC_VERDICT_PATH_OVERRIDE` | `.claude/frc/pre-deploy-verdict.json` | Where the verdict is written. The path must be one git ignores, nothing but a regular file may already sit at it, and neither it nor its immediate parent may be a symlink — anything else is refused with a `STOPPED:` before the run creates or removes anything, and the same check is repeated just before the file is moved into place |
| `FRC_SIM_READY_PATTERN` | `Robot program startup complete` | **The words the simulation stage looks for.** Giving it a non-default value also drops the whole-line requirement for that run — see the note below |

> **Setting it is now recorded in the verdict.** A run with a non-default pattern writes
> `sim_ready_pattern_overridden: true` and the pattern itself into the JSON, and prints a block
> saying the verdict does **not** assert that the robot program announced startup normally. **That
> closes the `FRC_SIM_READY_PATTERN` path — a non-default pattern is never silent. Read that line
> before trusting a PASS.**
>
> **Giving it a non-default value also drops the whole-line requirement for that run**, and there is no second variable
> that restores it. The decorated line the stage otherwise requires is a property of the shipped
> banner; a caller who has asserted the banner changed has left nothing to compare the decoration
> against. That run falls back to a substring test for the pattern given — which is why `/deploy`
> treats `sim_ready_pattern_overridden: true` as not clean regardless of what the stage table says.
>
> **It does not close the other path.** `sim_ready_pattern_overridden` is computed by comparing the
> effective pattern to the `SIM_READY_PATTERN_DEFAULT` constant inside `run-pre-deploy.sh` itself.
> Editing that constant directly — say, to stop a simulation stage that started timing out after a
> WPILib banner change, instead of exporting an environment variable — moves both sides of the
> comparison together, so the flag reads `false` and the verdict looks exactly like one produced
> against the shipped default. **No constant this script could compare against would fix that**: any
> baseline it carries is exactly as editable as the default it would be policing. The script cannot
> verify that `sim_ready_pattern` matches what WPILib actually prints — it can only disclose what
> pattern was used. **Read `sim_ready_pattern` against the literal banner below on every verdict, not
> only when `sim_ready_pattern_overridden` is `true`.** That gap is a defect this baseline
> records as D-051 in `docs/LIMITATIONS.md`.
>
> **`FRC_SIM_READY_PATTERN` CAN MANUFACTURE A PASS, and that is not a hypothetical.** Measured
> 2026-08-10: a simulation that never announces startup yields `TIMEOUT`, exit 1; the same run with
> `FRC_SIM_READY_PATTERN="Starting"` yields **`PASS`, exit 0**. Set it only to match a genuinely
> changed WPILib banner, never to make a red stage go green. A verdict produced with it set is a
> verdict about a different question than the one the stage table describes.

**Calibration data, not a specification.** That machine is near the fast end of what students use.
The budget sits ~20× above it deliberately: **a ceiling calibrated on fast hardware false-fails a
donated laptop**, and a validation step that cries wolf is one students stop running. Erring toward
a generous budget costs seconds; erring tight costs the mitigation entirely.

**What the stage watches for.** A whole line of the simulation's output equal to
`********** Robot program startup complete **********`, decoration included — verified at source in
WPILib at commit `878da3d54cbc6b64d663bded17d87d5bed040ed9`, which is what the annotated tag
`v2027.0.0-alpha-6` dereferences to. A trailing carriage return and any surrounding blanks are
removed before the comparison, so a JVM writing CRLF on Windows still matches. **A reworded or
redecorated banner makes this stage fail closed**, reporting `TIMEOUT` on a healthy simulation. That
is the correct direction and it is stated here rather than left to be discovered. Re-verify the line
on any WPILib bump; regression fixtures assert the fail-closed behaviour so it stays visible.

**Why the whole line, and what that still does not buy.** A substring test over the log is satisfied
by any line that mentions those words anywhere, and **the project's own code runs before the
framework prints this line** — Java constructs the team's robot in `RobotBase` before
`TimedRobot.startCompetition()` prints it, and calls the team-overridable `simulationInit()` first;
the C++ path has the same order. So a line printed out of the project reaches the log ahead of the
framework's and satisfies a substring search. Measured 2026-08-21 against an earlier revision of
this script: a simulation whose only output was `TEAM-CONSTRUCTOR: Robot program startup complete
(framework banner never reached)` produced `PASS`, exit 0, `simulate: pass`.

**Requiring the whole line rejects a line that merely mentions the words. It does not establish
which program printed the line, and nothing this script can do would.** A project that prints this
exact line still matches: text in a log carries no author. The verdict therefore records
`sim_startup_provenance: "not-established"` on **every** run, including a `PASS`, and the stage's
own detail says the same. **Read a `pass` here as "that line appeared", never as "the robot program
started."**

**If a real student's round trip ever exceeds what they will wait for**, revisit the design rather
than the wording.
