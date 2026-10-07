<!-- Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md -->

# `settings.json.template` — what each rule is for, and what it does not do

**Last verified: 2026-09-05** · **Upstream: current-wpilib-2027**

The template is what `setup/setup-frc-baseline.sh` installs as `.claude/settings.json`, and it
installs it only when that file does not already exist: when it does, the installer writes nothing
to it and prints an instruction to compare the existing file against this template by hand. The
template ships as a standalone, diffable file rather than a heredoc inside the setup script so that
the comparison is one a team can actually make. This document is its rationale. The template
itself carries **no comments**: `$comment` is not a documented settings key and this suite does not
put unverified keys in a security artifact.

---

## Version floor: Claude Code v2.1.228

Three version requirements are stated on the vendor's permissions page, and this section quotes them
rather than paraphrasing (verified 2026-08-21 against `code.claude.com/docs/en/permissions.md`).
From its "Read and Edit" section: "A `Read` deny rule also blocks the Edit and Write tools on the
same path, including creating a new file there. NotebookEdit isn't covered, so add an `Edit` deny
rule for paths no tool may change. The check requires Claude Code v2.1.208 or later on edits, and
v2.1.228 or later on writes." The paragraph that follows it — the one saying file permission checks
consult `Edit(path)` and `Read(path)` rules only, that a rule written for `Write`, `NotebookEdit`,
`Glob` or `MultiEdit` is accepted but never consulted, and that Claude Code warns at startup about
one — ends: "Requires Claude Code v2.1.210 or later."

The floor is the highest of the three. Below v2.1.228 that page does not establish that a write to a
denied path is checked at all; below v2.1.210 the startup warning about an ineffective path-rule form
is absent. This template uses only `Edit(path)` and `Read(path)`, which are the two forms that page
says file permission checks consult.

Read that page, not the changelog, for these numbers. An independent pass on 2026-08-21 checked the
product changelog alone and reported the floor as unsourced: the 2.1.210 entry names the startup
warning, but the 2.1.208 and 2.1.228 entries do not name the file-permission change at all. The
changelog's silence is not a contradiction of the page, and the page is what is cited here.

Stated rather than assumed, because a template that silently needs a newer version than the team has
is a template that appears to work. The floor is also delivered rather than only written down, in
three places, each with its own limit:

- The `CLAUDE.md` the scaffold WRITES names it. A `CLAUDE.md` already in place is left alone, so it
  gets nothing — and the run does not inspect it for this either: what it compares in an existing
  `CLAUDE.md` is that file's three marked blocks and its first-line provenance header.
- The scaffold prints the floor at the end of a successful run.
- Where a `claude` executable is on the PATH, the scaffold reads `claude --version` and reports what
  it found. Below the floor, unreadable, and no `claude` on the PATH are warnings; at or above the
  floor is an informational line, not a warning. None of the four blocks the install. A version it
  cannot read is reported as NOT CHECKED rather than as fine, and nothing else about the installed
  version is examined.

---

## Start sessions at the repository top level

Start Claude Code from the repository top level. Claude Code loads ordinary project settings and
hooks from the starting directory's `.claude/` folder; it does not search parent directories for
`.claude/settings.json` (verified 2026-08-20 against
`code.claude.com/docs/en/permissions.md`, "Working directories"). Starting in a subdirectory
therefore leaves this baseline's root `.claude/settings.json` permission rules unloaded.

To check a session without touching a protected file, run `/permissions` and confirm that the
expected `Read(...)` and `Edit(...)` deny rules are listed with the repository's project settings as
their source. Run `/status` to confirm that a project settings source is active. Do not test these
rules by asking Claude to read a secret.

---

## The rules

### Allow

| Rule | Why |
|---|---|
| `Bash(./gradlew build)` | Compiling is the loop a team lives in; prompting on every build trains people to stop reading prompts |
| `Bash(./gradlew test)` | Same |
| `Bash(./gradlew run)` | What the pre-deploy simulation stage actually invokes on WPILib 2027. Measured at alpha-7: there is no `simulateJava` task |
| `Bash(./gradlew simulateJava)` | Retained for toolchains that still register that task. On 2027 it grants a task that does not exist, which is harmless; it is NOT what the simulation stage runs |

