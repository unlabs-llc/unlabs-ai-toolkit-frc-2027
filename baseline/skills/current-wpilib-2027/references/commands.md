<!-- Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md -->

# WPILib 2027 command frameworks

**Last verified: 2026-09-02** · `ref_pinned`: `v2027.0.0-alpha-7` and `main@83df3ee`

Owned by `current-wpilib-2027`.

---

## Two frameworks ship side by side

2027 ships **both** command frameworks as separate Gradle projects. This is the fact to establish
before answering any command-based question — the same class name means different things in each.

| | Commands v2 | Commands v3 |
|---|---|---|
| Project | `commandsv2/` | `commandsv3/` |
| Java package | `org.wpilib.command2` | `org.wpilib.command3` |
| 2026 ancestor | `edu.wpi.first.wpilibj2.command` | none — new in 2027 |
| Paths at `alpha-7` | 402 | 119 |
| Paths at `main@83df3ee` | 402 | 119 |
| Paths at `alpha-6` (historical) | 350 | 108 |
| Paths at `main@df5a648` (historical) | 399 | 119 |

**`Command` exists in both packages and they are not the same type.** At
`v2027.0.0-alpha-6@878da3d54cbc6b64d663bded17d87d5bed040ed9`,
`org.wpilib.command2.Command` is a public abstract class and `org.wpilib.command3.Command` is a public
interface. They are distinct models and are not interchangeable.

**Ask which framework a team is on.** When it cannot be established, say so and answer for neither
rather than guessing the more common one.

---

## Commands v2 — the continuation of what teams know

At the current verification snapshot, the tag and `main` resolve to the same commit, so no class can
diverge between those two refs. That is not a controller inventory and not a promise about future
`main`; teams on earlier releases still require an exact-ref check.

### Historical alpha-6/`main@df5a648` controller divergence

> **A controller class exists on `main` that does not exist at the tag.**
> `org.wpilib.command2.button.CommandXboxController` is present at `main@df5a648` and absent from
> `v2027.0.0-alpha-6`, where the nearest class is `CommandNiDsXboxController`. Its `wpilibj` partner
> `org.wpilib.driverstation.XboxController` diverges the same way. Both live in GENERATED sourcesets,
> which is why a `src/main/java`-only census misses them — see
> [`ref-divergence.md`](ref-divergence.md), whose basis was corrected on 2026-08-29 for this reason.
> Do not tell a team building against that historical `main@df5a648` snapshot that these names do not
> exist.

`org.wpilib.command2`, verified at `alpha-6`. The familiar class set carried forward under the new
package root:

`Command` · `CommandScheduler` · `Commands` · `ConditionalCommand` · `DeferredCommand` ·
`FunctionalCommand` · `InstantCommand` · `NotifierCommand` · `ParallelCommandGroup` ·
`ParallelDeadlineGroup` · `ParallelRaceGroup` · `PrintCommand` · `ProxyCommand` · `RepeatCommand` ·
`RunCommand` (and others)

Trigger and button bindings live in `org.wpilib.command2.button`, including `CommandGamepad` and the
generated `CommandNiDs*Controller` classes — see [`namespaces.md`](namespaces.md) for the controller
changes, which apply here too.

**DO NOT TELL A TEAM HOW MANY EDITS THE 2026 MIGRATION TAKES.** This paragraph has now asserted a
count three times and been wrong twice, which is the reason it no longer asserts one.

What IS established, and all that is:

- The package root changed: `edu.wpi.first.wpilibj2.command` → `org.wpilib.command2`. This applies at
  both pinned refs.
- At `v2027.0.0-alpha-6` the controller classes were replaced, so a package-only fix leaves an
  unresolved `CommandXboxController`.
- At `main@df5a648` a class of that name EXISTS (see the note above) — but it is not the 2026 class
  wearing a new package. Its public surface differs: methods present in the 2026 class are absent
  there. A package-only fix therefore resolves the TYPE and can still leave call sites unresolved.

So the honest instruction is not a number. **Establish the exact ref the team is on, then check the
members they actually call against that ref.** The two current pinned refs are identical only at this
snapshot; an earlier installed release can still differ, and `main` can diverge again after it
advances.

*Corrected 2026-08-29 for the second time in a day. The first version was unqualified and false on
`main`; the fix for it asserted "one edit on `main`", which is also false — the class exists but its
API moved. An edit count is a claim about every call site in a project this file has never seen.*

*Corrected 2026-08-21.* These two paragraphs said "renames", inheriting an error in `namespaces.md`
that mapped controllers unconditionally. The documented base-controller replacement depends on which
Driver Station the team runs; `namespaces.md` owns that mapping and its sources. A corresponding
replacement for `CommandXboxController` was **not established** — do not generate one from parallel
class names.

---

## Commands v3 — new and still moving

`org.wpilib.command3`, verified at `alpha-6`. A different model, not a rename: coroutine-based, with a
declarative state-machine layer.

Top-level source-file/type inventory at `alpha-6` includes: `Command` · `CommandState` · `Coroutine` ·
`Continuation` · `ContinuationScope` · `Scheduler` · `SchedulerEvent` · `Mechanism` · `Binding` ·
`BindingScope` · `BindingType` · `ConflictDetector` · `ParallelGroup` · `ParallelGroupBuilder` ·
`OpModeFetcher` · `CommandTraceHelper`

The `v2027.0.0-alpha-6` release notes record two v3 changes landing in that release alone: *"[cmd3] Add
rising and falling edge trigger factories"* and *"[cmd3] Add a declarative state machine API on top of
commands v3."*

