Unlabs AI Toolkit for FRC 2027 Season Teams
===========================================

An AI-assisted development toolkit for student programmers in the FIRST® Robotics Competition. It runs
inside Claude Code, works with a team's existing WPILib project, and helps a student turn intended robot
behavior into WPILib 2027-compatible Java code, laptop-based tests, simulation runs, and pre-deployment
evidence. It does not replace WPILib, the Java compiler, Gradle, the WPILib desktop simulator, or a
mentor.

**Documentation and release site:** https://unlabs.co/projects/unlabs-ai-toolkit-frc-2027/
**Start with the web Student Guide:** https://unlabs.co/projects/unlabs-ai-toolkit-frc-2027/student-guide/

**Status: version 1.0.0_Alpha-7.** The version follows WPILib's own pre-release numbering: this release is
built against WPILib 2027.0.0 alpha 7 (`v2027.0.0-alpha-7`), and WPILib has published no 2027 beta. Every
one of the 28 shipped artifacts carries a PASS from an independent adversarial review, recorded with the
artifact's content hash — edit a reviewed file and its review re-opens by itself. **A PASS record is not
product approval:** it establishes that a review was recorded against those exact bytes, not that the
artifact is correct or that a robot is safe. 3 defects are still open and are described in
`docs/LIMITATIONS.md`. Validation is software-in-the-loop only: **no physical robot has been integrated by
this toolkit.**

Start with what the robot must do
---------------------------------

The toolkit uses a behavior-first workflow. Before code is written, the student and the assistant state
what the mechanism must do, what limits apply, how it behaves when idle, how it responds to interruption
or incorrect sensor data, and what evidence will show that it works. The student reviews and approves
those requirements, and the code follows the agreed behavior. The student still makes the engineering
decisions, reviews the work, and verifies its behavior.

Students can work before the robot is available: define behavior, create a subsystem, commands and
autonomous routines, integrate vision, explain inherited code, write laptop-based tests, tune one
closed-loop gain at a time, debug from observed evidence, review code for defects that can stop a robot
from operating, check that code compiles against the project's own WPILib dependencies, and run a
structured pre-deployment validation. The toolkit reads the team conventions stored in the project's
`CLAUDE.md`, so new work follows the team's motor controllers, naming rules and subsystem structure.

---

What the toolkit does for a student, feature by feature
=======================================================

WPILib 2027 is in **alpha**; there is no 2027 beta.

Three things it tries to be, in priority order:

* **Safe** — no committed secret, no over-broad permission grant, and **no safety claim it cannot
  keep**. v1.0 does not gate deploys to a physical robot.
* **Current** — one file absorbs a WPILib release, rather than forty.
* **Honest** — a team knows what it is and is not getting before a competition weekend depends on it.

The things a student feels first
--------------------------------