**All three are bare task forms, and the missing trailing wildcard is the point.** The permissions
page documents `Bash(npm run build)` as matching "the exact command `npm run build`" and
`Bash(npm run test *)` as matching "Bash commands starting with `npm run test`" (verified 2026-08-21
against `code.claude.com/docs/en/permissions.md`). An earlier revision shipped the wildcard form of
all three, which pre-authorised anything appended to the task name — including Gradle's own options,
which is the subject of the ALLOW-side entry under "What these rules do NOT do" below.

**The narrowing is paid for on harmless invocations too.** A build or test invocation carrying any
option or argument after the task name no longer matches the grant. It stops being PRE-APPROVED, and
what happens to a command no rule matched is then a property of the session's permission mode rather
than of this file: the default mode asks, `bypassPermissions`
skips the prompt, and `dontAsk` denies instead of asking (verified 2026-08-21 against
`code.claude.com/docs/en/permissions.md`, "Permission modes").

**"No rule matched" is the load-bearing qualifier, and an earlier revision of this paragraph left it
out.** It said "Nothing here denies those forms", which is false for any appended text containing
`deploy`: `Bash(./gradlew *deploy*)` and `Bash(gradle *deploy*)` ship in the deny list and are
consulted wherever the substring appears, so `./gradlew build deploy` and
`./gradlew build --init-script /tmp/deploy.gradle` are DENIED rather than falling through to the
permission mode. The row for `Bash(./gradlew *deploy*)` in the table below says so in as many words —
the two statements contradicted each other, and this one was the wrong one. Deny is consulted
independently of the grants and wins over them.

A team that meets one of those
prompts often can add its own rule for that exact form — and should write the exact form, not a
trailing wildcard, for the reason above.

## Every deny rule here is yours to lift — here is what each one costs

**None of these rules is permanent, and none of them is enforced from outside your project.** They
live in `.claude/settings.json` in your repository, and the installer writes that file only when it
does not already exist — it never modifies one you already had.

**It does, however, keep checking it. Read this before you lift anything.** When a later run reaches
its settings step and the settings path already exists, the installer leaves that path unchanged.
For an existing regular file on a machine with `jq`, it first checks that the file parses as JSON and
contains exactly one top-level value. Only if those checks succeed does it read the file's
`permissions.deny` array and test every deny string shipped by the template. Remove one from an
otherwise valid file and every later run that reaches that membership test while the string remains
absent reports the settings file unconfirmed; the final status is normally **exit 18, "install
incomplete"**. Restoring the string removes that particular membership failure, but another missing
string or validation failure can still produce exit 18.

Three things bound that report. Without `jq`, the membership test does not run; an existing regular
file is reported unconfirmed for that reason instead. If the earlier baseline-files step has already
recorded exit 20, both warnings print but the final status remains 20 because the first recorded code
wins. And a run that stops earlier with any other non-zero code never reaches this step. The
existing file's `permissions.allow` array and every other key are not examined.

**Five mechanics decide what a lift actually does, and getting them backwards wastes an afternoon.**

- **Rules are evaluated deny, then ask, then allow**, and specificity does not change that order.
- **Removing a deny grants nothing by itself, and it does not mean nothing matches.** The remaining
  rules are evaluated again, in that same order. The shipped denies overlap —
  `Bash(./gradlew *deploy*)` is strictly wider than `Bash(./gradlew deploy*)`, so removing the narrow
  one leaves a direct `./gradlew deploy` denied — and a settings file you already had may carry
  broader deny, ask or allow rules of its own that this document cannot see. Only an operation that
  then matches no rule at all falls to the session's permission mode, and for a command that means:
  the default mode **asks**, `bypassPermissions` runs it, `dontAsk` refuses. So a lift usually buys a
  prompt, not a capability, and sometimes it buys nothing until the overlapping rule is lifted too.
