---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: robot-review
description: Review robot code for the defects that strand a robot on the field, before it goes to a match.
disable-model-invocation: true
---

# /robot-review

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

> **Named `/robot-review`, not `/review`, because `/review` is a Claude Code command.** It is listed
> in the product's command table as an alias of `/code-review`. Whether a project file named
> `review.md` would shadow that alias or be shadowed by it is **not documented**, and both outcomes
> are bad — so the collision must not exist. This mirrors `/robot-debug`, renamed for the same
> reason. Do not rename it back. Re-verified against the product command list on **2026-08-10**.
> The baseline's own source repository carries a check for this collision; it runs there, on a tool
> the installer does not copy, so an installed project does not have it to re-run after a local rename.
>
> This is a **robot-code** review and it is not a substitute for the product's `/code-review`.

What to review: $ARGUMENTS — if that is empty, review the uncommitted changes in this project.

## What this is looking for

Not style. **The defects that strand a robot on a field**, in this order:

<!-- FRC-FIELD-DEFECTS-BEGIN -->
1. **A motor left running.** A command that ends or is interrupted without stopping what it started.
   Trace the interruption behaviour and report the test or review evidence you actually found.
2. **A missing or wrong requirement declaration**, letting two commands drive one mechanism.
3. **An unbounded loop or a blocking call** in code that runs every cycle. Anything that waits,
   sleeps, or retries in the main loop can cause missed cycles, and the symptom is a robot that
   responds late and unpredictably. Judge a network read by whether it can wait, not by what it
   touches — WPILib's own NetworkTables documentation puts subscriber reads inside a periodic
   method. Do not flag one as this defect unless you can say where it waits.
4. **A limit that is enforced in only one place**, or only on the way up. Judge a software-only
   limit by what happens when that code does not run — do not flag one as this defect unless you
   can say what it fails to protect.
5. **A unit mismatch.** Degrees into a method expecting radians, rotations into one expecting
   metres. This compiles.
6. **A sensor read with no handling for it being absent, stale or impossible.**
7. **A number nobody can account for.** A gain, an offset or a conversion with no derivation and no
   comment. Flag it and ask; do not guess where it came from.
8. **An uncaught exception on a path that runs every cycle** — in init or in a periodic method.
   It does not misbehave; it takes the whole program down, and the robot stops responding entirely.
<!-- FRC-FIELD-DEFECTS-END -->

9. **An API name that may not exist.** The test is **membership, not familiarity**. Do not clear a
   name merely because it occurs in the code under review. An existing source occurrence clears this
   gate only when the project has built successfully since that occurrence's last edit *and the build
   could not have succeeded without the compiler resolving that occurrence as a reference to the API
   it names*. A successful build alone is not that evidence: the relevant compile task may have been
   `SKIPPED` or `NO-SOURCE`, and a comment, an excluded source set, or a file that does not compile
   never establishes resolution.

   For any import or class not pinned in the `current-wpilib-2027` schema host and not cleared by
   such a compiler-resolved occurrence, use the `frc-docs-checker` subagent. This review does not
   require the student to finish the reviewed changes or obtain a successful project compile: if the
   checker cannot decide because the source set does not compile, report the name as unresolved with
   that reason. A `FOUND` clears the import or class on this axis because the checker requires its
   scratch class's own `.class` file under the probe output directory before returning that verdict.
   A `NOT FOUND`, with the compiler diagnostic and positive-control evidence the checker requires,
   is a finding. A method, field, or constructor is `UNVERIFIED` by design. Give the checker's answer
   in every case; any other answer, or no answer at all, leaves the name unresolved. A fabricated
   name feels familiar, which is why "check anything unfamiliar" fails precisely when it matters.
   The names have moved between library builds.

**These are a floor, not the boundary.** They are the classes that recur, not a closed set — anything
else that would strand the robot on the field belongs in the report, ranked the same way. If you find
something that fits none of them, that is a finding, not an off-topic remark.

**Treat the defects between the two FRC-FIELD-DEFECTS comment markers above and the field-defect
list in the baseline's `CLAUDE.md` template as one list represented in two places.** The baseline's
own source repository carries a consistency check for the two shipped copies; the baseline installer
adds no such check to a team project. If the two read differently, report that and stop there: an
installed project holds only its own two copies, and this baseline installs no location the shipped
originals could be fetched from and no per-file record either copy could be checked against, so
which copy diverged cannot be decided from inside the project. Say so, give the team the baseline
version recorded in `.claude/frc-baseline-manifest.yml` and whatever this project's `CLAUDE.md`
records on its first line, and treat neither copy as authoritative. If the team can identify and
obtain the exact baseline source used for installation, compare both copies against it: a divergence
already present in the shipped files is a baseline defect to report upstream, while a difference
confined to either local copy is a local edit to resolve with the team. If that source cannot be
identified and obtained, leave the attribution unresolved.

## How to report

- **Order by what would happen on the field**, worst first. A crash in autonomous outranks a naming
  inconsistency and the list should show that.
- **Each finding names the file and line, what goes wrong, and the conditions under which it goes
  wrong.** A finding that cannot say when it fires is a suspicion — label it as one.
- **A finding is a claim and it carries your burden.** If you propose a change, say what it would
  break if you are wrong. Being wrong about robot code costs a match.
- **Say what you did not review.** Files skipped, paths not traced, anything you could not confirm.

## What not to do

- **Do not fix anything.** This command reads and reports. A review that edits removes the student's
  chance to decide, and the student is the one who has to defend the code.
- **Do not report a clean review as "the code is correct."** Report what was examined and what was
  checked for. Those are different claims and the difference matters.
- **Do not pad the list.** Ten trivial findings hide the one that matters. If there is nothing
  serious, say there is nothing serious.
