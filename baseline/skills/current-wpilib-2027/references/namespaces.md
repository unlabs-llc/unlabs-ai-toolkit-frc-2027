<!-- Copyright Unlabs, LLC — PolyForm Noncommercial 1.0.0. Commercial use: see COMMERCIAL-LICENSE.md -->

# WPILib 2027 namespaces

**Last verified: 2026-09-02** · `ref_pinned`: `v2027.0.0-alpha-7` (`b323287…`) and `main@83df3ee`

Owned by `current-wpilib-2027`. Cite these; do not restate them in another artifact.

---

## The headline, as a contrast pair

> **2027 uses `org.wpilib`. It replaces `edu.wpi.first`, which no longer exists.**

Both halves are stated together on purpose. `edu.wpi.first` is the established prior in Java WPILib
code — tutorials, forum answers, and prior seasons' team code included. Naming only the new root
leaves that Java default intact; C++ and Python examples do not use Java package names at all, so this
contrast is Java-specific.

**Evidence, both refs, whole-tree:**

**Counting basis:** `.java` **files** under `wpilibj/src/main/java/` — directory entries excluded, and
the separate `src/generated/main/java` sourceset excluded. Stated because three bases give three
different numbers, and an unstated basis is how the earlier figure here went wrong.

| Ref | `.java` files under `edu/wpi/first/` | under `org/wpilib/` |
|---|---|---|
| `v2027.0.0-alpha-7` | **0** | 138 |
| `main@83df3ee` | **0** | 138 |

**The zero is the load-bearing claim.** At the 2026-08-06 pass it was established basis-independent —
holding for `.java`-only, for any-path including directories, and for `src/main` plus
`src/generated/main` together — at the refs then pinned. On 2026-09-02 it was re-verified at the refs
above on the `.java`-files-under-`wpilibj` basis, which contains this table's basis and both
production sourcesets. The 138 is context.

**The headline says `edu.wpi.first` no longer exists, and that is measured whole-tree, not inferred
from `wpilibj` alone.** An independent review flagged the headline as broader than the `wpilibj`-scoped
count supported — correctly, of the evidence as it then stood. So it was measured: at `83df3ee` the
complete recursive tree holds **9950 entries and not one path contains `edu/wpi/first`**, on any
basis, `.java` or otherwise. The reviewer's objection was right about the evidence and wrong about the
claim, and the fix was to measure rather than to soften the sentence.

Derived from `GET /repos/wpilibsuite/allwpilib/git/trees/<ref>?recursive=1`, which reported
`truncated: false` at both refs — so this is the complete tree, not a page of it. The two refs resolve
to the same tree at this verification snapshot; that does not establish that they will remain
identical.

---

## Package map

The moves that matter to a team, verified at `v2027.0.0-alpha-6`. The old column is the 2026 package
at `v2026.2.1@c89401250fbd412ba050f595551d0a451b7307a2`.

| 2026 (`v2026.2.1`) | 2027 (`alpha-6`) | Notes |
|---|---|---|
| `edu.wpi.first.wpilibj` | **split** — see below | The 2026 grab-bag package is gone; its classes were sorted into purpose-named packages |
| `edu.wpi.first.wpilibj2.command` | `org.wpilib.command2` | Commands v2 |
| `edu.wpi.first.wpilibj2.command.button` | `org.wpilib.command2.button` | |
| *(did not exist)* | `org.wpilib.command3` | Commands v3 — new in 2027 |
| `edu.wpi.first.math.*` | `org.wpilib.math.*` | Root changed **and** some sub-packages moved — see below |
| `edu.wpi.first.networktables` | `org.wpilib.networktables` | |
| `edu.wpi.first.units` | `org.wpilib.units` | |
| `edu.wpi.first.hal` | `org.wpilib.hardware.hal` | Moved **under** `hardware` |
| `edu.wpi.first.apriltag` | `org.wpilib.vision.apriltag` | Moved **under** `vision` |
| `edu.wpi.first.cscore` | `org.wpilib.vision.camera` | Renamed and moved |
| `edu.wpi.first.util.datalog` | `org.wpilib.datalog` | Promoted out of `util` |
| `edu.wpi.first.epilogue` | `org.wpilib.epilogue` | |
| `edu.wpi.first.net` | `org.wpilib.net` | |