| # | Feature | What it does | What the student gets | In plain words | Source |
| --- | --- | --- | --- | --- | --- |
| 1 | `/frc-pre-deploy` validation run | Compiles; clears the old test results and runs the tests, counting how many actually executed; launches the simulation; counts compiler warnings; checks the working tree is clean; then writes one verdict file. A run where no test executed cannot be a PASS, and failing tests fail the stage even when Gradle exits zero | One command before a match instead of five, and a written answer that cannot be green on code nothing has exercised | Before a robot goes out to play a match, somebody has to be sure the code actually works. This does the whole check in one go and writes down what it found, including how many tests actually ran in that run. If none ran, the result cannot come back green: a project with no tests gets an explicit "not established" rather than a pass. If tests ran and failed, it fails, even in the case where the build tool reports success anyway. The student doesn't have to remember five separate steps late at night, and the mentor can read the result instead of taking someone's word for it. | `skills/frc-pre-deploy/SKILL.md`, `scripts/run-pre-deploy.sh` |
| 2 | `frc-docs-checker` subagent | Settles whether a WPILib class or import exists by compiling it against the project's own libraries | The assistant stops guessing at names; a wrong import is caught at the desk, not at the field | An AI assistant can produce a name that sounds exactly right and does not exist. Instead of trusting the answer, this builds it against the team's own copy of the robot library to see whether it is real. The student finds out at the desk. That is the whole difference between a confident answer and a checked one. | `agents/frc-docs-checker.md` |
| 3 | The compile probe behind it | A shipped driver and Gradle init script that builds a one-class probe against the real dependency tree | Evidence a student can read, not an opinion: it either compiled or it did not | This is the small program that does that checking. It compiles a single throwaway file against exactly the libraries the team's project uses, and shows the compiler's own output. Nothing is taken on faith, by the student or the assistant. | `baseline/tools/frc-docs-probe.sh`, `.init.gradle` |
| 4 | `current-wpilib-2027` skill | Holds the WPILib 2027 facts the assistant must consult before naming a package, class or Gradle task | Answers that match this season's library instead of last season's tutorials | The robot library changed substantially for this season. This is the assistant's cheat sheet of current facts, and it has to read it before it answers. Answers come from this season's reality rather than from tutorials written two years ago. | `skills/current-wpilib-2027/SKILL.md` |
| 5 | Namespace reference | Maps the 2027 package moves and names that no longer exist | The class a student can't find under its old name gets its current name from a checked map | When the library reorganised itself, a lot of familiar names stopped working. This is the map from the old name to the new one. Instead of hunting through forum posts, the student gets the current name from a map checked against this season's library. | `skills/current-wpilib-2027/references/namespaces.md` |
| 6 | `frc-behavior-first` skill | Makes the assistant state the behaviour, its limits and how you'll know it worked, and agree that before writing code | The student decides what the mechanism should do; the code follows the decision | Before any code is written, the assistant has to say plainly what the mechanism should do, what its limits are, and how you will know it worked, and the student has to agree. That keeps the student in charge of the decision. It also stops pages of code appearing that nobody actually asked for. | `skills/frc-behavior-first/SKILL.md` |
| 7 | `/subsystem` | Scaffolds a subsystem from the team's own hardware details and idle behaviour, and states how it will be simulated | A new mechanism starts from a working file, wired the way the team wires things | A subsystem is one moving part of the robot, such as an arm or an intake. This writes that part's starting code from the team's own hardware details, including what it should do when nothing is asking it to move. A student starts from something that works rather than a blank page. | `commands/subsystem.md` |
| 8 | `/command` | Scaffolds a command class against an existing subsystem, wired to that subsystem's requirements | No more commands that compile but fight each other for the same hardware | A command is one thing the robot does, such as spinning the intake. This writes that action against the part it belongs to and reserves the hardware it needs while it runs. Two actions can no longer grab the same motor at the same time by accident. | `commands/command.md` |
| 9 | `/robot-debug` | Works from evidence to a cause before changing any code | Replaces the change-something-and-see loop that can consume a build night | When something misbehaves, the temptation is to change things until it stops. This works from what was actually observed to the cause, before touching the code. It is aimed at the build nights that are otherwise spent guessing. | `commands/robot-debug.md` |
| 10 | `/robot-review` | Reviews code for the defects that strand a robot on the field | A second read before a match, aimed at the failures that actually cost matches | This is a second read of the code before a match, looking for the faults that leave a robot sitting still while everyone watches. It is the review a team would do if it had an experienced reviewer to spare, which most teams do not. | `commands/robot-review.md` |
| 11 | `/tune` | Runs a closed-loop tuning session one gain at a time and records what each change did | A tuning record the team can repeat, rather than numbers with no recorded reason | Tuning means adjusting numbers until a mechanism moves smoothly instead of slamming or sagging. This changes one number at a time and writes down what each change did. Next season the team can see why the numbers are what they are, rather than starting again from nothing. | `commands/tune.md` |
| 12 | `/test` | Writes tests that run on a laptop with no robot and no network, one named test per condition the agreed behaviour names, then reports a mapping from every condition to its test or to **uncovered**, and refuses to call the work done while a condition is uncovered | Students can work when the robot is in pieces or someone else has it, and a single test cannot stand in for five | Tests here are small automatic checks that run on a laptop, with no robot attached. The student writes one for each thing they said the mechanism should do: the normal case, the limits, a sensor that lies, and what happens when the action is interrupted. At the end it lists each of those conditions against the test that covers it, and says plainly which ones nothing covers yet. Students can keep making progress while the robot is apart, and mistakes get caught before they reach hardware. | `commands/test.md` |
| 13 | `/auto` | Builds an autonomous routine out of commands that already exist, and checks its assumptions | Autonomous stops being a rewrite and becomes a composition | Autonomous is the autonomous period, when the robot runs with nobody driving. This builds that routine out of actions the team has already written, and checks the assumptions it depends on. It turns autonomous into assembly rather than a yearly rewrite. | `commands/auto.md` |
| 14 | `/vision-integrate` | Wires a vision pipeline into a subsystem, handling no-target and bad-target first | The robot behaves when the camera sees nothing, which is most of a match | Cameras lose sight of their target constantly during a match. This connects the camera's output to the robot's code by dealing first with the cases where there is no target or a bad reading. The result is a robot that behaves sensibly most of the time, not only in the moments when the camera has a clean view. | `commands/vision-integrate.md` |
| 15 | `/explain` | Explains a piece of this robot's code in terms of what the robot physically does | A student who inherits code can understand it without the person who wrote it | Code is inherited by students who did not write it and cannot ask the person who did. This explains a piece of code in terms of what the robot physically does when it runs. It is the difference between reading the code and understanding it. | `commands/explain.md` |
| 16 | `/deploy` | Walks the pre-deploy checks and hands the student the deploy command to run themselves | The checks happen in order, and a person still presses the button | Deploying means putting new code onto the robot. This walks the checks in order and then hands the student the command to type themselves. A person stays in control of the moment the robot receives new code. | `commands/deploy.md` |
| 17 | The verdict file | A machine-readable record of what each stage established, including how many tests this run executed and what the run does not prove | A mentor can read the result, and the test count, without re-running anything | The result of the pre-match checks is written down, including what it does not prove. A mentor can read that file instead of re-running everything or trusting a summary. It is a record, so nobody has to argue later about what was checked. | `scripts/run-pre-deploy.sh` |
| 18 | `/deploy` withholds the command | If the verdict is stale, a review is missing or a placeholder is unfilled, it says so and prints nothing | The student finds out before the field, not on it | If the checks are out of date, or the review was skipped, or a placeholder was never filled in, the deploy command is not printed and the reason is stated. The student deals with it at the desk rather than discovering it on the field. It makes a warning something you have to resolve rather than something you scroll past. | `commands/deploy.md`, student guide §6 |
| 19 | Starter `CLAUDE.md` with Team Conventions | A place for the team's motor controllers, naming and subsystem layout, read at the start of every session | The assistant writes code that looks like the team's code | Every team has its own habits: which motor controllers they use, how they name things, how they lay code out. This is where the team writes that down once, and the assistant reads it at the start of every session. New code comes out looking like the team's code rather than like a stranger's. | `templates/CLAUDE.md.template` |
| 20 | Permission rules | 18 deny rules and a five-entry allow list installed with the project | The assistant can build, test and simulate without asking; the denied patterns are refused | The assistant is allowed to do the routine things without stopping to ask, such as building and testing. Anything that matches a deny rule is refused, and anything the rules do not cover falls to the session's permission mode. Students are not interrupted every two minutes. The deny rules match the tool and the text of a command, so a different route to the same file or command is not blocked: `docs/LIMITATIONS.md` and `docs/ARCHITECTURE.md` say so. | `templates/settings.json.template` |
| 21 | Build files protected | Deny rules on `build.gradle`, `gradlew`, `gradle/`, `.wpilib/` and `vendordeps/` | The assistant's editing tool is refused on the files that can block the whole team at once | A handful of files decide how everybody's code gets built. If one is changed carelessly, every student on the team is blocked at once. The assistant's file-editing tool is refused on those files. A shell command can still write them, so changes to them still get a person's review. | same |
| 22 | Secrets protected | Deny rules on `.env`, `.env.*` and `secrets/` for both reading and editing | The assistant's read and edit tools are refused on the usual secrets files | Teams keep private keys for things like scouting data services. The assistant's file-reading and file-editing tools are refused on the usual places those keys are kept. A shell command is not covered by these rules, so keeping keys out of commits still needs the team's own care. | same |
| 23 | Deploy commands denied | Four spellings of the Gradle deploy task are denied in the template | The ordinary deploy command is refused mid-session | The command that pushes code onto the robot is refused in four common spellings. It is a speed bump rather than a gate: a differently spelled invocation is not matched, which the limitations page states. A person runs the deploy deliberately when the team is ready. | same |
| 24 | Managed `.gitignore` block | Adds the ignore rules the toolkit needs, written before anything else | The verdict file and local scratch stay out of the team's commits | Some working files should never be shared with the rest of the team. This sets that up automatically, before anything else is installed. The team's shared history stays clean and nobody has to remember to do it. | `templates/gitignore-fragment.txt` |
| 25 | Session-start update check | At the start of a session, checks whether a newer release exists and says so; for a security release it says to pause and get a mentor | Students stop running a stale copy through a season without knowing | When a student opens a session, the toolkit quietly checks whether a newer version exists and tells them if so. If the newer version is a security fix, it says to stop and fetch a mentor first. Teams no longer run a stale copy for an entire season without realising. | `baseline/tools/frc-version-check.sh` |
| 26 | The installer | One command, idempotent: it never overwrites a file, and lists anything that differs | A team can try it on a branch without touching src/, vendordeps/ or the build files | One command installs everything, and it will not overwrite a file that already exists. If a file already there differs from what it ships, it leaves that file alone and lists it when the run finishes (exit 20). A team can try it on a side branch without putting their project at risk. | `setup/setup-frc-baseline.sh` |
| 27 | Installed-file manifest | A copy, in the project, of the release manifest: every file the toolkit ships, and the release version | The team always knows what they have and where it came from | This is the list of every file the toolkit ships, and which release it is. The team always knows what is installed. It is also what the update check reads to know whether the project is behind. | `.claude/frc-baseline-manifest.yml` |
| 28 | `current-claude-models` skill | The single place model names and effort levels are recorded | Students aren't copying a model name out of a blog post from last year | AI models change names and capabilities often, and stale names spread fast. This is the one place those facts are recorded for the toolkit. Students are not copying a model name out of a blog post from last year. | `skills/current-claude-models/SKILL.md` |
| 29 | Gradle-task and command references | What the 2027 Gradle tasks and command-framework classes are, each pinned to the release it was checked against | `./gradlew` questions get answered from the project, not from memory | These record what this season's build commands and framework pieces are actually called, each noted against the exact release it was checked against. Students get the current answer instead of a plausible one. When something changes, it is clear what was checked and when. | `references/gradle-tasks.md`, `references/commands.md` |
| 30 | Divergence reference | Records where the pinned release and WPILib's development branch differ, and how to re-measure it | Students are told which facts to re-check rather than trusting all of them equally | Sometimes the published release of the robot library and the version being developed disagree. This records where that happens and how to check for yourself. It tells students which facts deserve a second look rather than asking them to trust everything equally. | `references/ref-divergence.md` |
| 31 | Every shipped file reviewed | 28 files, each with an independent review recorded against its exact content | A mentor can see the work was checked, not just claimed | Every one of the 28 files that ships has been through an independent review, recorded against that file's exact contents. If the file changes, the review is automatically marked as needing to be redone. A mentor deciding whether to allow this can see the work rather than a claim about it. | the build repository's review index (not published) |

