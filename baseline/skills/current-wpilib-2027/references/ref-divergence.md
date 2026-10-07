<!-- Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md -->

# Tag versus `main` — the divergence, and how to re-measure it

**Last verified: 2026-09-04**

> **RESOLVED AT alpha-7 — measured 2026-09-04.** The `Alert` divergence below described
> `v2027.0.0-alpha-6` (tag) against `main`. At **`v2027.0.0-alpha-7`** the development-branch
> location SHIPPED: `javap` against the 30 jars an alpha-7 project resolves finds
> **`org.wpilib.util.Alert` present** (in `wpiutil-java`) and **`org.wpilib.driverstation.Alert`
> absent**. A team on the newest release must import `org.wpilib.util.Alert`; the alpha-6 guidance
> below is correct only for a team still on alpha-6. **Read the rows that follow as a record of the
> alpha-6 state, not as current guidance.**
>
> The mechanism this file teaches is unchanged and is the reason the row was written pinned: a name
> true against one ref can be false against another, and this is what it looks like when the refs
> converge.


The newest published **release** and the pinned **development branch** resolve to the same commit at
this verification snapshot. Neither ref establishes what a particular team has installed; a team may
still be on an earlier release, so ask for that team's ref before selecting an import. The current
identity does not remove the need for this file: `main` can advance and divergence can recur.

This file records the divergence as measured, and the command to re-measure it. **Re-run the command;
do not re-reason the answer.**

---

## The two refs

| Role | Ref | SHA | Date |
|---|---|---|---|
| Newest published release at verification | `v2027.0.0-alpha-7` | `b3232873240d60fe9f3d8ed6587e2770392f206c` (**tag object**) | 2026-09-01 |
| Pinned development snapshot | `main` | `83df3ee3ce1e892f76970ec21c8efdc00a104d4a` (commit) | 2026-08-31 |

**The release row's sha is the tag-object sha** — the annotated tag itself. The installed-safe public
evidence is `GET https://api.github.com/repos/wpilibsuite/allwpilib/git/ref/tags/v2027.0.0-alpha-7`:
it returns object type `tag` and sha `b3232873240d60fe9f3d8ed6587e2770392f206c`; following that
response's object URL returns commit `83df3ee3ce1e892f76970ec21c8efdc00a104d4a` (verified live
2026-09-02). A re-measurer running `git rev-parse v2027.0.0-alpha-7^{commit}` gets that commit sha —
a **different value from the tag-object sha**. At this snapshot it is also the `main` commit; those are
separate facts, and `main` can move independently after verification.

There is zero measured divergence at this snapshot. That zero is not a new invariant and must be
re-measured after either ref moves.

---

## Current measured divergence in `wpilibj`

At `v2027.0.0-alpha-7` and `main@83df3ee`, the measured divergence is **zero**: the refs resolve to the
same commit and tree, and the GitHub comparison reports `status=identical`, `ahead_by=0`,
`behind_by=0`, and `files=0`. This is the 2026-09-02 snapshot, not a claim that divergence cannot
recur after `main` advances.

## Historical measurement: alpha-6 versus `main@df5a648`

Diff of `wpilibj/src/main/java/**/*.java` between the two refs, 2026-08-06 — **a basis that was too
narrow, corrected 2026-08-29.** `wpilibj` also compiles `src/generated/main/java`, and over the same
interval that sourceset diverges in TWENTY-TWO further files. The table below enumerates the eight
hand-written differences only; re-run the script at the foot of this file, which now uses both
sourcesets, before relying on any completeness claim here.

### Present at the release, gone on `main`

| Path at `v2027.0.0-alpha-6` | State at `main@df5a648` |
|---|---|
| `org/wpilib/driverstation/Alert.java` | **moved** → `wpiutil/src/main/java/org/wpilib/util/Alert.java` |
| `org/wpilib/driverstation/UserControls.java` | removed |
| `org/wpilib/driverstation/DefaultUserControls.java` | removed |
| `org/wpilib/driverstation/UserControlsInstance.java` | removed |

### New on `main`, absent from the release

| Path at `main@df5a648` | State at `v2027.0.0-alpha-6` |
|---|---|
| `org/wpilib/driverstation/HIDDevice.java` | absent |
| `org/wpilib/driverstation/DSGamepadChooser.java` | absent |
| `org/wpilib/driverstation/DriverStationDisplay.java` | absent |
| `org/wpilib/hardware/bus/CANBusMap.java` | **moved** — the class exists at alpha-6 as `org.wpilib.hardware.hal.CANBusMap`, in `hal/`, not `wpilibj/`. Not a new class: it moved project and package, and changed declaration kind (a `final class` of `int` constants at alpha-6; an `enum` at `main`). Do not read this row as "unavailable" |