### WPIMath sub-packages moved too

*Corrected 2026-08-21.* The `edu.wpi.first.math.*` row above read "Sub-package names unchanged" until
this edit. That was false, and it is the shape of error that matters most here: it invites a
root-only search-and-replace, which produces imports that do not resolve for `Matrix`, `MathUtil`
and `DCMotor` among others. This correction carries its own date, above; the file's `Last verified`
stamp does not date it.

**Method, and the source sets it covers.** Reduce every production `.java` file under
`wpimath/src/main/java/` **and** `wpimath/src/generated/main/java/` at each ref to a
**source-set + class-basename** key carrying its package, then join the two refs on that key.
**Included:** those two production source sets, Java only. **Excluded:** `src/test/java`,
`src/dev/java`, C++, Python, and `.proto` inputs. Outside `wpimath`, one other project holds this
package tree at `v2026.2.1` — `wpilibj/src/test/java` — which is a test source set and so is out of
the basis; at `alpha-6` no project outside `wpimath` holds `org/wpilib/math` in Java at all.

**The source set has to be in the key.** At `v2026.2.1` the generated protobuf outer classes
`math.proto.Kinematics`, `math.proto.Spline` and `math.proto.Trajectory` share a basename with the
hand-written `math.kinematics.Kinematics`, `math.spline.Spline` and `math.trajectory.Trajectory`.
Keyed on the basename alone, those three collide and the join reports three moves that never
happened. Keyed on source set plus basename, they do not. Measured on the same two trees, the
cross-source-set set is not empty: it contains exactly those three old generated protobuf classes.
Their `alpha-6` basename matches are the hand-written classes just named, so they are the three false
positives, not hidden moves; there are no other cross-source-set candidates.