> **The current refs do not diverge.** Commands v3 has 119 paths at both alpha-7 and
> `main@83df3ee` because those refs resolve to the same commit at this snapshot. That does not
> establish that v3 has stabilized or that `main` cannot advance.
>
> **The historical alpha-6 inventory remains historical.** Commands v3 had 108 paths at alpha-6 and
> has 119 at alpha-7, but this refresh did not re-enumerate a current source-file/type inventory.
> Prefer "not established at your ref" over a detail that cannot be pinned; the inventory above is
> for alpha-6 and is not a public-API inventory.
>
> **What the path counts do and do not show.** A path count measures files, not API surface: a rename
> nets to zero and a rewrite inside one file is invisible. Treat these numbers as evidence that the
> project changed BETWEEN RELEASES — the 108 -> 119 movement above — never as a measure of how
> much API surface changed. Note that the two current-ref rows are identical to each other because
> those refs are the same commit; that is evidence of no change between them, not of change.

---

## `OpMode` — framework relationship not established

2027 adds `org.wpilib.opmode` (`OpMode`, `PeriodicOpMode`, `Autonomous`, `Teleop`, `Utility`) and
`org.wpilib.framework.OpModeRobot`.

This file has not established how these types relate to either command framework or to `TimedRobot`.
It has also not established whether a 2027 team should start from `OpModeRobot` or `TimedRobot`.
`[verify]`

Recording that as an open gap rather than answering it is the point: this is exactly the kind of
question where a confident wrong answer costs a team a rewrite, and it is cheap to establish properly
once someone runs a real project.

---

## How this file was derived

The current package-and-path-count table was re-derived for alpha-7 and `main@83df3ee`. The
explicitly alpha-6 source-file/type inventories above remain historical and were not replaced with an
unverified alpha-7 enumeration.

```bash
LISTING_DIR=$(mktemp -d "${TMPDIR:-/tmp}/command-inventory.XXXXXX") || {
  echo "BLOCKED: could not create a tree-listing directory; the inventory did NOT run"
  exit 1
}
echo "tree-listing directory: $LISTING_DIR"

# Fetch each complete tree. A producer failure, truncation, or empty tree is not an empty framework.
for R in v2027.0.0-alpha-7 83df3ee3ce1e892f76970ec21c8efdc00a104d4a; do
  truncated_rc=0
  truncated=$(gh api "/repos/wpilibsuite/allwpilib/git/trees/$R?recursive=1" --jq .truncated) \
    || truncated_rc=$?
  [ "$truncated_rc" = 0 ] || { echo "BLOCKED: gh api exited $truncated_rc checking tree completeness at $R; the inventory did NOT run"; exit 1; }
  [ "$truncated" = false ] || { echo "BLOCKED: the GitHub tree is truncated at $R; the inventory did NOT run"; exit 1; }
  gh api "/repos/wpilibsuite/allwpilib/git/trees/$R?recursive=1" --jq '.tree[].path' \
    > "${LISTING_DIR:?}/tree-$R.txt"
  tree_rc=$?
  [ "$tree_rc" = 0 ] || { echo "BLOCKED: gh api exited $tree_rc fetching the tree at $R; the inventory did NOT run"; exit 1; }
  [ -s "$LISTING_DIR/tree-$R.txt" ] || { echo "BLOCKED: the complete-tree request returned no paths at $R; the inventory did NOT run"; exit 1; }
done

for R in v2027.0.0-alpha-7 83df3ee3ce1e892f76970ec21c8efdc00a104d4a; do
  for P in commandsv2 commandsv3; do
    # Package inventory per framework. Every pipeline stage is a producer with a checked status.
    packages=$(
      grep -E "^$P/src/main/java/org/wpilib/.*\.java$" "$LISTING_DIR/tree-$R.txt" \
        | sed -E 's#.*/(org/wpilib/[a-z0-9]+)/.*#\1#' | sort -u
      inventory_statuses=("${PIPESTATUS[@]}")
      [ "${inventory_statuses[0]}" -le 1 ] || { echo "BLOCKED: grep exited ${inventory_statuses[0]} inventorying $P at $R" >&2; exit 1; }
      [ "${inventory_statuses[1]}" = 0 ] || { echo "BLOCKED: sed exited ${inventory_statuses[1]} inventorying $P at $R" >&2; exit 1; }
      [ "${inventory_statuses[2]}" = 0 ] || { echo "BLOCKED: sort exited ${inventory_statuses[2]} inventorying $P at $R" >&2; exit 1; }
    ) || exit 1
    if [ -n "$packages" ]; then
      printf '%s packages @ %s:\n%s\n' "$P" "$R" "$packages"
    else
      printf '%s packages @ %s: ABSENT after a complete-tree check\n' "$P" "$R"
    fi

    count_rc=0
    count=$(grep -cE "^$P/" "$LISTING_DIR/tree-$R.txt") || count_rc=$?
    [ "$count_rc" -le 1 ] || { echo "BLOCKED: grep exited $count_rc counting $P at $R; the count did NOT run"; exit 1; }
    if [ "$count" = 0 ]; then
      printf '%s paths @ %s: ABSENT after a complete-tree check\n' "$P" "$R"
    else
      printf '%s paths @ %s: %s\n' "$P" "$R" "$count"
    fi
  done
done
```

The names above are source-file basenames from the tree listing. **They establish only that a Java
source path with that basename exists at the ref — not its top-level declaration kind, accessibility,
importability, or API shape.** Reported as what it measured.
