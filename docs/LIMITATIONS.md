<!-- Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md -->

Known limitations and open defects
==================================

**Last verified: 2026-09-12**

Every open defect carries an id, a date, an impact statement, and a workaround or an
explicit "none".

---

The three that matter most
----------------------------

**1. There is no deploy guarantee. This baseline does not stop unvalidated code reaching a robot.**

The design put the enforcement boundary on *shell*
*command text*, and command text does not reliably represent what will actually execute.

What you get instead is `/frc-pre-deploy`, a validation skill you invoke: five stages, one
machine-readable verdict. **It reports. It does not enforce.** The permission template also denies
`Bash(./gradlew deploy*)`, which is a **speed bump, not a gate** — deny rules match command strings,
and a variant invocation walks around them.

**2. Validation is software-in-the-loop only.**

Every check here verifies shapes, contracts, text, and — where a simulation verdict is
recorded — behaviour in simulation.

**3. WPILib 2027 is in alpha and this baseline tracks a moving target.**

Facts pinned here were verified against a specific alpha ref and are dated accordingly. Between
alphas, package names, Gradle task names, and console output can all change. Where a fact could not
be verified it is marked `[verify]` rather than filled in with something plausible.

---

What has NOT been validated
-----------------------------

None of these is a defect report — each is a gap in
what was tested.

| Surface | Coverage |
| --- | --- |
| **Linux (x86-64 and aarch64)** | **Continuously tested** — every pull request, every push to `main` and every tag on the private build repository runs the full suite on both architectures. The test suites and CI are not part of this distribution |
| **macOS** | **Measured, not continuously tested.** Shell behaviour, hashing and `mktemp` templates were measured on one Apple Silicon machine at one macOS version, and simulation startup on the same machine. No macOS run happens on any push |
| **Windows via Git Bash** | **PARTIALLY covered — the installer only.** Two mechanisms: those same triggers run a Windows-checkout proxy on Linux that reproduces the line-ending conversion a Windows clone performs, and a hosted `windows-latest` runner executes the installer itself in Git Bash on pull requests, main and tags. **Everything after installation remains unexecuted on Windows** — the validation skill, the simulation stage and the documentation checker need further validation in the field by users |

**The pre-deploy test count**
Stage 2 removes regular, non-symlink XML from `build/test-results/test` immediately before the test
task, then counts `tests` minus `skipped` from the first suite in each file written there; Gradle
writes one root suite per file. A positive count now establishes that this invocation wrote XML at
that default path reporting at least one non-skipped test and no failures/errors. It does not
establish that every project test is represented, that the assertions are useful, or that build
logic has not changed what the `test` task and its reports mean. A project configured to write XML
only to another directory fails closed with `unconfirmed`; restore the standard output path before
using this validation stage.

---

Open defects
------------

Three defects are open at v1.0.0. Two affect the installed baseline and are described in full below.
The third concerns this project's own release tooling and cannot affect an installed baseline; it is
noted at the end for completeness.

### D-063 · MAJOR · The probe driver's own control proves the toolchain, not the dependency tree

**Status: OPEN — disclosed, not fixed. The fix needs a change to the privilege boundary.**

`baseline/tools/frc-docs-probe.sh` gates `NOT FOUND` on a positive control importing
`java.lang.String`. That import is on the JDK bootclasspath and compiles with no classpath at all,
so on a project whose WPILib jars failed to resolve the control passes, every `org.wpilib` probe
fails with `package ... does not exist`, the classifier reads that shape as absence, and the driver
answers `NOT FOUND` for a class that exists.

**No recorded result is wrong**, because `frc-docs-checker` is separately instructed to compile a
WPILib control and does before any `NOT FOUND` may be reported. The exposure is a direct call to the
driver, which the permission template pre-approves.

*Every WPILib name in this entry —* `org.wpilib.framework.TimedRobot`, `org.wpilib.driverstation.Gamepad`,
`edu.wpi.first.wpilibj.Timer` — is used as an example of a probe input, not as an API claim. The
authority for what exists at which ref is the `current-wpilib-2027` schema host, which pins each fact
to the ref it was verified against.

**Why it is disclosed rather than patched.**

**One — a control derived from the probed name's parent package.** It fixed the broken-tree case and
broke the commonest one, turning `edu.wpi.first.wpilibj.Timer` from `NOT FOUND` into `UNVERIFIED`. A
removed package and an unresolved tree produce identical `javac` output, so **no control derived from
the name alone can separate them.**

