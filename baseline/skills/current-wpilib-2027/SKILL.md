---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: current-wpilib-2027
description: Use when generating, reviewing, or explaining WPILib 2027 robot code; load this skill before any answer names a WPILib package, class, or Gradle task. It records volatile WPILib 2027 facts and available verification context, but not every fact is pinned to an immutable source.
---

# current-wpilib-2027

**Last verified: 2026-09-03**

This is a **data artifact**: it holds volatile WPILib 2027 facts and the maintainer procedure for
refreshing them, below. A citing artifact should cite a fact here rather than restate it — a
restatement needs a separate edit where it appears, while a citation does not duplicate the value.
Some restatements are deliberate; follow "Absorbing a WPILib release" below to re-check for affected
copies when a fact changes.

---

## Read this before you use any fact below

**WPILib 2027 is in ALPHA. There is no beta.** The newest release is `v2027.0.0-alpha-7`, published
2026-09-01. API names change between alpha releases. At the 2026-09-02 verification snapshot, the
shipped tag and the development branch resolve to the same commit; that identity is a snapshot, not
a promise that `main` will remain aligned — see
[`references/ref-divergence.md`](references/ref-divergence.md).

A name that is true against one ref can be false against the other, and "which ref" is not pedantry:
a team may have installed an earlier release or may be building development bytes, while an unpinned
answer describes neither reliably; the difference is code that does not compile. Not every fact below
is pinned to an immutable source. Before relying on one, use `Last verified` and whatever source
information accompanies it to judge whether it needs re-checking.

**When you do not know which ref a team is on, say so.** State what the pinned refs below establish,
but do not claim that either is the team's installed ref and do not select an import for them.

---

## Owned facts

Everything in this section is owned here. Cite it; do not restate its value.

### The two refs

| Field | Value |
|---|---|
| `release_tag` | `v2027.0.0-alpha-7` |
| `release_date` | 2026-09-01 |
| `release_is_prerelease` | yes — alpha |
| `release_tag_sha` | `b3232873240d60fe9f3d8ed6587e2770392f206c` |
| `beta_exists` | **no** |
| `dev_branch` | `main` |
| `dev_branch_sha_at_verification` | `83df3ee3ce1e892f76970ec21c8efdc00a104d4a` (2026-08-31) |
| `robot_controller` | Systemcore |
| `docs_root` | `https://docs.wpilib.org/en/2027/` |

### The namespace change — the largest 2027 break

> **2027 uses `org.wpilib`. It replaces `edu.wpi.first`, which is gone.**

Stated as a contrast pair deliberately: naming only the new root does not displace a strong prior — the
established Java default of `edu.wpi.first`. (This contrast is Java-specific; C++ and Python examples do
not use Java package names at all.)

`ref_pinned`: verified at `v2027.0.0-alpha-7` **and** `main@83df3ee` — **zero** `.java` files remain
under `edu/wpi/first/` in `wpilibj` at either ref. The refs themselves are identical only at this
verification snapshot; the namespace result does not depend on `main` remaining at that commit.

The package-by-package map is in [`references/namespaces.md`](references/namespaces.md). The C++
namespace state is recorded there too, including what was **not** established.

### Command framework

| Field | Value | `ref_pinned` |
|---|---|---|
| `commands_v2_package` | `org.wpilib.command2` | alpha-7 and `main@83df3ee` |
| `commands_v3_package` | `org.wpilib.command3` | alpha-7 and `main@83df3ee` |
| `commands_v2_superseded_package` | `edu.wpi.first.wpilibj2.command` (2026) | `v2026.2.1@c89401250fbd412ba050f595551d0a451b7307a2` |
| `commands_v3_status` | present in both current refs — 119 paths at each at the 2026-09-02 snapshot | alpha-7 and `main@83df3ee` |

**Two command frameworks ship side by side.** Ask which one a team is on rather than assuming. Details
and the class inventory: [`references/commands.md`](references/commands.md).

> *Corrected 2026-08-07.* This row previously read "399 paths at `main` against 119 at alpha-6",
> which crossed two projects: 399 is `commandsv2` on `main`, and 119 is `commandsv3` on `main` —
> neither figure was the alpha-6 value. The reference file was corrected on 2026-08-06 and **this
> row was missed**, so the host and its own reference disagreed for a day. A path count also
> measures files, not API surface: treat it as "this project is being worked on", never as "this
> much of the API changed".

### Gradle tasks

