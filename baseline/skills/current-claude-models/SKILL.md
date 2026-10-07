---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see ../../../COMMERCIAL-LICENSE.md
name: current-claude-models
description: Use when choosing a model or an effort level for robot-code work, when any answer would name a Claude model, or before pinning a model anywhere — this is the single source of truth for Claude model identifiers, effort levels, and retirement dates, and no other artifact in this baseline may name a model.
---

# current-claude-models

**Last verified: 2026-10-06**

**Verified against**, by live fetch of the raw Markdown on that date:
- `https://platform.claude.com/docs/en/about-claude/models/overview.md` — identifiers, context
  windows, max output, knowledge cutoffs, adaptive thinking
- `https://platform.claude.com/docs/en/about-claude/model-deprecations.md` — model status and
  retirement dates
- `https://code.claude.com/docs/en/model-config.md` — effort levels, defaults, aliases

This is a **data artifact**, the sibling of `current-wpilib-2027` and deliberately on its own clock.
It holds volatile Claude facts — the model data, the role map, the effort levels — together with the
procedure for keeping them current. **No fact here came from model memory.** If you find one that
did, that is a defect: report it rather than correcting it from recollection.

**This file names paths in the baseline's SOURCE repository, and most of them are not written into
your project.** Everything the installer writes comes out of `baseline/`. Re-measured 2026-08-28
against an empty project: the run left `.claude/**`, a `CLAUDE.md`, a `.gitignore`, and a
`COMMERCIAL-LICENSE.md` at the project root, and no other file in your project. **The licence is
the one an earlier version of this passage omitted**, and it is the write that makes this file's own
line-2 pointer (`../../../COMMERCIAL-LICENSE.md`) resolve in an installed project — so that pointer
is the exception the old wording denied: the sentence depended on a control it did not mention.
The same goes for every `CI-nn` check named below — those run where this baseline is maintained, not
on your machine.

**Repository-only paths are not audit evidence on a team machine.** CI-24's residual is therefore
stated in full below without requiring access to its repository record. Claude Code product-surface
facts use the public vendor sources linked in the ownership row; this installed file claims no
clearance from maintainer-side probe records that it does not reproduce.

---

## The rule this file exists to serve

**No artifact in this baseline may name a model — except this one, which exists to hold the names.**
Not a command, not a skill, not a subagent, not `settings.json`, not your `CLAUDE.md`. An artifact
inherits whatever model the session is running, expresses "this is cheap and repetitive" as a
**task class**, and expresses "think harder about this" as an **effort level**.

**Why, concretely.** A model identifier written into a checked-in team file eventually names a
retired model. The session then fails, mid-season, for **everyone on the team at once** — and the
file that broke it was installed by us, not chosen by them. `CI-24` scans for this in the
baseline's own source repository; the baseline installer does not install that check in your
project. It matches *shapes* rather than a list of today's names, so a model family that does not
exist yet can still be caught: two of its detectors look for a model's NAME, and a third looks for
the `model` selection setting — the frontmatter or settings key, and the `--model` flag — because
the shape that actually overrides a session carries no name a name-detector can see. `model: opus`
is an alias, and it passed both name-detectors until the selection detector was added on
2026-08-22.

**Its residual is written out here rather than pointed at, and it did not go away.** Each detector
matches only the syntax it describes; an artifact can name or select a model through syntax outside
those shapes and pass. The omitted shapes and product surfaces are deliberately not listed: no such
list would stay complete, and writing one would falsely make the residual look bounded.

The selection detector recognizes a `model` key at the **start of a line** or a `--model` argument,
with a value beginning with a letter or digit either unquoted or after an opening single or double
quote. That line anchor is what keeps ordinary prose out of the results. The complete scalar or
command-line argument `inherit` or `default`, in any of those quote forms, is excluded because each
means no model override; a longer provider-defined value beginning with either word is still
matched. A closing shell quote is not an argument boundary: suffix text concatenated immediately
after it remains visible.

**A green run means the enumerated shapes were not found — never that no artifact names a model**,
and the check prints that on every green run rather than leaving it to be remembered. Maintain the
rule through writing and review; the check catches shapes, and a rule is not a shape.

This file is the one place a model may be named. It is written for a **human** choosing `/model`
and `/effort`, and it gives the suite somewhere to put these facts that is not forty separate files.
It is installed as an ordinary skill and its frontmatter restricts nothing about who loads it, so do
not read "written for a human" as a promise that a session never sees it.

---

## What this file owns