**Two — a witness written from the compile classpath, matching** `org.wpilib` in file paths. Broken
in one line by the reviewer: a local jar named `org.wpilib-test-fixtures.jar` forges a positive and
restores the original false `NOT FOUND`. Over-counting is fail-open, which is the wrong direction for
a safety witness.

**Three — the same witness keyed on resolved module coordinates, plus deleting the witness before
each compile for provenance.** Rejected for two defects the remediation itself introduced: the
delete ignored its own failure (`rm -f … || true`), so the provenance guarantee did not hold; and
moving to `Configuration.incoming.resolutionResult` counted dependency-graph nodes rather than
selected artifacts, which widened positivity while being presented as a hardening.

### D-051 · MAJOR · The simulation-pattern override flag cannot see a directly edited default

**Status: OPEN — disclosed, not fixed. No mechanism inside the script can close it.**

`sim_ready_pattern_overridden` in `run-pre-deploy.sh` is computed by comparing the effective
`SIM_READY_PATTERN` against `SIM_READY_PATTERN_DEFAULT`, a constant living in the same file. Setting a
non-default `FRC_SIM_READY_PATTERN` environment variable is disclosed correctly. **Editing**
`SIM_READY_PATTERN_DEFAULT` directly is not — the comparison moves both sides together, the flag
stays `false`, and the resulting verdict is indistinguishable in shape from one produced against the
shipped default.

**The realistic path is not an attacker.** It is a team whose simulation stage started timing out
after a WPILib banner change, doing the helpful thing and correcting the constant instead of exporting
an environment variable on every run — the file's own comments tell them the pattern should match the
real banner.

**This is not a tamper-proofing complaint.** A team that edits its own verifier can defeat any
verifier.

**No constant stored in the script fixes it.** A second baseline compared against the first is exactly
as editable as the value it would police — that moves the defect one variable over rather than closing
it. The script has no access to what WPILib actually prints, so it cannot verify the pattern; it can
only disclose which pattern was used and how it was sourced.

**Mitigated, not fixed:**

* The runner prints, on every run, that `sim_ready_pattern_overridden` reports only whether this run
  used a pattern other than the default baked into the script — never whether that default is genuine
  — and points at the banner documented in `SKILL.md`.
* `SKILL.md` and `/deploy`, the verdict's consumer, both instruct a reader to check `sim_ready_pattern`
  against the documented literal on **every** verdict, not only when the override flag is `true`.

**What you should do:** read `sim_ready_pattern` in the verdict and compare it against the literal
documented in `frc-pre-deploy/SKILL.md`, every time. Do not rely on the override flag alone.

**Treat that as a diagnostic procedure, not as safety enforcement.** It asks a person to repeat an
exact string comparison on every verdict, under time pressure, and people under time pressure stop
doing that. The skill also documents that an environment override can manufacture a PASS.

### D-058 · MINOR · A release-tooling rule is asserted but not enforced

**Status: OPEN — deliberately not built yet.**

This project's release checks assert a rule about changelog `Deprecated`/`Removed` entries naming a
replacement, and that half of the rule is not implemented. It is recorded rather than built because
there is currently no entry of that kind for a detector to be tested against, and a detector validated
only against absence is not a detector.

**This cannot affect an installed baseline.** It concerns the project's own release process. It is
listed here because the count of open defects should match at a release.

---

The API checker: what it does, and the one case the installer cannot check
------------------------------------------------------------------------------

`frc-docs-checker` settles whether a WPILib class exists by **compiling** a scratch class against your
project's real dependency tree — not by recalling it. It calls a shipped driver,
`.claude/tools/frc-docs-probe.sh`, which the permission template pre-approves; the assistant passes a
name and reads a verdict, and never writes the code that runs.

**Two controls stand behind a** `NOT FOUND`, and they live in different places. Read this before you
trust one. The driver compiles a positive control of its own, and that control imports
`java.lang.String` — so it proves `javac` ran, and nothing more. `String` is on the JDK
bootclasspath and compiles against an empty classpath, so the driver's control **cannot** tell an
unresolved dependency tree from a genuinely absent class. The control that does tell them apart is
the agent's: `frc-docs-checker` is instructed to compile an import the schema host records as
present at the pinned ref — a WPILib import — before any `NOT FOUND` may be reported. This is
registered as **D-063** above.

**So: a** `NOT FOUND` reached through the agent rests on a WPILib control. A `NOT FOUND` from calling
`.claude/tools/frc-docs-probe.sh` yourself does not — the driver is pre-approved by the permission
template, so you can call it directly, and if you do, supply your own control.

