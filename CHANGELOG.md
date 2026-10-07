<!-- Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md -->

# Changelog

Every release names each artifact that changed.

## [1.0.0_Alpha-7] — 2026-Oct-06

The toolkit is now called the **Unlabs AI Toolkit for FRC 2027 Season Teams**, and its repository and
web address moved with it.

- **Name and addresses.** The repository is `unlabs-llc/unlabs-ai-toolkit-frc-2027`, and the
  documentation site is `https://unlabs.co/projects/unlabs-ai-toolkit-frc-2027/`. GitHub and the site
  redirect the old addresses for browsers and links. A project that installed 1.0.0 checks the old
  API address without following redirects, so its update check stays silent; it will not report a
  later release, including a security release.
- **Version label.** The version is written `1.0.0_Alpha-7`: the toolkit's `1.0.0` plus the number of the
  WPILib 2027 pre-release it was built against (`v2027.0.0-alpha-7`). The update check understands
  this form and orders `_Alpha-N`, `_Beta-N` and `_RC-N` builds before the plain release of the same
  number.
- **Installed files.** The managed `.gitignore` block markers and the first line of the installed `CLAUDE.md` now carry
  the new name. The manifest file name (`.claude/frc-baseline-manifest.yml`), the `frc-*` skill and command names, and
  `FRC_TOOLKIT_NO_UPDATE_CHECK` are unchanged.

## [1.0.0] — 2026-Sep-12

**The first release.** There is no prior version to diff against, so this entry describes what the
release contains and what it does not do, rather than listing changes.

### What a team gets

Ten commands, four skills, one subagent, a settings template, a `CLAUDE.md` template, and an
installer that puts them into a robot project. The complete list is in
[`baseline/manifest.yml`](baseline/manifest.yml), which is the authority; the README summarises it.

- **Commands** — `/subsystem` `/command` `/auto` `/robot-debug` `/tune` `/test` `/vision-integrate`
  `/explain` `/robot-review` `/deploy`
- **Skills** — `current-wpilib-2027` (the WPILib schema host and its four reference files),
  `current-claude-models`, `frc-pre-deploy`, `frc-behavior-first`
- **Subagent** — `frc-docs-checker`, which settles whether a WPILib import or class exists by
  compiling it rather than by recalling it. It calls a shipped probe driver rather than assembling
  one, so what executes is code you can read. Acceptance-tested end to end on a generated project
- **Templates** — root `CLAUDE.md`, `settings.json` permissions, and a managed `.gitignore` block
- **Installer** — `setup/setup-frc-baseline.sh`
- **Update check** — at session start, asks GitHub whether a newer release exists and tells the
  student if one does; for a release marked as a security fix, it tells them to pause and get a
  mentor. It blocks nothing, and `FRC_TOOLKIT_NO_UPDATE_CHECK=1` turns it off
- **Support and security** — `SUPPORT.md`, `SECURITY.md`, and issue forms for bugs and
  documentation mistakes

Every one of the 28 shipped artifacts carries a PASS from an independent adversarial review, recorded
against the artifact's content hash — edit a reviewed artifact and its review re-opens by itself.
**A PASS record is not product approval:** it establishes that a review was recorded against those
exact bytes, not that the artifact is correct or that a robot is safe.

The pre-deploy test stage also requires evidence that tests exist. After the Gradle test task exits
zero, it counts `tests` minus `skipped` in fresh Gradle JUnit XML and rejects any reported failure or
error. Regular default-path XML is removed immediately before the task, so a positive count
establishes that this invocation wrote XML reporting at least one non-skipped test and no
failures/errors. Zero records `unconfirmed` and the overall verdict is `FAIL`; the verdict's
`tests_executed` field is a number when that count succeeds and `null` when it does not. The count
does not establish that every project test is represented or that its assertions are useful.

### What this release does NOT do, stated here rather than discovered later

- **There is no deploy guarantee.** `frc-pre-deploy` is a validation skill a team
  invokes; it reports and enforces nothing. The `deploy*` permission rule is a speed bump, not a gate
  — deny rules match command strings and a variant invocation evades them.
- **Validation is software-in-the-loop only.** No physical robot interfaces with the toolkit.
- **WPILib 2027 is in alpha.** Facts are pinned to the ref they were verified against and dated.
  Between alphas, package names, Gradle task names and console output can all change.
- **3 defects remain open.** All three are described
  in [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md). Two affect an installed baseline; the third
  concerns the project's own release tooling.
- **Sustaining work is not in this release.** The deploy gate reattempted at a different enforcement
  boundary, and the capabilities deliberately not built, are named in
  [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md).

### Environments, and what each one's support actually rests on

**Linux (x86-64 and aarch64) is continuously tested** — every push to the private build repository
runs the full suite on both. That CI is not part of this distribution.
**macOS is measured but not continuously tested**: shell behaviour and simulation startup were
measured on one Apple Silicon machine at one OS version.
Git Bash is the intended route on Windows, and only the installer has run there, on a hosted
`windows-latest` runner that exercises the installer, the missing-`jq` case and a failing hasher. See
[`docs/LIMITATIONS.md`](docs/LIMITATIONS.md).

---

## Trademarks

*FIRST®, FIRST® Robotics Competition, and FRC® are trademarks of For Inspiration and Recognition of
Science and Technology (FIRST). WPILib and WPI are marks of their respective owners. All other
product names, logos, and brands are the property of their respective owners, and are used here only
to identify the software this project works with. Use of them does not imply any affiliation with,
endorsement by, or sponsorship by their owners.*

*Unlabs, LLC is not affiliated with, endorsed by, or sponsored by FIRST, by Worcester Polytechnic
Institute, or by the WPILib project.*