What comes with it, outside the project folder
----------------------------------------------

| # | Feature | What it does | What the student gets | In plain words | Source |
| --- | --- | --- | --- | --- | --- |
| 32 | Student guide, 43 pages | Install, first session, every command, the permission rules, the pre-match run, and what to do when the assistant is wrong | One document a student can read in an evening and start | A 43-page guide written for the student who writes the code. It covers installing it, a first session from end to end, every command, the rules, and what to do when the assistant gets something wrong. It can be read in an evening, and a student can start work straight after it. | `docs/STUDENT-GUIDE.md` |
| 33 | *FRC 2027 Cycle Guidance*, 546 pages | The season's control-system change: hardware, software, AI and machine learning, development environment, learning pathways, team operations, and what is not yet confirmed | A team can plan the season without assembling it from forum posts | A 546-page guide to this season's change of robot control system, covering the hardware, the software, machine learning on the robot, the tools, the calendar, and what is still unconfirmed. It is the reference a team would otherwise assemble themselves from dozens of separate sources. | the guide |
| 34 | *Claude Code for FRC*, 270 pages | Core robot software, vision and ML pipelines, simulation and controls, a full sample `CLAUDE.md`, setup, slash commands, MCP servers, and what FIRST's policy says about AI-assisted work | The mentor's reference for running this on a team | A 270-page companion on running AI-assisted development on a team: how to set it up, what to standardise, how to handle vision and simulation, and what FIRST's own policy says about students using AI. It is written for the mentor as much as the student. | the companion |
| 35 | Walkthrough recordings | Two recordings, 19:40 and 1:36, following one intake from a sentence to a motor output moving in the simulator, with a full text account | A team can watch the whole loop before installing anything | Two screen recordings, about twenty minutes together, showing one mechanism go from a sentence a student says out loud to a motor value moving in the simulator. Everything in them is also written out with timecodes, so it can be read instead. A team can see exactly what they would be adopting before installing anything. | the walkthrough page |
| 36 | Free for teams | PolyForm Noncommercial for the toolkit, CC BY-NC 4.0 for the guides; commercial use is separately licensed | No budget conversation before a team can try it | Free for teams, schools and nonprofits, and that includes the written guides. Companies that want to build a business on it buy a licence. No budget conversation has to happen before a team can try it. | `LICENSE.md` |
| 37 | Where to get help | Questions in GitHub Discussions, bugs and documentation errors as issues, security reports privately, all tracked in one place | A student knows where to put a problem and that someone sees it | Questions, bug reports and security reports each have a place to go, and all of them land in one tracked system behind the scenes. A student knows where to put a problem and that it will be seen. Help is community-based and best effort, which the documentation states plainly. | `SUPPORT.md`, `SECURITY.md` |
| 38 | Published limitations | `docs/LIMITATIONS.md` states every open defect and standing limitation that reaches a team. (The fuller internal defect register, 62 entries, stays in the build repository; Limitations is its published counterpart.) | A team can see what is broken before they hit it, not after | Most projects tell you what works. This one also publishes what does not, and keeps it current. A mentor can read the known problems before adopting it rather than discovering them on a build night. It is also how a student knows whether an odd behaviour is a known issue or something they caused. | `docs/LIMITATIONS.md`, `release/public-files.txt` |
| 39 | `docs/ARCHITECTURE.md` | How the parts fit together, and what declared versus enforced means | A mentor can judge the design without reading the code | This explains how the pieces work together and, importantly, which things are genuinely enforced by software and which are only instructions the assistant is asked to follow. A mentor deciding whether to allow this can understand the design without reading every file. | `docs/ARCHITECTURE.md` |
| 40 | Changelog that names each artifact | Every release names each file that changed, and if something is withdrawn it names the replacement or says there is none | A team mid-season can decide whether an update is urgent | When a new version comes out mid-season, a team has to decide whether to take it. This names exactly which files changed and what happened to anything removed. The decision stops being a guess, and the safe-looking default of never updating stops being the only option. | `CHANGELOG.md` |
| 41 | Security releases are marked | A release that fixes a security problem carries `[security]` in its title, and the session check tells students to pause for a mentor | The one update a team must not ignore is the one that announces itself | Ordinary updates can wait for a convenient moment. A security fix cannot. Those releases are marked, and the check that runs when a student opens a session tells them to stop and get a mentor rather than carry on. The urgent case is the one that interrupts. | `release/README.md`, `SECURITY.md` |
| 42 | A documented way to update | The README sets out how to move a project to a newer release: run the new installer, delete what it lists, put your own `CLAUDE.md` section back, run it again | Updating is a documented procedure | Updating an installed toolkit is where teams usually lose an evening. The steps are written down and were run end to end: the installer tells you exactly which files differ, you remove the ones you have not customised, and you keep your own team conventions. A mentor can follow it without improvising. | `README.md` |
| 43 | The check can be switched off | Setting `FRC_TOOLKIT_NO_UPDATE_CHECK=1` turns off the session-start check; it also stays silent when it cannot reach GitHub | A pit with no internet is silent, not noisy | At a competition the network is unreliable and nobody wants a tool complaining. The check says nothing when it cannot reach the internet, and a team that does not want it at all can switch it off with one setting. A check that nags on every offline session would be ignored on the day it mattered. | `baseline/tools/frc-version-check.sh` |
| 44 | The licence travels with the project | `COMMERCIAL-LICENSE.md` is installed at the root of the team's project | The terms are where the code is, not on a website somebody has to find | The licence terms are copied into the project itself. A team that inherits a repository next season can see what they are allowed to do with it, without hunting for a web page. | `COMMERCIAL-LICENSE.md` |