### The one that will actually break a team

`Alert` is the concrete case, and it is worth spelling out because it is the shape of every future
instance of this defect:

| If the answer says | It is right for | It is wrong for |
|---|---|---|
| `import org.wpilib.driverstation.Alert;` | a team on `v2027.0.0-alpha-6` | a team building against `main` |
| `import org.wpilib.util.Alert;` | a team building against `main` | a team on `v2027.0.0-alpha-6` |

Neither import is "the 2027 import". **The question "which ref?" has to be asked**, and when it cannot
be answered, both are stated.

### Scope of this measurement

This diff covers **`wpilibj` only** — the Java robot library. It is where a student's imports come from
and it is not the whole repository. The command frameworks moved too over the same interval
(`commandsv2` 350 → 399 paths, `commandsv3` 108 → 119); they are recorded in
[`commands.md`](commands.md) rather than enumerated here.

**Report this as what it measured**, and the measurement is narrower than the heading suggests: the
eight rows above are the HAND-WRITTEN `wpilibj` sources only. Adding the generated sourceset takes the
count to thirty at these two refs. Do not report "the refs diverge in eight files", and do not report
eight as the `wpilibj` surface either.

**THE TWENTY-TWO GENERATED DIFFERENCES INCLUDE CONTROLLER CLASSES, WHICH IS WHY THIS MATTERS.** All
twenty-two are new on `main` and absent at the tag, and they are a family: eleven controller classes
under `org.wpilib.driverstation` and their eleven `*Sim` twins under `org.wpilib.simulation`. Among
them is `org.wpilib.driverstation.XboxController` — verified 2026-08-29 present at `main@df5a648`
(`public class XboxController implements HIDDevice, Sendable`) and absent at `v2027.0.0-alpha-6`,
where the only such class is `NiDsXboxController`. `commandsv2` likewise gains
`org.wpilib.command2.button.CommandXboxController` on `main`.

They are NOT enumerated by name here on purpose. A list of twenty-two names in a document nothing
re-runs is a list that goes stale silently; the script at the foot of this file produces the current
set from both sourcesets, and that is the answer to trust. What this section fixes is the BASIS, not
a snapshot.

**What the narrow basis would have caused, stated plainly:** every artifact in this unit treats
`XboxController` as the canonical name that is gone in 2027. A team building against `main` compiles
`new XboxController(0)` today. An agent reading the old text would have told them the class does not
exist — a wrong answer about the robot library at the team's own ref, produced by the file whose
whole purpose is to prevent exactly that.

---

## Re-measuring