**Every fact in this file that moves when Anthropic ships, changes or retires a model** — the model
table, the role map, the effort-level names and defaults, the aliases and the retirement dates all
sit inside that test. **The test is the boundary, not the examples after the dash:** a fact this
file carries that moves with a model release is owned here even where no phrase above happens to
name it, which is what a list would get wrong the first time a column is added. Re-read all of it
at every refresh.

## What it does NOT own, and who does

| Fact class | Owner |
|---|---|
| WPILib packages, classes, Gradle tasks, vendordep paths | **`current-wpilib-2027`** — the WPILib schema host, in this baseline |
| Claude Code product surface: frontmatter keys, hook event names, permission modes, tool tokens | **Anthropic's live product documentation, not a host.** Re-fetch `https://code.claude.com/docs/en/skills.md` for skill and command frontmatter, `https://code.claude.com/docs/en/hooks.md` for hook events, and `https://code.claude.com/docs/en/permissions.md` for permission modes and tool rules before relying on those facts. These are direct vendor sources a team can open; this installed skill does not claim that an unreproduced maintainer-side probe cleared them. A host would give the *feeling* of currency here without the protection: if the product renames a hook event, your config breaks regardless of what any file records |
| Pricing, monetary figures, plan names, seat tiers, per-plan billing coverage | **Nobody, deliberately — out of scope for this baseline.** This is an owner decision, not an omission. This suite is installed by volunteer teams under many different arrangements, and a price or a plan name written here would be wrong for most of them and stale for the rest. Ask whoever pays for the account |
| Game vocabulary, field dimensions | **Nothing yet** — the season overlay is the designed owner and does not exist today |
| Team numbers, CAN IDs, subsystem names | Your team's own `CLAUDE.md` |

**A fact class that every host disclaims and nobody owns is a hole.** The row above that says
"nobody" says so on purpose and names the reason, which is what makes it a decision you can argue
with rather than a gap nobody noticed.

---

## The role map

**The vocabulary is closed. These three roles are the only ones defined.** An artifact that needs to
name a role uses one of these; a role that is not here does not exist, and inventing a fourth in a
consumer quietly reintroduces the unmapped reference this file exists to remove.

| Role | The job it names | Fills it today |
|---|---|---|
| `default-session` | Everything a team does day to day: writing subsystems, reading errors, explaining code | **Claude Opus 5.5** (`claude-opus-5-5`) |
| `mechanical-verifier` | Repetitive checking with a clear right answer — comparing a list, confirming a name, running a fixed procedure | **Claude Sonnet 5.5** (`claude-sonnet-5-5`) |
| `deeper-reasoning` | A genuinely hard problem: an intermittent fault nobody can reproduce, a control loop that will not settle | **Claude Opus 5.5 at a higher effort level** — see below. Reach for effort before reaching for a different model |

**Correcting a role here corrects it everywhere.** That is the whole point, and a consumer that
copies an identifier out of this table instead of citing the role has broken it.

---

## Current models

Verified 2026-10-06 against the pages cited at the top of this file. **No pricing appears here by
design** — see the not-owned table.

| Model | Identifier | Context | Max output | Reliable knowledge cutoff | Adaptive thinking |
|---|---|---|---|---|---|
| **Claude Opus 5.5** | `claude-opus-5-5` | 1M tokens | 128k tokens | **Jun 2026** | Yes (always on) |
| **Claude Sonnet 5.5** | `claude-sonnet-5-5` | 1M tokens | 128k tokens | **Jun 2026** | Yes |
| **Claude Fable 5.1** | `claude-fable-5-1` | 1M tokens | 128k tokens | **Jun 2026** | Yes (always on) |
| **Claude Haiku 4.5** | `claude-haiku-4-5-20251001` (alias `claude-haiku-4-5`) | 200k tokens | 64k tokens | Feb 2025 | No |

**This table is a selection, not the lineup.** It carries the four models that the overview page
cited at the top of this file features in its own current-models table. The deprecations page cited
there lists further models whose state is **Active** and which do not appear above. A model missing
from this table has not been assessed and rejected, and is not thereby retired: consult the
deprecations page before concluding anything about a model you do not see here. (All THREE sources listed at the top of this file — the models overview, the deprecations page and
the Claude Code model-config page — were re-fetched on **2026-10-06**, and every
row above was re-read against them. That re-reading is why the stamp at the top of this file moved;
it did not move because the date looked old. **Claude Opus 5.5 and Claude Sonnet 5.5 replaced Claude
Opus 5 and Claude Sonnet 5 on the current table in that pass**: the overview now lists the earlier
models under *Legacy models (still available)*. Both remain **Active** on the deprecations page and
are not retired.)

