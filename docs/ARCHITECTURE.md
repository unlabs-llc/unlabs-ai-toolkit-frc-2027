<!-- Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md -->

Suite architecture
==================

**Last verified: 2026-09-03**

What the pieces are, where they sit, what an update may touch, and — the part that is usually left
out — what this design **cannot** guarantee.

---

The three layers
----------------

| Layer | Owns | Changes when |
| --- | --- | --- |
| **Toolkit** | Everything in this repository. Skills, subagents, templates, the scaffold. Byte-identical on every installing team's machine at a given version | a baseline release |
| **Season overlay** | Game vocabulary, field dimensions, scoring elements — anything that is true of one year's game | a season kickoff. **Ships on its own tag series** |
| **Team** | The team's own `CLAUDE.md` content, its robot code, its numbers, its conventions | whenever the team wants. **The baseline never writes here** |

**The season overlay ships on its own tag series, and installing it changes no baseline-owned file.**
Mixing the two series would make a game-vocabulary drop look like a platform change, which destroys
the changelog's decision value exactly when a team needs it — mid-season, deciding whether an update
is urgent.

### The boundary is a path list, not a name prefix

`baseline/manifest.yml` carries an **explicit path list**. Every artifact that updates, verifies, or
reports on baseline files resolves that set **from the list**, never from the `frc-` prefix.

* A baseline file whose name lacks the prefix **is** updated, because the list names it.
* A team file that happens to carry the prefix is **not** touched, because the list does not.

A glob would silently widen the moment a team adds a matching file. An explicit list is the only form
in which *"the update touched something it should not have"* is a comparison rather than an argument.

**A file absent from the list is treated as team-owned.** That is the safe direction: skipping an
update costs less than overwriting a team's tuned copy — and a team whose work gets overwritten stops
updating, which leaves a stale configuration running through a competition season.

---

The schema-host pattern
------------------------

WPILib 2027 is in alpha. API names change between releases, and the shipped tag and the development
branch disagree **today**. Left alone, that churn would touch every artifact in the suite.

So every volatile WPILib fact lives in **exactly one** artifact —
`baseline/skills/current-wpilib-2027/` — and every other artifact **cites** it.

**The acceptance test:** after a WPILib beta, nothing outside the host, the dated stamps, and the
recorded exceptions below needs an edit. If something else does, that artifact restated a fact instead
of citing it. Fix the artifact.

Consumers carry the literal body line `Upstream: current-wpilib-2027`. The host lists its consumers.
Both defects are real — an undeclared consumer means a beta bump misses it, a dangling declaration
means the host's list is fiction — and **CI-10 catches only the first**: it compares declaring
artifacts against the host list in one direction, because an entry declared ahead of its artifact is
legitimate by design. A dangling declaration is caught by reading, not by CI.

### The one recorded exception to cite-don't-restate

`baseline/templates/CLAUDE.md.template` restates the namespace facts inline, and this is
deliberate.

The general rule is that a consumer cites the host and never copies a value. That rule cannot hold
here:

* The template's toolchain section exists to **displace training data at context-load time**. A
  pointer does not displace a strong prior; the contradicting statement has to be *present*.
* The file is loaded as the first 200 lines / 25 KB, whichever binds first. Nothing is fetched.

The one-file-edit promise is really *"the host, the dated
stamps, the root template's toolchain block, **and every working string that cannot cite**"* — any
permission grant, match pattern, or invoked command line that restates a WPILib fact by mechanism,
because a grant string or a match pattern has nowhere to put a citation. Not "one file". The host's
beta procedure (step 4 of "Absorbing a WPILib release") re-derives the current set with a search rather
than trusting a list, and that search — not a copy of it — lives there.

**The mitigation:** the template carries `Upstream: current-wpilib-2027`, so CI-10 sees it as a
declared consumer; the host's beta procedure names it explicitly and the template itself says that when it and the host disagree, **the host is right and the template
is stale.**

---

Declared versus enforced
-------------------------

This is the distinction the whole safety story rests on.

| Mechanism | Establishes | Really? |
| --- | --- | --- |
| `allowed-tools` in a skill or command | a **pre-approval** for that turn | **No restriction at all.** Verbatim: *"It does not restrict which tools are available: every tool remains callable."* Omitting a tool causes a **prompt**, not a block |
| `disallowed-tools` | removal from the pool while the skill is active | Yes, but turn-scoped and skill-scoped |
| A permission **deny** rule | blocks matching command **strings** | Real, and **evadable by a variant invocation** — runners like `devbox run` are not stripped before matching |
| A **subagent's** tool list | a true allowlist | Yes |
| A **hook** | runs outside the model's control | Yes — this is enforcement |