```bash
# Re-run this; do not re-reason it. Every step that can produce an empty or partial input stops the
# run rather than letting a clean-looking answer be computed from it.
set -euo pipefail
OLD=c89401250fbd412ba050f595551d0a451b7307a2   # v2026.2.1,         peeled from its tag object
NEW=878da3d54cbc6b64d663bded17d87d5bed040ed9   # v2027.0.0-alpha-6, peeled from its tag object
WORK=$(mktemp -d "${TMPDIR:-/tmp}/wpimath-moves.XXXXXX")
echo "scratch directory (left behind on purpose; delete it by hand): $WORK"

# 1. Whole tree at each ref. A truncated tree yields a short listing, a short listing yields a
#    small confident wrong answer — so refuse to continue on one.
for side_ref in "old:$OLD" "new:$NEW"; do
  side=${side_ref%%:*}; ref=${side_ref#*:}
  gh api --method GET "repos/wpilibsuite/allwpilib/git/trees/$ref" -f recursive=1 \
    > "$WORK/tree-$side.json"
  jq -e '.truncated == false' "$WORK/tree-$side.json" >/dev/null \
    || { echo "TREE TRUNCATED at $ref — counts derived from it are unusable"; exit 1; }
done

# 2. Production Java only. Each line becomes  <source set> TAB <package>.<Class>, vendor root removed.
#    awk does the filtering rather than grep on purpose: grep exits 1 when nothing matches, and under
#    `set -e -o pipefail` that would abort the run BEFORE the empty-listing check below could say what
#    went wrong. awk exits 0 on no match, so the explicit check is what reports it.
jq -r '.tree[] | select(.type == "blob") | .path' "$WORK/tree-old.json" \
  | awk '/^wpimath\/src\/(main|generated\/main)\/java\/edu\/wpi\/first\/math\/.*\.java$/' \
  | sed -e 's#^wpimath/src/main/java/edu/wpi/first/#main\t#' \
        -e 's#^wpimath/src/generated/main/java/edu/wpi/first/#generated\t#' \
        -e 's#\.java$##' \
  | tr '/' '.' | LC_ALL=C sort > "$WORK/old-files.txt"

jq -r '.tree[] | select(.type == "blob") | .path' "$WORK/tree-new.json" \
  | awk '/^wpimath\/src\/(main|generated\/main)\/java\/org\/wpilib\/math\/.*\.java$/' \
  | sed -e 's#^wpimath/src/main/java/org/wpilib/#main\t#' \
        -e 's#^wpimath/src/generated/main/java/org/wpilib/#generated\t#' \
        -e 's#\.java$##' \
  | tr '/' '.' | LC_ALL=C sort > "$WORK/new-files.txt"

# An EMPTY listing means the filter stopped matching the layout — not that nothing moved.
for side in old new; do
  [ -s "$WORK/$side-files.txt" ] \
    || { echo "NO production Java matched the $side filter — the layout moved; this census did NOT run"; exit 1; }
done

# 3. Key = source set + class basename; value = package. The 2026 key must be unique; alpha-6 may
#    carry multiple packages for one key, which step 4 intentionally collects.
key() {
  awk -F'\t' -v OFS='\t' '{ c = $2; sub(/^.*\./, "", c); p = $2; sub(/\.[A-Za-z0-9_$]+$/, "", p);
                            print $1 "/" c, p }' "$1" | LC_ALL=C sort -t $'\t' -k1,1
}
key "$WORK/old-files.txt" > "$WORK/old-by-key.txt"
key "$WORK/new-files.txt" > "$WORK/new-by-key.txt"
dups=$(cut -f1 "$WORK/old-by-key.txt" | uniq -d)
[ -z "$dups" ] || { printf 'duplicate 2026 keys — the key is not unique, so the join is unsound:\n%s\n' "$dups"; exit 1; }

# 4. A move is a key at both refs whose 2026 package is NOT among its alpha-6 packages. Collecting
#    ALL alpha-6 packages per key is what suppresses the NumericalIntegration false positive that a
#    plain field-inequality test produces (explained below the table).
moves() {
  LC_ALL=C join -t $'\t' "$WORK/old-by-key.txt" "$WORK/new-by-key.txt" \
    | awk -F'\t' '{ old[$1] = $2; dest[$1] = dest[$1] "," $3 }
        END { for (k in old) if (index(dest[k] ",", "," old[k] ",") == 0) {
                c = k; sub(/^.*\//, "", c); print old[k] "." c " -> " substr(dest[k], 2) "." c } }' \
    | LC_ALL=C sort
}
echo "--- moved ---"; moves
echo "--- counts ---"
total=$(wc -l < "$WORK/old-files.txt")
moved=$(moves | wc -l)
absent=$(LC_ALL=C join -t $'\t' -v1 "$WORK/old-by-key.txt" "$WORK/new-by-key.txt" | wc -l)
printf '2026 production Java files: %s\nmoved: %s\nabsent at alpha-6: %s\nkept: %s\n' \
  "$total" "$moved" "$absent" "$((total - moved - absent))"
```

**Measured 2026-08-21** at `v2026.2.1@c89401250fbd412ba050f595551d0a451b7307a2` and
`v2027.0.0-alpha-6@878da3d54cbc6b64d663bded17d87d5bed040ed9`, both trees reporting
`truncated: false`: **236** production Java files on the 2026 side — **183** keep their package,
**21 move**, and **32** keys have no same-named class at `alpha-6`. 183 + 21 + 32 = 236.

The 21 that move, in full:

| 2026 (`edu.wpi.first.`…) | 2027 `alpha-6` (`org.wpilib.`…) |
|---|---|
| `math.ComputerVisionUtil` | `math.util.ComputerVisionUtil` |
| `math.DARE` | `math.linalg.DARE` |
| `math.InterpolatingMatrixTreeMap` | `math.interpolation.InterpolatingMatrixTreeMap` |
| `math.MatBuilder` | `math.linalg.MatBuilder` |
| `math.MathShared` | `math.util.MathShared` |
| `math.MathSharedStore` | `math.util.MathSharedStore` |
| `math.MathUtil` | `math.util.MathUtil` |
| `math.Matrix` | `math.linalg.Matrix` |
| `math.Nat` | `math.util.Nat` |
| `math.Num` | `math.util.Num` |
| `math.Pair` | `math.util.Pair` |
| `math.StateSpaceUtil` | `math.util.StateSpaceUtil` |
| `math.VecBuilder` | `math.linalg.VecBuilder` |
| `math.Vector` | `math.linalg.Vector` |
| `math.proto.MatrixProto` | `math.linalg.proto.MatrixProto` |
| `math.proto.VectorProto` | `math.linalg.proto.VectorProto` |
| `math.struct.MatrixStruct` | `math.linalg.struct.MatrixStruct` |
| `math.struct.VectorStruct` | `math.linalg.struct.VectorStruct` |
| `math.system.plant.DCMotor` | `math.system.DCMotor` |
| `math.system.plant.proto.DCMotorProto` | `math.system.proto.DCMotorProto` |
| `math.system.plant.struct.DCMotorStruct` | `math.system.struct.DCMotorStruct` |