- **If a prompt is what you actually want, say so explicitly** with a `permissions.ask` rule, rather
  than removing a deny and relying on the mode a session happens to be in.
- **Deny wins over allow and is consulted independently of it.** You cannot carve an exception with
  an `allow` entry; to permit a narrower case you must edit or remove the DENY rule itself.
- **A path rule reaches further than its spelling suggests, in two ways.** A bare filename such as
  `build.gradle` or `.env` follows gitignore semantics and matches at any depth, so a rule naming one
  is a rule about every file of that name, not about one file. And a `Read` deny also blocks the Edit
  and Write tools on the same path, including creating a new file there, so lifting a `Read` rule
  lifts more than reading. Both quotations are on this page: under "What depth these six reach" and
  under the version floor.

What each rule denies, and what a lift changes. A lift removes ONE string from `permissions.deny`.
Every remaining rule — the other shipped denies, the five shipped grants, and any rule of your own —
is still evaluated in the deny, ask, allow order above, and only an operation that then matches
nothing falls to the session's permission mode. No row below says what the assistant can do after a
lift, because that is not decidable from this file alone.

| Remove this | What it denied, and what the lift costs |
|---|---|
| `Bash(./gradlew deploy*)`, `Bash(./gradlew *deploy*)`, `Bash(gradle deploy*)`, `Bash(gradle *deploy*)` | A Bash command whose string matches one of these four patterns. They are the only deploy-related control that ships (see "As of v1.0 the hook is WITHDRAWN" below, and `docs/LIMITATIONS.md`, item 1), and `/frc-pre-deploy` reports rather than enforces. Lifting one removes only that pattern; the other three remain consulted. `Bash(./gradlew *deploy*)` is wider than `Bash(./gradlew deploy*)` (mechanics above), so removing only the narrow rule leaves a direct `./gradlew deploy` denied by the wider one. Lifting all four removes every shipped Bash deny whose pattern names `deploy`; all remaining shipped and user rules are still evaluated, and only a command matching none of them falls to the permission mode. While present these rules are a speed bump, not a gate: `docs/LIMITATIONS.md` says so, and item 4 under "What these rules do NOT do" names an invocation whose command string never contained `deploy`. Read that file before lifting, and prefer replacing the family with your team's own task names over deleting it |
| `Edit(build.gradle)` | The `Edit`-form path check on any file of that name at any depth. `./gradlew build` evaluates the project's `build.gradle` (`docs/LIMITATIONS.md`, "What the driver does not contain"), and `build` is granted; in a project whose `build.gradle` carried `build.dependsOn deploy`, `./gradlew build` was measured to deploy. That run has no published record; what it demonstrates is the mechanism `docs/LIMITATIONS.md` records under "What the driver does not contain": the grant is over a command string, and what that string executes is whatever the build file wires. **This rule closes the direct file-edit route to files with that name and nothing else:** `settings.gradle` has no matching shipped deny, and `buildSrc/` has no directory-wide deny, although a nested `buildSrc/build.gradle` still matches this bare-filename rule. A path rule constrains file-tool access rather than a subprocess, so a shell heredoc still writes the file (same section of `docs/LIMITATIONS.md`). Lifting it removes this path-rule check; all remaining rules are still evaluated. The four `./gradlew` grants and the probe-driver grant remain, and when the driver is run it invokes `compileJava` through `./gradlew`, so the project build file executes under that granted driver command regardless of whether this deny is present. If you want the assistant editing the build file, decide about those grants at the same time rather than afterwards |
| `Edit(vendordeps/**)` | The `Edit`-form path check under `vendordeps/`. What this repository establishes about that directory: the schema host records `<project>/vendordeps/` as the project vendordep location and `vendordep --url=<url>` as a Gradle task; `frc-docs-checker` reads the JSONs there for installed library versions and never writes them; the installer writes nothing inside it; and the shipped `CLAUDE.md` tells the assistant never to edit it. What a lift costs depends on what your project's build does with those files, which this repository does not establish, so this row names no consequence in either direction — only the loss of this path-rule check between the assistant's file tools and those files |
| `Edit(gradle/**)`, `Edit(gradlew)`, `Edit(gradlew.bat)` | The `Edit`-form path checks under `gradle/` and on any file named `gradlew` or `gradlew.bat` at any depth. The shipped `CLAUDE.md` tells the assistant never to edit these, and the installer writes nothing inside `gradle/`. What `gradle/**` contains in your project, and what your `gradlew` or `gradlew.bat` loads when it runs, nothing published here establishes: this repository ships no Gradle wrapper and describes none. The installer only warns when `./gradlew` is absent and tells you to create the robot project first, and the permission measurements on this page were made against a stub `gradlew` that echoes its arguments, not against a wrapper that downloads and runs a Gradle distribution ("How the enforcement claims on this page were measured" below). What a lift costs therefore depends on what those files do in your build, and that is yours to check before removing the rule |
| `Edit(.wpilib/**)` | The `Edit`-form path check under `.wpilib/`. The shipped `CLAUDE.md` tells the assistant never to edit it, and the installer writes nothing there. Nothing published here describes the directory's contents beyond this deny. One measured fact about them: a Gradle build in a project that lacked `.wpilib/wpilib_preferences.json`, a file the WPILib VS Code extension generates, failed at configuration time for want of a team number, so that file is read before any task runs, and a build that cannot find it never reaches `compileJava` (measured on a laptop while testing this behaviour; the failing run itself has no published record). What else the directory holds, and what a lift costs, this repository does not establish; it depends on what your toolchain keeps there, and that is yours to check before removing the rule |
| `Edit(.claude/tools/**)` | The `Edit`-form path check on everything under `.claude/tools/`, including the shipped probe script and its Gradle init script. The probe exists so an API question is answered by compiling rather than by recall. The deny is paired with the `Bash(.claude/tools/frc-docs-probe.sh:*)` grant: run the driver, do not rewrite its files (`docs/LIMITATIONS.md`, "keep `Edit(.claude/tools/**)` in `deny`"). Even while present it does not make those files tamper-proof — a path rule constrains file-tool access, not a subprocess, and a Gradle build can write to this path (the driver's own header says so). Lifting it removes this path-rule check; all other rules remain evaluated. If you are debugging the driver, edit it yourself, or lift the rule for that session and put it back. While the string is absent, an installer run that actually performs the membership test reports the settings file unconfirmed and normally finishes with exit 18; the qualifications and earlier-exit precedence are described above |
| `Read(secrets/**)`, `Edit(secrets/**)`, `Read(.env)`, `Read(.env.*)`, `Edit(.env)`, `Edit(.env.*)` | Together these rules deny file-tool reads and modifications on those paths at any depth (measured; see "What depth these six reach" below). A `Read` deny also blocks the Edit and Write tools on the same path, while NotebookEdit is not covered by `Read` (see the version floor). Each `Read` pattern here has a corresponding `Edit` pattern, so removing only one member of a pair does not establish that modification is permitted: the remaining rule is still evaluated. The gitignore fragment contains the corresponding broad ignore patterns but deliberately unignores `.env.example`; the permission deny has no such exception, because `.env.*` also names `.env.example`. If you want the assistant to read that one file, replace `Read(.env.*)` with the variants you actually keep secret rather than adding an allow, because deny is evaluated first and an allow cannot carve an exception out of it. What these six do not reach, present or lifted, is the Bash lane: a path rule constrains the file tools and not a subprocess, so a shell command reading the same path is outside what these rules check, and the shipped `CLAUDE.md` carries that prohibition as instruction text instead. Lifting all six removes these six shipped path checks; any overlapping shipped or user rule remains evaluated, the instruction text remains, and no PreToolUse, blocking, or deploy-gate hook ships |

**Nothing here needs to be lifted for the shipped workflow.** No command, skill or agent in this
baseline edits a build file or reads a secret, and nothing in it rewrites `.claude/tools/` — the
installer puts the two driver files there once, if absent, and never rewrites them. If you find yourself lifting a rule to make something in this toolkit work,
that is a defect worth reporting rather than a configuration step.

**A bare grant is not an exact-string guarantee, and this is the part that is easy to get wrong.**
Claude Code strips a fixed set of wrappers BEFORE it matches a Bash rule, so a wrapped invocation can
match a grant that the unwrapped string alone would describe as exact. Verbatim from that page: "Before
matching Bash rules, Claude Code strips a fixed set of wrappers, so a rule like `Bash(npm test *)`
also matches `timeout 30 npm test`." The stripping is built in and not configurable. So the bare
grants above pre-approve more than their literal command strings, and no wording in this file
should be read as saying otherwise. What the narrowing removed is the pre-approval of arguments
appended to the TASK NAME, which is where the `--init-script` privilege lived; it did not turn the
grant into a literal string comparison.

**There is deliberately no `Bash(git ...)` grant.** Claude Code maintains a built-in set of Bash
commands it treats as read-only and runs without a permission prompt in every mode; read-only forms
of `git` are in that set, and the set is not configurable (verified 2026-08-17 against
`code.claude.com/docs/en/permissions.md`). So for the read-only forms of the commands an earlier
revision granted here — `git status`, `git diff`, `git log` — a grant is not what lets them run.
What a trailing-wildcard grant did add was pre-authorization for argument forms outside that
built-in set, and those include forms that are not reads: `git diff --output=<file>` writes a file,
and `--ext-diff` allows an external diff helper to be executed (git-scm.com/docs/git-diff, verified
2026-08-17). The grants were removed rather than narrowed: a list of permitted flags would be an
enumeration, and this file refuses those elsewhere for the same reason. The cost: a `git` form the
built-in set does not recognise may prompt, and that prompt is the behaviour this template chooses.

**There is deliberately no `Bash(./gradlew *)` grant.** Deny rules are evaluated before allow
rules regardless of which one is more specific (verified 2026-08-21 against
`code.claude.com/docs/en/permissions.md`: "Rules are evaluated in order: deny, then ask, then
allow... rule specificity doesn't change the order"), so a bare-prefix allow here would NOT silently
undo the deploy denies below — a matching deploy deny still blocks a command that a bare-prefix allow
also matches. What a bare-prefix grant would actually do is pre-authorise, with no prompt at all,
every OTHER gradle invocation that does not happen to match one of the four pinned deny strings —
including the abbreviated deploy spelling already disclosed under "What these rules do NOT do" below
(`./gradlew depl` matches no deny string today, and currently falls through to a prompt; a bare-prefix
allow would let it run with none). Grant per task, never per tool.

**No trailing wildcard appears in the allow list, in either spelling.** `Bash(./gradlew build *)` and
`Bash(./gradlew build:*)` match identically, so dropping the wildcard drops both spellings at once.
Where a team adds a trailing-wildcard rule of its own, the space form is the one to write: the
product writes that form when a user selects "don't ask again", and `:*` is only recognised at the
end of a pattern — in `Bash(git:* push)` the colon is a literal and never matches (verified
2026-08-21 against `code.claude.com/docs/en/permissions.md`).

### Deny

| Rule | Why |
|---|---|
| `Bash(./gradlew deploy*)` | **No space before the wildcard, on purpose.** `deploy *` would require a space after `deploy` and so would miss any task whose name merely BEGINS with `deploy`; the no-space form matches `deploy`, `deployStandalone`, and a target-derived `deploy<Target>` should a build register one — when the task is spelled out in full. Those first two are what the alpha-6 fixture actually lists; no target-derived name has been observed, and the schema host records whether a generated project creates one as not established. The wildcard is what covers the unobserved case, which is the point of using one. Gradle also accepts abbreviations these strings never see: item 4 under "What these rules do NOT do" |
| `Bash(./gradlew *deploy*)` | **Closes the multi-task hole the rule above cannot reach.** Gradle accepts several tasks in one invocation, and the rule above only matches when `deploy` is the first token after `./gradlew ` — so `./gradlew build deploy` and `./gradlew test deploy` matched the `build`/`test` grants and ran. Measured against Claude Code 2.1.229: a wildcard on both sides is consulted wherever the substring appears, including after another task name. It is strictly wider than the rule above and does not replace it — that one is pinned below, and both ship |
| `Bash(gradle deploy*)` | The same family invoked without the wrapper |
| `Bash(gradle *deploy*)` | The same multi-task hole on the unwrapped form. Added with the rule above rather than after it: leaving one side fixed and the other open is the asymmetry a reader of this table would most reasonably assume was deliberate |
| `Edit(vendordeps/**)` | Vendor dependency JSONs are managed by the vendordep tooling. The moment the baseline edits one, every toolchain upgrade becomes a merge conflict the team blames the baseline for |
| `Edit(.wpilib/**)`, `Edit(gradle/**)`, `Edit(gradlew)`, `Edit(gradlew.bat)` | Same reasoning: the generated project skeleton is not the baseline's to write |
| `Edit(build.gradle)` | Same reasoning, plus one the others do not carry: `build.gradle` decides what `./gradlew build` does, and that command is granted. See the section above for the bypass this closes and how to lift the rule |
| `Edit(.claude/tools/**)` | The probe driver lives here. It exists so an API question is answered by compiling rather than by recall, and an assistant that can edit it can edit away the thing that makes its answer evidence. Paired with the `Bash(.claude/tools/frc-docs-probe.sh:*)` grant: run it, do not rewrite it |
| `Edit(.claude/skills/frc-pre-deploy/scripts/**)` | The validation runner lives here. It computes the verdict a human reads before enabling a robot, and an assistant that can edit the check can make the check pass. Added 2026-09-08: until then only `Edit(.claude/tools/**)` existed, and the student guide claimed a protection the template did not have |
| `Read(secrets/**)`, `Edit(secrets/**)` | Paired with the gitignore fragment: the ignore rule and the deny rule ship together and name the same path, so the place a key must not live is also the place these rules tell the tools not to go. What the deny actually reaches is narrower than it reads — see the Bash-lane note under "What these rules do NOT do" below |
| `Read(.env)`, `Read(.env.*)`, `Edit(.env)`, `Edit(.env.*)` | Same. **Also covers `.env.example`**, even though the gitignore fragment carves it out so a team can commit it: deny rules are evaluated before allow rules and a broader deny always wins over a narrower allow, so no allow rule could relieve this one for that one path (verified 2026-08-15 against `code.claude.com/docs/en/permissions.md`: "a deny rule can't carry allowlist exceptions"). The model can help a team decide what `.env.example` should contain; a human has to write the file itself. |

**What depth these six reach.** `secrets/**` is a single directory segment and `.env` / `.env.*` are
bare filenames, and the permissions page treats both shapes as reaching any depth in a DENY rule: as
a deny or ask rule `Read(secrets/**)` "matches a directory named `secrets` at any depth under the
current directory, so the rule also applies to nested copies", and "bare filenames follow gitignore
semantics and match at any depth, so `Read(.env)` and `Read(**/.env)` are equivalent" (verified
2026-08-21 against `code.claude.com/docs/en/permissions.md`). Measured against Claude Code 2.1.239 in
a scratch repository whose only settings were this template: reads of `sub/.env`,
`sub/.env.production` and `sub/secrets/key` were each refused, and a read of `sub/notes.txt` in the
same repository succeeded — so the refusals were these rules matching at depth and not a blanket
refusal. That is the depth question only. It says nothing about the Bash lane, which is the next
section, and the same shapes in an ALLOW rule would not reach that far.

There is no `Write(...)` rule here because a path rule written for `Write` is accepted but never
consulted: file permission checks consult `Edit(path)` and `Read(path)` rules only, and from
v2.1.228 — the floor above — a `Read` deny rule also covers the Write tool.

---

## The one hook: the session-start update check

The template's `hooks` block runs `.claude/tools/frc-version-check.sh` when a session starts, resumes,
or is forked. It compares the version in `.claude/frc-baseline-manifest.yml` with the latest GitHub
Release of the toolkit and, when a newer one exists, shows the student a one-line warning and asks
the assistant to repeat it; a release titled with `[security]` says to pause and ask a mentor to
update first. Each session start makes at most one request with a three-second timeout, and successful
and failed results are cached per user for 24 hours when the cache can be written. The check stays
silent when offline, writes nothing inside the project, and blocks nothing.

- **To turn it off** for a user or a session: set `FRC_TOOLKIT_NO_UPDATE_CHECK=1`.
- **To remove it:** delete the `hooks` block. Nothing else depends on it.
- **An existing `settings.json`** is never modified by the installer, so a team that already had one
  does not get this hook automatically. The install says so; copy the `hooks` block from the template
  if you want it.

## What these rules do NOT do

**A deny rule cannot be a deploy gate, and this is not a caveat — it is the reason the withdrawn
design put enforcement in a hook rather than in these rules. v1.0 ships no gate. Its one hook is the
session-start update check, which reports and blocks nothing.**

Deny rules match command **strings**, not effects. Behaviours that defeat a string-matched deny
include:

1. **Environment runners are not stripped before matching.** `npx`, `docker exec`, `devbox run`,
   `mise exec`, and `direnv exec` are absent from the built-in wrapper list, so a rule whose prefix is
   a runner authorises whatever follows it.
2. **Exec wrappers are not covered by a prefix rule** — `watch`, `setsid`, `ionice`, `flock`, and
   `find` with `-exec`.
3. **Aliases and scripts change the string without changing the effect.**
4. **Gradle's own task-name abbreviation.** Gradle accepts an unambiguous abbreviation of a task
   name — documented Gradle behaviour, not a permissions quirk — so the string a deny rule sees
   need never contain the full name: `./gradlew depl` never contains `deploy`, so no deny string in
   this template ever sees it. **What happens next depends on the allow list, and this file has
   said two different things about it — this is the correct one.** The no-prompt outcome was
   measured when the template carried a bare-prefix allow (`Bash(./gradlew build *)`), which has
   since been removed; see the note above at "No trailing wildcard appears in the allow list". Under
   the template as shipped, whose allows are exact strings, `./gradlew depl` matches no allow and no
   deny and falls through to whatever the session's permission mode does — a prompt, on the default
   mode. The deny is doing no work either way, which is the point. Do not try to close this with
   more deny strings. `dep*` would deny
   `dependencies` and `dependencyInsight`, and each shorter pin denies more of what a team
   legitimately runs. It is a named, open hole, and one more reason these rules are a speed bump.

**The three ALLOW rules are bare task forms. That removes the appended-option privilege; it does not
make `./gradlew build` a safe operation.** Until 2026-08-21 the three were written with a trailing
wildcard, and that was not a deny-side hole — it was the grant itself. Gradle accepts its own options
after a task name, not only before it
(`docs.gradle.org/current/userguide/command_line_interface.html`, verified 2026-08-21: "Options are
allowed before and after task names"). `--init-script <path>` (short form `-I`) is one such option:
Gradle runs the named script during initialization, before any project build script is evaluated, and
an init script can configure the whole build
(`docs.gradle.org/current/userguide/init_scripts.html`, verified 2026-08-21). So
`./gradlew build --init-script /tmp/x.gradle` matched the wildcard `build` grant, matched none of the
four deploy denies — there was nothing for a deny rule to defeat — and ran the named script's Groovy
or Kotlin with no prompt. The bare form does not match that string, or any other string with anything
appended to the task name.

Four things that narrowing does **not** do:

1. **It does not stop the command running.** It removes a pre-approval and nothing else. What then
   happens to an unmatched command belongs to the session's permission mode, not to this file: the
   default mode asks, and an approved prompt executes exactly as before; `bypassPermissions` runs it
   without asking; `dontAsk` denies it. Removing a grant is therefore not equivalent to adding a
   deny, and in one mode it is not even equivalent to adding a prompt.
2. **`./gradlew build` still runs code that is already there.** A Gradle build evaluates the
   project's own `build.gradle` and `settings.gradle`, and Gradle also discovers and runs init
   scripts from `$GRADLE_USER_HOME` and from `$GRADLE_HOME/init.d/` with none of them named on the
   command line (`docs.gradle.org/current/userguide/init_scripts.html`, verified 2026-08-21:
   "Init scripts are discovered and executed in this order"). The grant is over a command STRING;
   what that string then executes is whatever the checkout and the machine already hold.
3. **It denies no option, and it enumerates none.** No option name appears anywhere in the settings
   template. The narrowing works by granting less, which is the only reason it needs no list — item
   4 above is still not closable by adding more strings, and neither would this be.
4. **It changes nothing on the deny side.** The four defeats listed above stand exactly as written.

So the three allow rules remain grants, not guarantees, the same as the deny rules below — see
"Permissions allow; hooks enforce" at the end of this section.

**Do not rely on path permission rules as an OS-level boundary.** Do not use shell commands or
subprocesses to read or write the denied paths.

**How the enforcement claims on this page were measured, and their limit.** Which commands are
allowed and which are denied was measured with `claude -p` (**headless**) against Claude Code
2.1.229, using a stub `gradlew` that echoes its arguments. In that mode a control run carrying **no
permission rules at all** still executed `./gradlew build` — so headless, the **allow** list is not
what stops an unlisted command; only **deny** is observed to have effect. What an interactive session
shows a student — a prompt, a silent allow, or something else — **has not been re-probed**. Read the
allow/deny behaviour described here as headless-verified and interactive-unconfirmed. (This scopes
the enforcement measurements only. Other claims on this page are interactive by nature and rest on
other evidence — the version floor on a startup warning, and the space-form rule on what the product
writes when a user selects "don't ask again".)

So the deny rules above are the belt, and nothing shipped is the braces.

**As of v1.0 the deploy-gate hook is WITHDRAWN and there is no gate** — so these deny rules are the
only deploy-related control that ships, and they are a **speed bump, not a guarantee**. Do not
describe them as one. Why the gate was withdrawn rather than weakened is recorded in
`docs/LIMITATIONS.md`.

**Permissions allow; hooks enforce.** Any property that must be *guaranteed* rather than *declared*
belongs in a hook, a deny rule that is genuinely sufficient, or a subagent — never in an
`allowed-tools` line.

---

## The settings-template source pin

Before it writes any project file, the installer compares the complete `settings.json.template`
bytes with this release's pinned SHA-256 value. That single digest covers the four deny strings
shown in the table above — `Bash(./gradlew deploy*)`, `Bash(./gradlew *deploy*)`,
`Bash(gradle deploy*)`, and `Bash(gradle *deploy*)` — without maintaining a second rule list. An
update that changes the template's SHA-256 digest requires the installer pin to change too. A
mismatch stops the run with source-failure exit 14 before the template or any other project file is
written.

This source pin establishes only that the complete shipped template has the pinned SHA-256 digest.
It does not run Claude Code or Gradle, prove that the rules prevent every deploy spelling, or
verify a corresponding changelog entry. The wide forms remain important because they cover the
measured multi-task spelling `./gradlew build deploy`; the limitations in “What these rules do NOT
do” still apply.

---

## No model identifier

The template names no model. A team that upgrades its session model should not have to edit a settings
file, and no file here should name a model that can retire underneath a team mid-season.