| Field | Value | Source ref |
|---|---|---|
| `deploy_task_family` | `deploy`, `deployStandalone`, `deploy<Target>`, `deployStandalone<Target>` | `wpilibsuite/deploy-utils@4c96861fd72e4ea3f42fda02cf8cb68f261b057c` |
| `simulate_task_java` | **`run`** (measured, alpha-7). The docs say `simulateJava`; **no such task exists in an alpha-7 build**, and Gradle abbreviates it to `simulateExternalJava`, which starts no robot program. | official 2027 docs, contradicted by measurement 2026-09-04 — see `references/gradle-tasks.md` |
| `simulate_task_cpp` | `simulateNative` | official 2027 docs |
| `vendordep_task` | `vendordep --url=<url>` | official 2027 docs |

> **`deploy` is a task family, not a task name.** A control that matches the literal string
> `gradlew deploy` and stops there does not cover the target-derived tasks a build may register —
> match the family, not the name. No such task name is asserted here: in the alpha-6 fixture measured
> for [`references/gradle-tasks.md`](references/gradle-tasks.md), `./gradlew tasks --all` listed
> `deploy` and `deployStandalone` and no target-derived deploy task, and whether a normally generated
> team project creates one is recorded there as **not established**. The gap is the reason to match a
> family; a specific name for it would be invented, and that file marks the question `[verify]`.
> Matching `deploy*` is not proof a robot was reached either: a build script can register its own task
> under a `deploy`-prefixed name without that task deploying anything. Full derivation:
> [`references/gradle-tasks.md`](references/gradle-tasks.md).

### Vendordep locations

