---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see ../../../COMMERCIAL-LICENSE.md
name: frc-behavior-first
description: Use before writing code for any robot mechanism — state the observable behavior, its limits, and how you will know it worked, and get that agreed before writing it. Use when accepting code that already exists — restate what it actually does, compare it with the agreed behavior, and say when no agreed behavior exists.
---

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

<!-- FRC-BEHAVIOR-FIRST-BEGIN -->
## Behavior first

Before writing code for a mechanism, state in one or two sentences what it should **do** — the
observable behavior, its limits, and how you will know it worked. Get that agreed before writing
the implementation.

When a request is ambiguous about behavior, ask rather than choosing. After writing code, or before
accepting code that already exists, restate the behavior it actually implements and name any way it
differs from the agreed behavior. If no behavior was agreed, say so instead of inventing one.

This applies to generated code and to human-written code equally.
<!-- FRC-BEHAVIOR-FIRST-END -->

---

## Why this skill and the root CLAUDE.md block should read the same

They are **one discipline, not two similar ones.** In the baseline source release, the block above
also appears between the same markers in `baseline/templates/CLAUDE.md.template`; that template is
source-only and is not installed in a team project. The two source copies are maintained by hand.
Do not infer that they match from a repository check's name or PASS label. Establish equality only
after finding exactly one properly ordered pair of exact marker lines in each readable regular file,
writing the bytes between them to ordinary files, confirming both bodies are nonempty, and receiving
exit 0 from `cmp`. If any of those operations does not complete, equality was not established; only
a completed `cmp` that returns 1 establishes a byte difference.

The installed local counterpart is the marked block in the project's root `CLAUDE.md`. Where that
file does not exist, the installer renders it from the source template. Where it already exists, the
installer leaves it unchanged and extracts each block to ordinary files. A source-template
extraction that does not complete stops the run at exit 14; a project-file extraction that does not
complete is recorded as unconfirmed and ends at exit 20. Only successful extractions reach the
nonempty-template check and `cmp`; a difference or comparison error is also recorded as unconfirmed
and ends at exit 20. After installation, nothing this baseline installs continuously re-checks the
two local copies, so a later local edit can make them drift.

Where the project's root `CLAUDE.md` carries the block, Claude Code loads that file into context at
the start of every session, subject to settings that can exclude a `CLAUDE.md` from loading — Claude
Code's `claudeMdExcludes` among them (Claude Code memory documentation,
https://code.claude.com/docs/en/memory, checked 2026-08-22). Invoke this skill when a mechanism is
being designed or existing mechanism code is being accepted. If the local copies read differently,
say so and treat neither as authoritative until the difference is resolved.

This installed skill names no verified public source or issue-tracker location. When the installer
creates the root `CLAUDE.md`, its first line receives `HEAD` only when the baseline source directory
is itself the top level of that Git worktree. For an existing root file, installer success means the
first line had the template's structure, current baseline version and current source-ref value; its
four-digit–two-digit–two-digit install-date text was accepted as existing text. That check confirms
the text, not who wrote it. The ref names the local source checkout's `HEAD` only; it does not record
uncommitted source bytes or establish that the ref was published or is retrievable elsewhere.

If the team can identify and obtain the exact baseline source used for installation, compare both
local copies against its template. Otherwise, report the installed file paths and baseline version.
Report the complete source-ref field from the root `CLAUDE.md` only if the installer confirmed its
first-line header; if it did not, say that the source ref is unconfirmed. In either case, say that the
exact source is unavailable, and do not guess which local copy diverged. A difference already present
in an obtained source release is a baseline defect to report to whoever supplied it. A later
difference confined to the project's root `CLAUDE.md` is local, and editing only one local copy does
not reach the other.
