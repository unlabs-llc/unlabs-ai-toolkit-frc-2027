---
# Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md
name: explain
description: Explain a piece of this robot's code to a student, in terms of what the robot physically does.
disable-model-invocation: true
---

# /explain

**Last verified: 2026-09-03**
**Upstream: current-wpilib-2027**

What to explain: $ARGUMENTS — if that is empty, ask which file, class or method the student
wants explained, and do not guess. Explaining the wrong thing convincingly wastes the session.

## The audience

A student on this team who can read code but has not read *this* code, and who will be asked about
it by a judge, a mentor, or the next student to touch it. **They must end up able to explain it
without you.** That is the test of whether this worked.

## How to explain it

1. **Start with what the robot physically does.** Not the class hierarchy. "This holds the arm at
   whatever angle you last asked for, and fights gravity to do it" comes before any type name.
2. **Then the shape of the code** — which file, which class, what calls it and when. A student who
   knows *where* it runs can find it again.
3. **Then the part that is not obvious.** Most robot code has one thing that looks wrong until you
   know why: a sign flip, a unit conversion, a clamp, a magic offset, a check that seems redundant.
   If this code has one, explain it — **this is the highest-value paragraph on the page** and it is
   the one that gets left out. **If it genuinely does not have one, say so plainly.** A constants
   file may simply be a constants file. Manufacturing a hidden subtlety to fill this section is the
   same defect as inventing a derivation, and it will be repeated to a judge just as confidently.
4. **Then what happens when it goes wrong** — what the student would see on the robot if this code
   misbehaved. That is what turns an explanation into something usable in a pit.

## Rules

- **Read the actual code in this project before explaining it.** Do not explain the general pattern
  and let the student assume it matches. If this project's version differs from the common idiom,
  the difference is the interesting part.
- **Do not assert a WPILib behaviour from memory.** The `current-wpilib-2027` skill is the schema
  host, and the names have moved between library builds. The test is **membership, not familiarity**:
  any API name not pinned in the host goes through `frc-docs-checker` unless an existing occurrence
  in this project's source has already been resolved by the compiler. A source occurrence clears
  this gate only when the project has built successfully since that occurrence's last edit *and the
  build could not have succeeded without the compiler resolving that occurrence as a reference to
  the API it names*. A successful build alone is not that evidence: the relevant compile task may
  have been `SKIPPED` or `NO-SOURCE`, and a comment, an excluded source set, or a file that does not
  compile never establishes resolution. Unless you can say why the compiler had to resolve the
  occurrence, send the name to the checker.

  For a name sent to the checker, `FOUND` clears the import or class name it names because the
  checker requires its scratch class's own `.class` file under the probe output directory before
  returning that verdict. Any other answer, or no answer at all, means say plainly that the name is
  unresolved. This does not require the student to finish the code or obtain a successful project
  compile merely to receive an explanation: if the checker cannot decide while the source set is
  unfinished, preserve that uncertainty in the explanation.

  A `FOUND` concerns existence, not behaviour: the checker has no documentation source and cannot
  tell you what the call *does*. A behaviour still needs evidence you can name, and this project's
  own code is the first place to look. Where you have none, say plainly that you are not certain what
  the call does rather than explaining it from memory because the name checked out.
- **Say what you do not know.** A magic number whose origin is not recorded anywhere in the project
  is an honest "nobody wrote down where this came from, and someone should ask." Inventing a
  derivation for it is the single most damaging thing this command could do, because it will be
  repeated to a judge as fact.
- **No fake precision.** If the code is unclear or looks wrong, say so. A student who is told
  confusing code is elegant learns to distrust their own reading.

## Before you finish

Give the student two or three questions they should be able to answer about this code, and let them
check themselves. If they cannot answer them, the explanation is not finished.