**This table is Claude API data, and that is the scope it carries.** The identifiers are the Claude
API model IDs. `Max output` is the ceiling the overview page cited above states for the synchronous
Messages API — that page records a higher one on another API surface. And `Context` is the window on
the Claude API, not a promise about your session: what a Claude Code session actually gets can be
smaller, because the plan, the deployment and the environment settings all bear on it, and no list
written here would stay complete. Before you plan a session around one of these numbers, read the
Claude Code `model-config` page cited at the top of this file for the surface you are on.

The overview's stated starting point is *"start with Claude Opus 5.5 for most workloads."* It describes
Claude Fable 5.1 as *"for demanding reasoning and long-horizon agentic work"* and directs a reader to
it *"when your evals on Claude Opus 5.5 at higher effort still fall short."* Claude Fable 5.1 is not the
default model on any account type the model-config page lists; a session uses it only when someone selects it.

**Every Claude model ID is a pinned snapshot, never a moving "latest" pointer** — including the
dateless ones like `claude-opus-5-5`. An alias such as `opus` *is* a moving pointer, and what it
resolves to depends on the provider. On the Anthropic API, `opus` → Opus 5.5 and `sonnet` → Sonnet 5.5.

---

## Retirement dates — read this before you pin anything for a season

For an Active model, the *retirement floor* is the earliest date it could stop working, and it is a lower
bound rather than an outage date: the deprecations page cited at the top of this file publishes it as
a **tentative** retirement date given as "not sooner than" the date shown, so the real retirement can
land later. A Deprecated model shows a deprecation date and either a plain tentative retirement date
or "To be announced". What is not tentative is what happens at the end — once a model is retired, requests to
it **fail**; they do not silently downgrade. That page also scopes these dates to Anthropic-operated
platforms; a model reached through any other provider is on that provider's own schedule, which this
file does not record — check the provider before pinning.

| Model | State | Retirement (Active: not sooner than; Deprecated: tentative date) |
|---|---|---|
| `claude-opus-5-5` | Active | **September 22, 2027** |
| `claude-sonnet-5-5` | Active | **September 28, 2027** |
| `claude-opus-5` | Active | **July 24, 2027** |
| `claude-sonnet-5` | Active | **June 30, 2027** |
| `claude-fable-5-1` | Active | **September 1, 2027** |
| `claude-fable-5` | Active | **June 9, 2027** |
| `claude-sonnet-4-5-20250929` | **Deprecated** (deprecated September 30, 2026) | **November 30, 2026** (tentative) |
| `claude-haiku-4-5-20251001` | Active | **October 15, 2026** |

**This table is a selection, not the lineup** — the full set of active models and floors is the
deprecations page cited at the top of this file. A model absent from this table has not been checked
against the season: consult the page before pinning anything. (The dates above were re-checked on **2026-10-06** against the deprecations page, and previously
against the page on 2026-08-15, 2026-08-22 and 2026-09-04.)

> ### The one that matters for a build season
>
> **A currently-active model can have a retirement floor that falls before a 2027 competition
> season even begins, and a deprecated one is already scheduled to go.** In the table above that is
> true of Haiku 4.5 (Active, October 15, 2026) and Sonnet 4.5 (already Deprecated, retiring
> November 30, 2026) — and the table is a selection, so check the deprecations page,
> not this paragraph, for whatever you are about to pin. A team that pins such a model in the
> autumn is pinning something that may already be gone by kickoff, and the failure arrives as a
> hard error in the middle of build season.
>
> *Corrected 2026-08-15.* This callout previously opened with a count — "two currently-active
> models" — that is false against the deprecations page as fetched 2026-08-15, which shows more
> than two active models with floors before or inside a 2027 season. Whether the count was true
> when written was not established and does not matter: a count here goes stale the moment the
> lineup moves, so the correction removes the enumeration rather than updating it.
>
> **The three roles above all resolve to models whose floors sit past a spring 2027 championship.**
> That is not an accident and it is the reason to use a role rather than a name.
>
> This file does not own the season calendar — that class belongs to the season overlay, which does
> not exist yet. Compare these dates against your actual season dates rather than against the
> assumption embedded in this paragraph.

The dates move. An Active model's date is a floor, not a promise, and Anthropic publishes them on the deprecations page
cited at the top of this file.

---

## Effort levels

Effort controls how much the model reasons before answering. **It is the right lever for "think
harder about this" — reach for it before reaching for a different model.**