**A case: a project that already had a** `.claude/settings.json`. The installer never modifies a
settings file it did not create — deliberately, so it cannot weaken permissions you chose — and it
does not inspect that file's `permissions.allow`, so it cannot tell you whether the driver call is
permitted there. That file's own rules decide, evaluated deny, then ask, then allow: a deny or ask
rule of yours that matches the driver call wins over the exact allow, whether the allow was already
there or you add it now; the exact allow works only when no deny or ask rule matches; and if no
deny, ask or allow rule matches at all, the call falls to the session's permission mode — the
default mode prompts, and a refusal (or `dontAsk`) is what produces `UNVERIFIED` with a permission
reason. A pre-existing file that carries the exact allow and nothing that denies or asks first works
normally. None of these arrangements has been tested. If the grant is missing, add this one line
to your `permissions.allow`:

```
"Bash(.claude/tools/frc-docs-probe.sh:*)"
```

and keep `"Edit(.claude/tools/**)"` in `deny`, so the driver cannot be rewritten by the thing that
runs it. **Read the driver before you grant it.** It is a shipped script you can audit in full, and
that is the point: granting it is a bounded decision about code you can see.

**What the driver does not contain.** It runs your project's own
`./gradlew`, so your `build.gradle` executes — its plugins, its task graph, and anything added to
`compileJava`. That authority is not created by the driver: the permission template already grants
`Bash(./gradlew build)`. `Edit(build.gradle)` now ships in the deny list. That rule closes the direct-edit route
only: `settings.gradle` and `buildSrc/` are not denied, and a path deny constrains the Edit tool rather
than a subprocess, so a shell heredoc still writes the file. Anything able to write your build file can
still run code through the existing grant. The
`Edit(.claude/tools/**)` deny stops an assistant editing the driver directly; it does not make the
file tamper-proof, because a path-based deny constrains the editing tool and not a subprocess.
**If you treat** `build.gradle` as a file only humans change, review changes to it the way you would
review any other executable code.

**Every check leaves a directory behind, on purpose, and you own the cleanup.** The driver creates
one directory per run under `TMPDIR` (default `/tmp`), named `frc-docs-probe.XXXXXX`, holding the
scratch source, its compiled output, and the compiler logs. Nothing removes it: every verdict ends
with an `EVIDENCE=` line pointing into that directory, and the agent is instructed to delete
nothing and to report each directory it created. That is the design, but the consequence is that the directories accumulate, one per check, for
as long as your temporary directory keeps them, which differs by platform. Fifty-four accumulated
across a single day of development on this project, totalling 2.7 MB — so this is a tidiness
problem and a stale-evidence problem, not a disk-space one.

Clearing them is safe. **Deleting a directory makes the verdict that points at
it uncheckable**, so list before you delete, and keep any you might still want:

```bash
ls -d "${TMPDIR:-/tmp}"/frc-docs-probe.*
rm -rf "${TMPDIR:-/tmp}"/frc-docs-probe.*
```

**Not established:** its behaviour on Windows. See the platform table above.

---

Capabilities deliberately not built
--------------------------------------

These were specified, considered, and left out by decision. They are listed so the gap is visible
rather than discovered.

| Not in v1.0 | Why |
| --- | --- |
| A hosted MCP server | Nobody owns hosting or support for one. Requirements exist so that if one is ever built, the known failure modes are answered first. |
| Orchestrated multi-agent packs | Out of scope by decision. v1.0 artifacts are deliberately forbidden from carrying subagent-spawning grants |
| `frc-match-scout` | It would depend on a match-data server that does not exist in installable form. Shipping a subagent that depends on software that does not exist is the exact anti-pattern this baseline argues against |
| A PowerShell twin of the installer | **Git Bash is the intended route on Windows, and only the installer has run there.** Git for Windows already requires it, and a second installer script that drifts from the first would give Windows students a different security posture from everyone else |

---

Reporting a defect
--------------------

Open an issue on this repository. Include the exit code if the scaffold produced one, the verdict JSON
if `/frc-pre-deploy` produced one, your WPILib version, and your operating system.

---

Trademarks
----------

*FIRST®, FIRST® Robotics Competition, and FRC® are trademarks of For Inspiration and Recognition of*
*Science and Technology (FIRST). WPILib and WPI are marks of their respective owners. All other*
*product names, logos, and brands are the property of their respective owners, and are used here only*
*to identify the software this project works with. Use of them does not imply any affiliation with,*
*endorsement by, or sponsorship by their owners.*

*Unlabs, LLC is not affiliated with, endorsed by, or sponsored by FIRST, by Worcester Polytechnic*
*Institute, or by the WPILib project.*