---

Install
-------

> **Before you install**
>
> Install it on a branch or a scratch project first and exercise it there. **Keep every review, simulation, physical-test and deployment procedure your team already has** — this toolkit is not designed to replace them, and it cannot stop a bad deploy.

```bash
cd /path/to/your/robot-project   # must be a git repository, at its top level
/path/to/unlabs-ai-toolkit-frc-2027/setup/setup-frc-baseline.sh
```

The scaffold is **idempotent**: every file that already exists is byte-identical when it exits. It
writes nothing inside `src/`, `vendordeps/`, `gradle/`, or the build files.

It installs **one hook**: when a session starts, it checks whether a newer
release of this toolkit exists and, if so, tells the student and asks them to have a mentor update.
A release marked as a security fix says to pause first. Each session start makes at most one request
with a three-second timeout, and successful and failed results are cached per user for 24 hours when
the cache can be written. The check says nothing when it can't reach GitHub and is switched off by
setting `FRC_TOOLKIT_NO_UPDATE_CHECK=1`. The installer never modifies a `settings.json` you already
have; if yours doesn't run the check, the install says so and names the block to copy.

### Updating to a newer release

Run the new release's installer in your project, the same way. It never overwrites a file, so the
first run changes nothing: it lists every installed file that differs from the new release and exits
`20`. Then:

1. Delete each listed file you have not changed yourself.
2. Move `CLAUDE.md` aside, for example to `CLAUDE.md.old`. It is always listed, because its first
   line records the release it came from.
3. Run the installer again. It installs the new copies and a fresh `CLAUDE.md`.
4. Copy your Team Conventions section from `CLAUDE.md.old` into the new `CLAUDE.md`.
5. Review with `git status` and `git diff`, and commit.

A listed file you changed yourself is yours to keep: the installer goes on listing it and exits `20`
for that reason alone. `.claude/settings.json` is never replaced. If the installer says yours does
not run the update check, or the release notes say the settings template changed, merge the change
in by hand from `baseline/templates/settings.json.template`.

**Language: Java only, for now.** v1.0 serves Java teams. The validation drives a Gradle `run` task
and the documentation checker compiles Java against your project's own dependency tree, so neither does anything useful for a C++ or RobotPy project.

**Requirements:** `git`, `bash`, `jq`, and a SHA-256 tool — either `sha256sum` or `shasum`. The
installer exits `14` without one. The shipped permission rules need **Claude Code v2.1.228 or
later**; run `claude --version` and check.

**Platforms:** Linux is tested continuously. macOS is measured, not continuously tested. Git Bash is
the intended route on Windows, and only the installer has run there — on a hosted `windows-latest`
runner. The validation skill, the simulation stage and the documentation checker have not
executed on Windows. There is no PowerShell script. Confirm `bash`, `git`, `jq` and a SHA-256 tool
work before relying on it.