> **Permissions allow; hooks enforce.**
>
> Any property that must be **guaranteed** rather than **declared** belongs in a hook, a genuinely
> sufficient deny rule, or a subagent. Never in an `allowed-tools` line.

### The live design question this leaves open

A read-only *review* artifact is genuinely read-only when built as a **subagent**, and only
*declared* read-only when built as a skill or command. The upstream requirement that chose an
allow-list over a deny-list did so on the reasoning that *"a deny-list cannot establish a positive
property"* — and the verified answer is that **neither list establishes it**.

The requirement therefore stands as a **declaration-and-review** control, not an enforcement one.
**When read-only must be guaranteed, build the artifact as a subagent or enforce it with a hook.**
This is recorded as an open design question rather than resolved by assertion.

The prohibition on artifacts declaring subagent-spawning
grants is a **review-time** control. It proves no artifact *declares* such a grant. It does **not**
prevent spawning at runtime.

---

Repository layout
------------------

```
LICENSE.md  NOTICE  COMMERCIAL-LICENSE.md  LICENSING-FAQ.md   licence set, verbatim from counsel
README.md  CHANGELOG.md
baseline/
  manifest.yml                    the path list — the normative boundary
  skills/current-wpilib-2027/     the schema host + four reference files
  skills/current-claude-models/   the model-currency schema host
  skills/frc-pre-deploy/          validation skill: reports a verdict, enforces nothing
  skills/frc-behavior-first/      the behaviour-first authoring rules
  agents/frc-docs-checker.md      subagent: attempts to settle API existence by compiling
  commands/                       the ten commands — NO frc- prefix (see below)
  templates/                      CLAUDE.md, settings.json, gitignore fragment
setup/setup-frc-baseline.sh       the one executable artifact
docs/                             this file, LIMITATIONS, STUDENT-GUIDE
```

**What is not distributed.** The baseline is developed in a private build repository that also holds
the fixture suites, the CI check runner, the authoring tools, and the quarantined v1.1 deploy gate.
None of that is part of the distribution, and nothing installed by the scaffold refers to it.

**Naming conventions**, recorded as this project's own choices rather than as product facts:

| Kind | Path |
| --- | --- |
| Skill | `.claude/skills/frc-<name>/SKILL.md`, with `name` frontmatter equal to the directory name |
| Subagent | `.claude/agents/frc-<name>.md` |
| Schema host | `.claude/skills/current-<subject>/` — no `frc-` prefix, matching the pattern it is modelled on |
| Command | `.claude/commands/<name>.md` — **no** `frc-` prefix, because the basename is what a student types |

**No capability name may exist as both a command file and a skill directory.** Both create the same
slash invocation, and shipping both is an ambiguity a team cannot debug.

### Commands carry no prefix — and that is why the path list matters

`frc-` is reserved for skills and subagents. A command's basename **is the thing the student types**,
so prefixing it would tax every invocation for a signal the student does not need. Provenance moves
inside the file: the copyright header, the `Last verified` stamp, and the schema-host upstream
declaration.

**This is the first place the prefix heuristic would give an actively wrong answer**, which is the
argument for the path list above stated in the concrete. `deploy.md` and `test.md` are
baseline-managed; nothing about their names says so, and nothing needs to.

### A shipped command name must not collide with the product's

A command basename equal to a Claude Code built-in, **one of its aliases**, or a bundled skill either
shadows the product or is shadowed by it. **For an alias, which way it resolves is undocumented** —
the published precedence rule speaks to a skill and a command sharing a name, and to a skill
overriding a *bundled skill*. Neither sentence reaches an alias.

So the rule is not "predict the winner", it is **the collision must not exist**. Two commands are
renamed accordingly: `debug` → `robot-debug`, `review` → `robot-review`.

---

Branch and tag conventions
----------------------------

* One long-lived `main`. Work merges to `main`.
* Releases are **annotated tags**.
* The season overlay ships on **its own tag series**, so a mid-season overlay drop cannot be
  mistaken for a baseline version bump.
* **Exactly one canonical distribution point — this repository.** The baseline is built in a private
  repository and published here.

Relationship to the companion repository
------------------------------------------

Two repositories, different things, different audiences, **different licences**:

| | Companion (`frc-2027-companion`) | Toolkit (this repository) |
| --- | --- | --- |
| Holds | the guide's code artifacts, verbatim as published | a maintained, versioned product |
| Changes | frozen by the document | evolves independently |
| Licence | **MIT** | **PolyForm Noncommercial 1.0.0** + a separate paid commercial licence |

**The relationship is one-directional and documentation-only.** The baseline may have *originated*
from companion artifacts; it must not depend on the companion at install or build time. **A clean
install succeeds with no credential for, and no network call to, the companion repository** — which
matters because the companion is private until the final public release.

Neither licence governs the other. Do not assume one from the other.

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