| Level | Use it for |
|---|---|
| `low` | Trivial mechanical edits |
| `medium` | Routine work with a clear shape |
| `high` | Substantial code, anything touching the robot. In Claude Code the default on every model that supports effort except Opus 5.5 and Sonnet 5.5 (`medium`) and Opus 4.7 (`xhigh`), and except where an organization sets its own default; the Claude API's own default is stated on the overview page |
| `xhigh` | A hard problem that `high` has already failed on |
| `max` | The deepest reasoning available |

Verified 2026-10-06 against `model-config.md` — re-fetched, with every bullet in this block re-read
against that fetch:

- Fable 5.1, Fable 5, Opus 5.5, Sonnet 5.5, Opus 5, Sonnet 5, Opus 4.8 and Opus 4.7 support `low`,
  `medium`, `high`, `xhigh`, `max`.
- Verbatim: *"`high` on every model that supports effort, except that Opus 5.5 and Sonnet 5.5 default
  to `medium`, Opus 4.7 defaults to `xhigh`, and, when your organization sets a default effort level
  for its organization default model, that level is the default when you run that model."* So the
  default model on most account types, Opus 5.5, starts at `medium`, and you have to set effort *up* for harder work.
  Switching to Sonnet 5.5 for a cheap mechanical task still starts at `medium`, not `high`.
- Set a level a model does not support and Claude Code falls back to the highest supported level at
  or below it, rather than erroring.
- **`ultracode` is not an effort level.** Verbatim: *"Ultracode is a Claude Code setting rather than a
  model effort level: with it on, Claude orchestrates dynamic workflows for substantive tasks, at
  whichever effort level the session runs at."* Do not treat it as "one step above max".

> *Corrected 2026-08-15.* The default-effort bullet previously read "The default is `high` on every
> model that supports effort", dropping the source's Opus 4.7 exception — a sourced sentence turned
> into a false universal by elision. The ultracode bullet had also drifted from its source ("orchestrate
> work across agents" for "orchestrate dynamic workflows for substantive tasks"). Both now carry the
> source sentences verbatim. Both bullets were re-read and re-quoted from a 2026-10-06 fetch.

---

## Consumers

**None yet.** No artifact in this baseline currently cites a role from this file, and that is the
correct state: every artifact complies with the no-model rule by naming nothing at all, which is
stronger than citing a role.

**The contract, for the first artifact that does need one.** It carries the literal body line
`Upstream: current-claude-models` — a *different* string from the WPILib host's, so an artifact
depending on both carries **both** lines — and it appears in the list below. CI-10 runs in the
baseline's own source repository; the baseline installer does not install it in a team project.
It scans for the undeclared consumer: an artifact carrying the line without appearing below. It
scans best-effort: it matches a declaring artifact's name by substring against the backticked tokens
of this section, so a name that happens to sit inside another token passes without a bullet of its
own, and a green run is corroboration, not proof. It does **not** see the reverse defect at all — a
stale entry below for an artifact that no longer declares — because an entry declared ahead of its
artifact is legitimate by design, and a stale entry looks exactly like a plan. Neither direction,
then, is proven by CI; both are held by reading. The WPILib host carried two withdrawn artifacts in
its list with CI green, on exactly this blind spot.

<!-- CONSUMERS-BEGIN -->
<!-- One `- \`name\`` bullet per consuming artifact. Empty is a valid state and is checked as one. -->
<!-- CONSUMERS-END -->

---

## Absorbing a model release

**A model release is absorbed by editing this file and nothing else.** If any other artifact needs an
edit when a model ships, that artifact restated something it should have cited, and that is the
defect — not this file.

1. Re-fetch the three raw-Markdown sources listed at the top. **Fetch them; do not answer from
   recollection, and do not trust a summary of them.**
2. Update the tables. Move the stamp **only because you re-read the tables**, never because the date
   looked old.
3. Check whether any role should now resolve to a different model. Changing a role's target is a
   one-cell edit here and no edit anywhere else.
4. Re-check the retirement floors against the coming season.

**In the baseline source repository, CI applies a 30-day staleness threshold to this file's `Last
verified` stamp rather than the default 90-day threshold.** Model facts move faster than anything
else this suite touches. The installer does not install that check or its register in a team
project. When source-repository CI runs with a stamp older than its threshold, it warns on a pull
request and fails at a release tag.

*Corrected 2026-08-15: this paragraph previously asserted the lineup had "changed three times in the
six weeks before this file was written" — a count derivable from none of the three sources this file
cites, in a file that says no fact here came from model memory. Removed rather than sourced; the
30-day clock stands on the owner's judgement, which needs no statistic.*