After installing, **fill in the Team conventions section of** `CLAUDE.md`.

---

What is in the box
-------------------

Installing the toolkit puts the following into your robot project. This is the complete list; the
authority on it is `baseline/manifest.yml`.

| Artifact | What it does |
| --- | --- |
| `current-wpilib-2027` | The schema host. Every volatile WPILib fact, each pinned to the ref it was verified against, with four reference files |
| `current-claude-models` | The model-currency schema host |
| `frc-pre-deploy` | Five-stage validation skill. Reports a verdict; **enforces nothing** |
| `frc-behavior-first` | The behaviour-first authoring rules |
| `frc-docs-checker` | Subagent that settles whether a WPILib import or class exists **by compiling it**, through a shipped probe driver. Acceptance-tested end to end; the limits are in `docs/LIMITATIONS.md` |
| The ten commands | `/subsystem` `/command` `/auto` `/robot-debug` `/tune` `/test` `/vision-integrate` `/explain` `/robot-review` `/deploy` |
| Root `CLAUDE.md` template | Toolchain overrides first, safety rules, behaviour-first block |
| Permission + gitignore templates | Ignore rules written before any other file |
| Scaffold | The one executable artifact, with an idempotency test suite |

**Two commands are renamed from the obvious basename, and this is deliberate.** `/debug` is a Claude
Code bundled skill and `/review` is an alias of its `/code-review`, so those files ship as
`robot-debug` and `robot-review`. Whether a project file would shadow a product alias or be shadowed
by it is **not documented** — both outcomes are bad, so the collision is removed rather than
predicted. No command basename may equal a Claude Code command, alias, or bundled skill; the list is
fetched at build time, never baked, and a fetch that fails blocks the build rather than reporting
clean.