| Field | Value |
|---|---|
| `vendordep_project_dir` | `<project>/vendordeps/` |
| `vendordep_system_dir_unix` | `~/wpilib/2027/vendordeps/` |
| `vendordep_system_dir_windows` | `C:\Users\Public\wpilib\2027\vendordeps\` |

### Host system requirements

**Corrected 2026-09-09: the alpha-7 release DOES state host-system requirements**, and drops
alpha-6's Arm exclusion while shipping native Arm64 installers for Windows and Linux. The alpha-7
wording is: *"WPILib requires 64-bit Windows 11 (32-bit is not supported), Ubuntu 26.04, or macOS 15
or higher."* Note that WPILib's live 2027 install guide still says Arm-based Windows 11 is
unsupported, so the two sources conflict. The alpha-6 snapshot is retained below for history: *"WPILib requires 64-bit
Windows 11 (Arm and 32-bit are not supported), Ubuntu 26.04, or macOS 15 or higher."*

The alpha-7 release notes re-establish the substance of the toolchain sentence that follows; the
retained wording below is alpha-6's: *"C++ desktop builds additionally require the
latest Visual Studio on Windows; macOS requires the Xcode Command Line Tools
(`xcode-select --install`)."*

---

## What this file does NOT own

Stated explicitly, because a schema host without a boundary becomes a junk drawer and then nobody
trusts any of it.

| Not owned here | Owned by |
|---|---|
| Game vocabulary, field dimensions, scoring elements, match phases | **nothing yet** — the season overlay is the designed owner and ships on its own tag series, but no overlay exists today; until one ships, this class is unowned |
| A team's numbers: team number, CAN IDs, network addresses, mechanism constants | the **team's own `CLAUDE.md`**, read at runtime, never embedded in a baseline artifact |
| Current limits, gear ratios, free-speed figures, any safety number | **nothing** — these are derived from the motor and gearbox, never copied |
| Claude Code model identifiers, effort tiers, context windows | `current-claude-models` (the model-currency host) |
| Claude Code hook events, the general permission-string grammar, frontmatter keys | build-time verification against Claude Code's own published documentation, not carried by this host. This host owns the WPILib task-name inventory used by `references/gradle-tasks.md`. The rendering and matching semantics of its `Bash(...)` permission strings are Claude Code facts verified at build time, not facts this host owns |
| Vendor library APIs (CTRE, REV, PhotonVision, …) | **nothing yet** — see the gaps table below |

---

## Facts this host does not claim

A gap stated is a gap a team can work around. A gap filled with something plausible is a defect that
compiles and then does the wrong thing.

| Gap | Status |
|---|---|
| 2027 kickoff date | `[verify]` — read from the official published FIRST calendar |
| Systemcore OS version | `[verify]` — not established at either ref; the release notes name the controller, not an OS version |
| C++ namespace root for 2027 | `[verify]` — the Java root is established; the C++ root was not verified and is **not** asserted by analogy |
| Vendor library 2027 compatibility | `[verify]` — vendordeps must be re-imported for 2027 alpha 5/6 projects, per the release notes; per-vendor status not established |

**`[verify]` means not established.** It is never a slot to fill with a guess.

---

## Consumers

Each artifact below carries the literal body line `Upstream: current-wpilib-2027`. Every artifact
declaring that line must appear in this list — an undeclared consumer is a defect, because a beta
bump misses it. The reverse direction is deliberately not symmetric: an entry may sit here before
its artifact exists (see below), so a list-only entry is either a plan or a stale row, and a stale
row — an entry whose artifact no longer declares, or never will — means this list is fiction.
**CI-10 checks one direction only and best-effort in the baseline's own source repository; the
baseline installer does not install it in a team project**: it fails a declaring artifact whose
name it cannot find among this section's backticked tokens, matching by substring, so a green run
corroborates the declared direction rather than proving it. It cannot see a dangling entry at all —
which of plan or stale a list-only row is gets resolved by reading this list, not by CI.

| Consumer | Wave |
|---|---|
| `CLAUDE.md.template` | 1 |
| `setup-frc-baseline.sh` | 1 |
| `settings.json.README.md` | 1 |
| `frc-pre-deploy` | 2 — **built** |
| `frc-docs-checker` | 2 — **built** |
| `subsystem` | 2 — **built** |
| `command` | 2 — **built** |
| `auto` | 2 — **built** |
| `robot-debug` | 2 — **built** |
| `tune` | 2 — **built** |
| `test` | 2 — **built** |
| `vision-integrate` | 2 — **built** |
| `explain` | 2 — **built** |
| `robot-review` | 2 — **built** |
| `deploy` | 2 — **built** |
| `frc-behavior-first` | 3 — **built** |

A consumer may be **declared here before it exists** — deliberately: CI-10 runs as soon as an artifact
lands, and a host list written after the fact is a list nobody checked. The cost of that design is that
a stale entry looks exactly like a plan. Measured 2026-08-15: the withdrawn deploy gate
(frc-deploy-gate.sh, withdrawn 2026-08-09; it is retained privately and ships nothing) and the
withdrawn code reviewer (frc-code-reviewer, withdrawn 2026-08-11 on measurement) both still sat in this
list, and CI-10 was green throughout, because it tests the other direction. Both rows are now removed;
the records live in `.claude/frc-baseline-manifest.yml` under `withdrawn:`. The two names are deliberately not
backticked in this paragraph — CI-10 harvests every backticked token in this section as a listed
consumer, and a prose mention must not re-enrol what the table no longer lists.

---

## Absorbing a WPILib release

The acceptance test for this whole design, stated in full — the shorter "only this file and the stamps"
version oversells it, and the baseline source repository's `docs/ARCHITECTURE.md` says so
(maintainer-facing; `docs/` is not installed on a team machine): **after a beta lands, the edit set
is this file and its references, the dated stamps, the installed root `CLAUDE.md` toolchain block
(or the baseline source template that renders it), and every working string step 4 finds.** A
permission grant that names a Gradle task, or a script that matches a banner line, restates a WPILib
fact **by mechanism** — a grant string has nowhere to put a citation — so those artifacts are
re-checked rather than trusted to inherit.

1. Re-fetch the release list, the tag sha, and the branch head.
2. Re-run the ref-divergence diff (the command is recorded in
   [`references/ref-divergence.md`](references/ref-divergence.md) — run it, do not re-derive it).
3. Update the tables above and the reference files. Update `Last verified`.
4. Re-check every artifact that carries a WPILib fact as a **working string** — text that is executed,
   pattern-matched, or granted as a permission, rather than read as prose — and edit it only if the fact
   it restates moved. A working string has nowhere to put a citation, so it restates the fact **by
   mechanism** rather than by choice.

   `baseline/templates/CLAUDE.md.template` is the one **recorded, deliberate** exception: its toolchain
   block restates the namespace facts on purpose (see the baseline source repository's
   `docs/ARCHITECTURE.md`, "The one recorded exception to cite-don't-restate"; `docs/` is
   maintainer-facing and is not installed on a team machine). When it and this file disagree, this
   file is right and the
   template is stale — update the restatement, never strip it.

   Every other working string is **found, not maintained**. A hand-maintained list of them named the
   `Bash(./gradlew …)` grant strings and the `run-pre-deploy.sh` banner pattern, and still missed
   a maintainer measurement script's own `./gradlew simulateJava` / `pkill -f "simulateJava"`
   invocations — a script that had already landed six days before the last correction pass touched this
   list. So this step re-derives its candidates with a search instead of maintaining one:

   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
     echo "BLOCKED: this release refresh is not running in a Git worktree; the working-string search did NOT run"
     exit 1
   }
   [ "$(pwd -P)" = "$(cd "$REPO_ROOT" && pwd -P)" ] || {
     echo "BLOCKED: run this procedure from the repository root: $REPO_ROOT; the working-string search did NOT run"
     exit 1
   }

   search_output=$(
     grep -rlE '\bsimulateJava\b|\bsimulateNative\b|\bdeployStandalone\b|org\\?\.wpilib|edu\\?\.wpi\\?\.first|edu/wpi/first' \
       --include='*.sh' --include='*.template' --include='*.json' --include='*.md' . \
       | grep -vE '(^|/)skills/current-wpilib-2027/'
     search_statuses=("${PIPESTATUS[@]}")
     [ "${search_statuses[0]}" -le 1 ] || { echo "BLOCKED: the recursive search exited ${search_statuses[0]}; its candidate list is not trustworthy and the refresh did NOT run" >&2; exit 1; }
     [ "${search_statuses[1]}" -le 1 ] || { echo "BLOCKED: the exclusion filter exited ${search_statuses[1]}; its candidate list is not trustworthy and the refresh did NOT run" >&2; exit 1; }
   ) || exit 1
   [ -n "$search_output" ] || {
     echo "BLOCKED: the working-string search returned no candidates; its root or filters may be stale and the refresh did NOT run"
     exit 1
   }
   printf '%s\n' "$search_output"
   ```

   This matches any file, outside this skill's own directory, containing one of the searched tokens —
   two simulation task names, one deploy-family task name, or a package-root spelling, plain or
   regex-escaped (a CI check that greps for `org\.wpilib` restates the fact as hard as a script that
   runs it). It searches those tokens only, not every token this file owns: bare `deploy` and
   `vendordep` are English-word-shaped and would bury the hits in prose. It does not tell working code from prose about that code — a script that
   executes `simulateJava` and a doc paragraph that explains the rename both match — so read each hit: a
   permission grant, a `case`/pattern match, or an invoked command line needs the re-check; a sentence
   citing or narrating the fact does not. It will also miss a working string that encodes a fact without
   one of these literal tokens, or that lives outside this `--include` list.