**`Nat` is the row a `src/main/java`-only census misses.** It is the only one of the 21 that lives in
the generated source set — `wpimath/src/generated/main/java/edu/wpi/first/math/Nat.java` at
`v2026.2.1`, `wpimath/src/generated/main/java/org/wpilib/math/util/Nat.java` at `alpha-6`. It is a
class robot code imports directly, and a census scoped to hand-written sources reports 20 and calls
it complete.

Two consequences of that table are worth naming separately, because each is a whole class of broken
import rather than one class:

- **No production class sits directly in `org.wpilib.math` at `alpha-6`.** Fifteen production Java
  classes sat directly in `edu.wpi.first.math` in 2026. Fourteen of them are in the table above; the
  fifteenth, `MathUsageId`, is among the 32 with no same-named class at `alpha-6`. None is still at
  the bare root. Said with the source sets in it on purpose: the `test` and `dev` source sets, which
  are outside this basis, *do* hold classes at that bare root at `alpha-6` — `DoubleRange`,
  `MatrixAssertions`, `DevMain` — so a whole-tree grep for the bare root does not come back empty.
- **`edu.wpi.first.math.system.plant` has no `alpha-6` counterpart.** `DCMotor` moved up into
  `math.system`; `LinearSystemId` is one of the 32 keys with no same-named class at `alpha-6`.

**What this method establishes, and what it does not.** It is complete over production Java
source-set/class-basename keys: every 2026 file in `wpimath/src/main/java` or
`wpimath/src/generated/main/java` is classified as kept, moved, or absent, and the three counts sum
to the file total. It cannot see a class renamed as well as moved — that lands in the absent set, and
**the 32 absent keys were not individually resolved**, so do not read this table as an account of
what happened to them. It says nothing about C++, Python, or any test or `dev` source set, and
nothing about members inside a class.

**A basename join invites one specific false positive, and this one was checked.**
`NumericalIntegration` exists at `alpha-6` in **both** `org.wpilib.math.autodiff` and
`org.wpilib.math.system`. Its 2026 home was `edu.wpi.first.math.system`, which still holds a
same-named class, so it is an addition rather than a move and it is **not** in the table above.

**The package-by-package tables above remain pinned to `alpha-6`.** This refresh re-derived the
headline root counts, not a current class/package enumeration. WPIMath had already moved again on
`main@df5a648` — `math.geometry.Ellipse2d` is `math.shape.Ellipse2d` there, for one. At the current
alpha-7/`main@83df3ee` snapshot the refs are identical, but that identity can disappear when `main`
advances. Resolve against the exact ref the team is on.

### Where the 2026 `wpilibj` grab-bag went

In 2026, `edu.wpi.first.wpilibj` held ~75 classes at one level. In 2027 that package **does not
exist**; its contents are distributed across purpose-named packages:

| 2027 package | Holds | Examples at `alpha-6` |
|---|---|---|
| `org.wpilib.framework` | Robot base classes | `TimedRobot`, `RobotBase`, `IterativeRobotBase`, `TimesliceRobot`, `OpModeRobot` |
| `org.wpilib.driverstation` | Driver-station and human-interface | `DriverStation`, `Joystick`, `GenericHID`, `Gamepad`, `Alliance`, `MatchState`, `POVDirection` |
| `org.wpilib.opmode` | Op-mode model (new in 2027) | `OpMode`, `PeriodicOpMode`, `Autonomous`, `Teleop`, `Utility` |
| `org.wpilib.hardware.motor` | Motor controllers | `MotorController`, `PWMMotorController`, `MotorSafety` |
| `org.wpilib.hardware.discrete` | Digital and analog IO | `DigitalInput`, `DigitalOutput`, `AnalogInput`, `PWM`, `CounterBase` |
| `org.wpilib.hardware.rotation` | Encoders and rotational sensors | `Encoder`, `DutyCycleEncoder`, `AnalogEncoder`, `AnalogPotentiometer`, `DutyCycle` |
| `org.wpilib.hardware.bus` | Communication buses | `CAN`, `I2C`, `SerialPort` |
| `org.wpilib.hardware.pneumatic` | Pneumatics | `Solenoid`, `DoubleSolenoid`, `Compressor`, `PneumaticHub`, `PneumaticsControlModule` |
| `org.wpilib.hardware.led` | Addressable LEDs | `AddressableLED`, `AddressableLEDBuffer`, `LEDPattern` |
| `org.wpilib.hardware.power` | Power distribution | `PowerDistribution` |
| `org.wpilib.hardware.imu` | Onboard IMU (new) | `OnboardIMU` |
| `org.wpilib.hardware.expansionhub` | Expansion hub (new) | `ExpansionHub`, `ExpansionHubMotor`, `ExpansionHubServo` |
| `org.wpilib.hardware.accelerometer` | Accelerometers | `ADXL345_I2C`, `AnalogAccelerometer` |
| `org.wpilib.hardware.range` | Range sensors | `SharpIR` |
| `org.wpilib.system` | Runtime and timing | `Timer`, `Notifier`, `RobotController`, `Threads`, `Watchdog`, `Filesystem`, `DataLogManager`, `Tracer`, `SystemServer` |
| `org.wpilib.drive` | Drivetrain helpers | `DifferentialDrive`, `MecanumDrive`, `RobotDriveBase` |
| `org.wpilib.counter` | Counters | `UpDownCounter`, `Tachometer`, `EdgeConfiguration`. **At alpha-7, the package and examples are `org.wpilib.hardware.counter`: `EdgeCounter`, `Tachometer`, `EdgeConfiguration`** (verified against the alpha-7 artifacts 2026-Sep-11) |
| `org.wpilib.event` | Event loop | `BooleanEvent`, `EventLoop`, `NetworkBooleanEvent` |
| `org.wpilib.simulation` | Simulation classes | `DriverStationSim`, `GamepadSim`, `EncoderSim`, `ElevatorSim`, … |
| `org.wpilib.smartdashboard` | Dashboard widgets **only** | `Field2d`, `FieldObject2d`, `Mechanism2d`, `MechanismLigament2d`, `MechanismObject2d`, `MechanismRoot2d`. **`SmartDashboard` and `SendableChooser` are GONE at alpha-7** — replaced by `org.wpilib.telemetry.Telemetry` and `org.wpilib.tunable.Selectable` (alpha-7 release notes; verified against the alpha-7 artifacts 2026-09-09). This table is otherwise alpha-6-pinned, as its header says |
| `org.wpilib.util` | Utilities | `Preferences`. **At alpha-7, the package and example are `org.wpilib.preferences`: `Preferences`** (verified against the alpha-7 artifacts 2026-Sep-11) |
| `org.wpilib.sysid` | SysId | `SysIdRoutineLog` |

**This table is a map, not an inventory.** It names the packages and representative classes. When a
specific class matters, resolve it against the ref the team is on rather than against this table.

---

## Controllers — the change students hit first

*Corrected 2026-08-21.* This section previously mapped `XboxController` to `NiDsXboxController`
unconditionally, and described `Gamepad` as an addition whose relationship to those classes was
unknown. Both were wrong: **which class replaces a 2026 controller depends on which Driver Station
the team runs.** This correction carries its own date, above; the file's `Last verified` stamp does
not date it.

From the official 2027 documentation, *Creating a Test Drivetrain Program*, verbatim:

> "The `Gamepad` class is used with the 2027 FIRST Driver station. If you are using the NI Driver
> station, you will need to use the `NiDsXboxController` class instead."

Source: `https://docs.wpilib.org/en/2027/docs/zero-to-robot/step-4/creating-test-drivetrain-program-cpp-java-python.html`,
fetched 2026-08-21. From the official 2027 changelog, verbatim: *"2027 Alpha 5: Replace individual
gamepad classes (e.g. `XboxController`, `PS4Controller`, `PS5Controller`, `StadiaController`) with a
single `Gamepad` class."* Source:
`https://docs.wpilib.org/en/2027/docs/yearly-overview/yearly-changelog.html`, fetched 2026-08-21.
Both are live pages, not pinned snapshots; `/en/2027/` redirects to `/en/latest/`, and both were
fetched through the `/en/2027/` form this file already cites.

**Every mapping in the table below is carried by one of those two quotations**: the changelog gives
the replacement for all four 2026 classes, and the drivetrain Note gives which Driver Station each
2027 class belongs to. The quotations name classes, not packages — the package each 2027 class sits
in comes from the `alpha-6` tree, where `Gamepad` is in `wpilibj/src/main/java/org/wpilib/driverstation/`
and `NiDsXboxController` in `wpilibj/src/generated/main/java/org/wpilib/driverstation/`. Where the
documentation answers neither question, the cell says so instead of naming a plausible class.

| 2026 (`v2026.2.1`) | 2027 (`alpha-6`), 2027 FIRST Driver Station | 2027 (`alpha-6`), NI Driver Station |
|---|---|---|
| `edu.wpi.first.wpilibj.XboxController` | `org.wpilib.driverstation.Gamepad` | `org.wpilib.driverstation.NiDsXboxController` |
| `edu.wpi.first.wpilibj.PS4Controller` | `org.wpilib.driverstation.Gamepad` | **not established** |
| `edu.wpi.first.wpilibj.PS5Controller` | `org.wpilib.driverstation.Gamepad` | **not established** |
| `edu.wpi.first.wpilibj.StadiaController` | `org.wpilib.driverstation.Gamepad` | **not established** |

**What is deliberately absent from that table, and why.** `org.wpilib.driverstation.NiDsPS4Controller`,
`NiDsPS5Controller` and `NiDsStadiaController` all exist at `alpha-6`, and so do
`org.wpilib.command2.button.CommandGamepad` and the generated `CommandNiDs*Controller` classes.
**Existence is not a mapping.** Nothing found in the documentation says which class replaces
`PS4Controller`, `PS5Controller` or `StadiaController` on the NI Driver Station, or which replaces
`edu.wpi.first.wpilibj2.command.button.CommandXboxController`. A 2027 class whose name parallels a
2026 class name is not evidence that it is that class's replacement, and an earlier revision of this
section published exactly that inference as a mapping row. Those rows are therefore left out rather
than shown with a caveat attached: a mapping table is precisely where a consumer takes the name in
the cell as the answer. `[verify]` — not established. Establish it from documentation before
generating a binding; where it cannot be established, say so and state the alternatives.

**Ask which Driver Station the team runs before choosing a class.** The two 2027 columns name
different classes, and this file has no way to tell which one a team is on. When it cannot be
established, say so and state both — do not pick one.

Two things changed at once, which is why this one bites: the **package** moved *and* the class is a
different class in either column. A generated import that fixes only the package still fails to
resolve.

Whether `org.wpilib.driverstation.Gamepad` is API-compatible with 2026's `XboxController` was
**not** established. `[verify]`

---

## C++

`[verify] — NOT ESTABLISHED.`

The Java package root is verified above. The C++ namespace root for 2027 was **not** checked, and it is
**not** asserted by analogy from the Java change. A C++ team gets "this was not verified" rather than a
plausible guess.

Closing this gap means enumerating the C++ header tree at both refs the same way §"The headline" did
for Java, and recording the result here.

---

## How this table was derived

Recorded so it can be re-run rather than re-reasoned, and so a future maintainer can see the derivation
was mechanical rather than remembered:

```bash
# Whole tree at a ref; assert it is not truncated before trusting it.
tree_state=$(gh api "/repos/wpilibsuite/allwpilib/git/trees/<ref>?recursive=1" --jq '.truncated') \
  || { echo "gh api failed checking tree completeness at <ref>"; exit 1; }
[ "$tree_state" = false ] \
  || { echo "TREE TRUNCATED at <ref> — result would be wrong"; exit 1; }

tree_file='tree-<ref>.txt'
tree_tmp=$(mktemp "${tree_file}.XXXXXX") \
  || { echo "could not create a temporary tree listing for <ref>"; exit 1; }
gh api "/repos/wpilibsuite/allwpilib/git/trees/<ref>?recursive=1" --jq '.tree[].path' > "$tree_tmp" \
  || { echo "gh api failed fetching the tree at <ref>; prior $tree_file was preserved; partial output remains at $tree_tmp"; exit 1; }
mv -- "$tree_tmp" "$tree_file" \
  || { echo "could not replace $tree_file with completed listing $tree_tmp"; exit 1; }

# Package inventory for a ref.
package_inventory=$(set -o pipefail
  grep -aE 'src/main/java/org/wpilib/.*\.java$' "$tree_file" \
    | sed -E 's#.*src/main/java/(org/wpilib[a-zA-Z0-9/]*)/[A-Za-z0-9_]+\.java#\1#' \
    | tr '/' '.' | sort -u
) || { echo "BLOCKED: package inventory pipeline failed or matched no path for <ref>; the inventory did NOT run"; exit 1; }
[ -n "$package_inventory" ] \
  || { echo "BLOCKED: package inventory is empty for <ref>; the inventory did NOT run"; exit 1; }
printf '%s\n' "$package_inventory" \
  || { echo "BLOCKED: package inventory could not be printed for <ref>; the inventory did NOT run"; exit 1; }

# The old-root count that produces the 0 in the headline table. grep -c returns 1 for a valid zero;
# only an exit greater than 1 means the count could not run.
old_root_pattern='^wpilibj/src/main/java/edu/wpi/first/.*\.java$'

# Scope regression fixture: changing old_root_pattern back to the unanchored
# 'java/edu/wpi/first' makes this check match 2 instead of 1.
old_root_scope_fixture() {
  printf '%s\n' \
    'wpilibj/src/main/java/edu/wpi/first/InBasis.java' \
    'unrelated/src/test/java/edu/wpi/first/OutOfBasis.java'
}
old_root_fixture=$(mktemp "${TMPDIR:-/tmp}/wpilib-old-root-scope.XXXXXX") \
  || { echo "BLOCKED: could not create old-root scope fixture; the scope check did not run"; exit 1; }
old_root_scope_fixture > "$old_root_fixture"
fixture_write_status=$?
[ "$fixture_write_status" -eq 0 ] \
  || { echo "BLOCKED: old-root scope fixture producer failed (printf exit $fixture_write_status); the scope check did not run"; exit 1; }
printf 'scope fixture scratch: %s\n' "$old_root_fixture"

fixture_lines=$(awk 'END { print NR }' "$old_root_fixture")
fixture_lines_status=$?
[ "$fixture_lines_status" -eq 0 ] \
  || { echo "BLOCKED: old-root scope fixture line check failed (awk exit $fixture_lines_status); the scope check did not run"; exit 1; }
[ "$fixture_lines" -eq 2 ] \
  || { echo "BLOCKED: old-root scope fixture setup has $fixture_lines lines, expected 2; the scope check did not run"; exit 1; }
for fixture_path in \
  'wpilibj/src/main/java/edu/wpi/first/InBasis.java' \
  'unrelated/src/test/java/edu/wpi/first/OutOfBasis.java'; do
  grep -Fx "$fixture_path" "$old_root_fixture" >/dev/null
  fixture_setup_status=$?
  case "$fixture_setup_status" in
    0) ;;
    1) echo "BLOCKED: old-root scope fixture setup is missing exact path $fixture_path; the scope check did not run"; exit 1 ;;
    *) echo "BLOCKED: old-root scope fixture setup check failed for $fixture_path (grep exit $fixture_setup_status); the scope check did not run"; exit 1 ;;
  esac
done

fixture_count=$(grep -cE "$old_root_pattern" "$old_root_fixture")
fixture_count_status=$?
[ "$fixture_count_status" -le 1 ] \
  || { echo "BLOCKED: old-root scope fixture count failed (grep exit $fixture_count_status); the scope check did not run"; exit 1; }
case "$fixture_count" in
  ''|*[!0-9]*) echo "BLOCKED: old-root scope fixture returned no numeric result; the scope check did not run"; exit 1 ;;
esac
[ "$fixture_count" -eq 1 ] \
  || { echo "BLOCKED: old-root scope fixture matched $fixture_count paths, expected exactly 1; no count was established"; exit 1; }
rm -f -- "$old_root_fixture" \
  || { echo "BLOCKED: old-root scope fixture scratch could not be removed; the derivation did not finish cleanly"; exit 1; }

old_root_count=$(grep -cE "$old_root_pattern" "$tree_file")
old_root_status=$?
[ "$old_root_status" -le 1 ] \
  || { echo "BLOCKED: old-root count failed for $tree_file (grep exit $old_root_status); no count was established"; exit 1; }
case "$old_root_count" in
  ''|*[!0-9]*) echo "BLOCKED: old-root count returned no numeric result for $tree_file; no count was established"; exit 1 ;;
esac
printf '%s\n' "$old_root_count" \
  || { echo "BLOCKED: old-root count could not be printed for $tree_file; no count was established"; exit 1; }

# Not the table's 0. Evidence for the headline's "basis-independent": the broadest basis — any path,
# including directories and every sourceset. A nonzero here with an anchored zero above means an
# old-root path exists OUTSIDE the declared basis and the headline sentence must be re-examined, not
# the table.
basis_independence_count=$(grep -cE '(^|/)edu/wpi/first(/|$)' "$tree_file")
basis_independence_status=$?
[ "$basis_independence_status" -le 1 ] \
  || { echo "BLOCKED: basis-independence check failed for $tree_file (grep exit $basis_independence_status); no count was established"; exit 1; }
case "$basis_independence_count" in
  ''|*[!0-9]*) echo "BLOCKED: basis-independence check returned no numeric result for $tree_file; no count was established"; exit 1 ;;
esac
printf 'basis-independence check (not the table figure): %s\n' "$basis_independence_count" \
  || { echo "BLOCKED: basis-independence check could not be printed for $tree_file; no count was established"; exit 1; }

# The 138 in the headline table. Note the trailing \.java$ — WITHOUT it this counts directory
# entries too and yields 165, not 138. Both figures were re-measured at `83df3ee` on 2026-09-02:
# the .java count moved 139 -> 138 and the directory-inclusive count is still 165. An earlier
# revision of this file separately published a wrong count of 167 under this same header; re-running this exact command does not reproduce that number, so
# 165 should not be read as an explanation of where 167 came from.
new_root_count=$(grep -cE '^wpilibj/src/main/java/org/wpilib/.*\.java$' "$tree_file")
new_root_status=$?
[ "$new_root_status" -le 1 ] \
  || { echo "BLOCKED: new-root count failed for $tree_file (grep exit $new_root_status); no count was established"; exit 1; }
case "$new_root_count" in
  ''|*[!0-9]*) echo "BLOCKED: new-root count returned no numeric result for $tree_file; no count was established"; exit 1 ;;
esac
printf '%s\n' "$new_root_count" \
  || { echo "BLOCKED: new-root count could not be printed for $tree_file; no count was established"; exit 1; }
```

Refs used, current headline figures (2026-09-02):
`wpilibsuite/allwpilib@83df3ee3ce1e892f76970ec21c8efdc00a104d4a` — which is BOTH tag
`v2027.0.0-alpha-7` and `main` at that snapshot.

Refs used, historical figures retained above:
`878da3d54cbc6b64d663bded17d87d5bed040ed9` (tag `v2027.0.0-alpha-6`),
`df5a64806e7bde029afa1b9e4c0d49a9a53da844`, `v2026.2.1@c89401250fbd412ba050f595551d0a451b7307a2`.