`/deploy` must not deploy to a robot. It asks the physical questions a script cannot see, has the team run
the checks, and prints the deploy command for a human to run.

---

Known issues and limitations
-----------------------------

* **There is no deploy guarantee.**
* **Validation is software-in-the-loop only.** No physical robot has been powered by this toolkit.
* **Sustaining work is not in this release.** The v1.1 line — the deploy gate reattempted at a
  different boundary, and the deferred capabilities named in
  `docs/LIMITATIONS.md`.
* **Windows coverage stops at the installer.** A proxy on every push reproduces the line-ending
  conversion a Windows clone performs, and a hosted runner exercises the installer itself; nothing
  past that has run on Windows. See Platforms, above. Whether a standard Git for Windows install
  provides the required `jq` is unverified — if you are on Windows, treat your first install as the
  real test and open an issue either way so we know how it went. We can pick up testing on Windows if there is demand for it.
* **macOS coverage is one machine, one OS version.** See Platforms, above.
* **3 defects remain open**, and two of those three
  affect an installed baseline: the API checker's own control proves the toolchain rather than the
  dependency tree, and the simulation-pattern override flag cannot see a directly edited default, so
  read `sim_ready_pattern` in the verdict yourself, each time it's run. All three are described in
  `docs/LIMITATIONS.md`.

---

How this was verified
----------------------

**Every one of the 28 shipped artifacts carries a PASS from an independent adversarial review.** Each
verdict is recorded against the artifact's content hash, so editing a reviewed file re-opens its
review automatically rather than leaving a stale approval in place. Reviews are run by a reviewer
that did not author the work.

**A green test run is not a review verdict.** The
suites and the check register establish that specified shapes hold; they do not establish that the
product is correct.

---

Documentation
--------------

| Document | What it covers |
| --- | --- |
| `docs/STUDENT-GUIDE.md` | **Start here if you are the one writing robot code** — install, the workflow, and what to do when the assistant is wrong about WPILib |
| `docs/ARCHITECTURE.md` | The three layers, the schema-host pattern, and what *declared* versus *enforced* actually means |
| `docs/LIMITATIONS.md` | **Every open defect and standing limitation, published rather than held back** |
| [Student guide on the web](https://unlabs.co/projects/unlabs-ai-toolkit-frc-2027/student-guide/) | The student guide above as a web page, with a PDF |
| [*FRC 2027 Cycle Guidance*](https://unlabs.co/projects/unlabs-ai-toolkit-frc-2027/guide/) | The season guide this toolkit accompanies: hardware, software, the season calendar, and what is and is not confirmed for 2027. Web and PDF |
| [*Claude Code for FRC*](https://unlabs.co/projects/unlabs-ai-toolkit-frc-2027/companion/) | Its companion volume on using Claude Code on an FRC team. Web and PDF |
| [Walkthrough](https://unlabs.co/projects/unlabs-ai-toolkit-frc-2027/walkthrough/) | Two screen recordings, without audio, that follow one intake from a sentence a student says to a motor output moving in the simulator, with a full text account and timecodes |

---

Support
-------

**Support is community-only.** This project is maintained by one volunteer.

How to ask a question, report a problem, and hear about new releases is in
`SUPPORT.md`. A security problem goes through `SECURITY.md`, never a
public issue.

---

Licensing
---------

**Free for FRC teams, schools, and nonprofits. Paid for commercial use.**

The skills, agents, and subagents in this repository are licensed under the
[PolyForm Noncommercial License 1.0.0](./LICENSE.md). You can read them, use them, change them, and
share them at no cost for any noncommercial purpose.

**You are covered by the free license if you are:**

* a FIRST® Robotics Competition (FRC) team — school-based, booster-run, or a group of students and
  parents, even if you are not formally organized as a nonprofit
* a school, college, or university
* a charitable organization, government body, or public research organization
* an individual learning, tinkering, or experimenting

**You need a commercial license if** you sell a training program, course, or consulting service built
on these skills, or bundle them into a product you charge for, and you are not one of the above.

### Related repositories

| What | License |
| --- | --- |
| Skills, agents, subagents (this repo) | PolyForm Noncommercial 1.0.0 + commercial |
| Robot code samples | MIT |
| [Written guide](https://unlabs.co/projects/unlabs-ai-toolkit-frc-2027/guide/) | CC BY-NC 4.0 |

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