```bash
REL=v2027.0.0-alpha-7
DEV=$(gh api /repos/wpilibsuite/allwpilib/commits/main --jq .sha) \
  || { echo "BLOCKED: main-ref lookup failed; the comparison did NOT run"; exit 1; }

# Keep the listings under a directory mktemp creates for this run: with default shell options, `>`
# truncates an existing target before the producing command runs, so writing tree-$R.txt into the
# caller's cwd would truncate a prior snapshot of that name even when `gh api` then fails.
# No cleanup is installed: the scratch directory is left behind under ${TMPDIR:-/tmp}, at the path
# printed below — delete it by hand when it is no longer wanted.
LISTING_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ref-divergence.XXXXXX") || \
  { echo "could not create a scratch directory for the tree listings"; exit 1; }
echo "scratch directory: $LISTING_DIR"

for R in "$REL" "$DEV"; do
  # Assert completeness BEFORE trusting the listing — a truncated tree diffs clean.
  tree_state=$(gh api "/repos/wpilibsuite/allwpilib/git/trees/$R?recursive=1" --jq .truncated) \
    || { echo "BLOCKED: gh api failed checking tree completeness at $R; the comparison did NOT run"; exit 1; }
  [ "$tree_state" = false ] \
    || { echo "BLOCKED: tree completeness was not false at $R; the comparison did NOT run"; exit 1; }
  whole_tree="${LISTING_DIR:?}/whole-tree-$R.txt"
  gh api "/repos/wpilibsuite/allwpilib/git/trees/$R?recursive=1" --jq '.tree[].path' > "$whole_tree" \
    || { echo "BLOCKED: gh api failed fetching the whole tree for $R; the comparison did NOT run"; exit 1; }
  [ -s "$whole_tree" ] \
    || { echo "BLOCKED: the complete-tree response contained no paths at $R; the comparison did NOT run"; exit 1; }
  # BOTH production sourcesets. `wpilibj` compiles hand-written sources AND a generated sourceset,
  # and scoping this to `src/main/java` alone is the exact basis error `namespaces.md` names for
  # `Nat` and already avoids for `wpimath`. Measured 2026-08-29: the narrow basis reported eight
  # diverging files; the correct one reports thirty, and the twenty-two it had been missing are all
  # generated -- among them `org.wpilib.driverstation.XboxController`, which exists at `main` and not
  # at the tag. A file whose purpose is to say which names disagree cannot afford to miss a
  # controller.
  grep -E '^wpilibj/src/(main|generated/main)/java/.*\.java$' "$whole_tree" \
    | sort > "${LISTING_DIR:?}/tree-$R.txt"
  stages=("${PIPESTATUS[@]}")
  [ "${stages[0]}" -le 1 ] || { echo "BLOCKED: grep failed filtering the tree for $R (exit ${stages[0]}); the comparison did NOT run"; exit 1; }
  [ "${stages[1]}" = 0 ] || { echo "BLOCKED: sort failed writing the listing for $R (exit ${stages[1]}); the comparison did NOT run"; exit 1; }
done

# A listing that filtered to ZERO paths does not mean the refs agree — it means the scope this
# measures is not there any more. comm over two empty listings prints nothing and exits 0, which
# reads exactly like "no divergence". Assert non-empty before comparing.
for R in "$REL" "$DEV"; do
  [ -s "${LISTING_DIR:?}/tree-$R.txt" ] \
    || { echo "NO path matched '^wpilibj/src/main/java/.*\.java$' at $R — the scope this measures is gone; the comparison did NOT run"; exit 1; }
done

echo "--- at the release, gone on main ---"
comm -23 "$LISTING_DIR/tree-$REL.txt" "$LISTING_DIR/tree-$DEV.txt" || { echo "comm failed comparing the listings"; exit 1; }
echo "--- on main, absent from the release ---"
comm -13 "$LISTING_DIR/tree-$REL.txt" "$LISTING_DIR/tree-$DEV.txt" || { echo "comm failed comparing the listings"; exit 1; }
```

**The `truncated` assertion is not optional.** A truncated tree produces a short listing, a short
listing produces an empty diff, and an empty diff reads exactly like "the refs agree." A check that
cannot run has not passed.

**Neither is the non-empty assertion**, added 2026-08-21. It closes the same failure through a
different door: the tree can arrive complete and the *filter* still match nothing, because the
source layout moved. Without the assertion the script exits 0 and prints two empty sections, which
is indistinguishable from a clean comparison. With it, the run stops and says the scope is gone.
The two assertions are not interchangeable — `truncated` catches a short tree, this one catches a
stale filter — and an empty diff is only meaningful once **both** have passed.

---

## What a moved file looks like versus a removed one

`comm` reports a move as a removal plus an addition, and only if both halves are inside the filtered
path. `Alert` moved from `wpilibj/` to `wpiutil/`, so the filter above shows the **removal** and not the
matching addition — which is why the table records the destination explicitly.

Before recording a path as *removed* **or as *absent*, search the validated whole-tree listing for
its basename — and search the listing for the OTHER ref, which is the half this procedure used to
skip.** The snippet below searches `$DEV` only, so it catches a class that moved between release and
`main` and misses one that moved the other way. Measured 2026-08-28: `CANBusMap` was recorded
`absent` at alpha-6 while it existed there under a different project and package, found by an
independent review and confirmed three ways — an `unzip -l` of the alpha-6 `hal-java` jar, and a
compile probe returning FOUND for `org.wpilib.hardware.hal.CANBusMap` and NOT FOUND for
`org.wpilib.hardware.bus.CANBusMap`. Run the search below once per listing, substituting `$REL` for
`$DEV`, and record the destination when either search hits:

```bash
if grep '/Alert\.java$' "${LISTING_DIR:?}/whole-tree-$DEV.txt"; then
  :
else
  basename_status=$?
  [ "$basename_status" = 1 ] \
    || { echo "BLOCKED: grep failed searching the complete tree for Alert.java (exit $basename_status); no removal conclusion was reached"; exit 1; }
  echo "No path ending in /Alert.java was found in the complete development tree."
fi
# → wpiutil/src/main/java/org/wpilib/util/Alert.java
```

**Recording a move as a deletion is the failure mode here** — and recording it as an *absence* is the
same failure wearing the other direction's label. Either one tells a team a class is gone when it is
one import away, which is worse than saying nothing. The `Alert` row was written with this rule
applied; the `CANBusMap` row was not, because the procedure above only looked one way.