5. Run the suite's checks. **If an artifact outside steps 3–4 needs an edit, that artifact restated a
   fact instead of citing it — fix the artifact, not this file.**
6. The response window for a platform beta is **3 days**. It is short on purpose, and it is only
   survivable because this procedure is written down before the beta arrives rather than after.

---

## Sources

The current-ref tables above were re-derived on 2026-09-02, and that is the date `Last verified`
carries. Facts explicitly pinned to older refs remain historical snapshots, and facts sourced to live
documentation pages or to the `v2027.0.0-alpha-6` release notes were last checked in the 2026-08-06
pass; this refresh does not silently promote any of them to alpha-7. It is not the only date in this
file: **where a line here carries a date of its own, that date governs that line and this sentence
does not.** *(This sentence read "Every fact
above was fetched live on 2026-08-06" until 2026-08-21. That was a universal the file's own later
dated entries contradict.)* Installed readers can follow or re-run the public endpoints below and
the pinned-source procedures in the references. Maintainers also keep a fuller private record in
the build repository; it is not part of an installed project and nothing here depends on it.

| Source | Used for |
|---|---|
| `GET https://api.github.com/repos/wpilibsuite/allwpilib/releases` | release state, alpha status, no-beta |
| `GET https://api.github.com/repos/wpilibsuite/allwpilib/git/trees/<ref>?recursive=1` | namespaces, source-file/type inventory, ref divergence |
| `https://github.com/wpilibsuite/deploy-utils/tree/4c96861fd72e4ea3f42fda02cf8cb68f261b057c` | Gradle deploy task family |
| `https://docs.wpilib.org/en/2027/` — a live page, not a pinned snapshot | simulate/vendordep tasks, vendordep paths, deploy path |
| `v2027.0.0-alpha-6` release notes | system requirements, controller, upgrade path |

**No fact here came from model memory.** If you find one that did, it is a defect — report it rather
than correcting it in place, because the same fact is probably wrong somewhere else too.
