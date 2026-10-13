---
name: pub-review
description: >-
  Source-level review of a pub.dev (Flutter/Dart) dependency, handed to the user without a verdict. Two entry points. ADD: vet one package before depending on it, or compare candidates for the same job — "is X any good", "should I use X", "X vs Y", adopt-vs-build. UPDATE: vet moving a package the project already uses from its locked version to a target by reading the diff — "can I bump X to 3.0", "is it safe to upgrade", a dependabot/renovate PR, `pub outdated`, a major-version migration, "what changed between 1.x and 2.x". Reads the actual source (`dart pub unpack`), never likes, downloads, or pub points; produces two independent readings — functionality/quality and risk — with every finding anchored to file:line and a coverage record. Use whenever someone is choosing, vetting, comparing, questioning, or upgrading a Flutter/Dart package, even if they never say "evaluate".
---

# Flutter / Dart package evaluation

## What this is

This skill carries one senior Flutter engineer's axes for judging a library and applies them — at AI speed, against the package's actual source — to whatever package the user is weighing. The output is handed to the user, who makes the decision. The skill lends the engineer's eyes; it does not decide.

It differs from an ordinary "is this package good?" check in four ways:

- It produces **two independent readings**, not one score: **functionality & quality** (what the package solves, and how well) and **risk** (what should make a user cautious about depending on it, *regardless of how good the functionality is*). "The functionality is excellent, but the risk is high" is the most valuable thing it can say — and exactly what a score hides.
- It refuses to emit a verdict. Because the judgment stays with the user, the **depth** of the evaluation becomes visible: the functionality reading is something most models approximate from the README and API, but the **risk reading is where capability shows** — how far a risk is traced, how precisely, with source evidence. Anchoring risk to `file:line` exposes that depth instead of burying it in a number.
- It reports **what it checked and found nothing**, and what it did not read. A silent lens is indistinguishable from an unread one; the coverage record makes depth auditable.
- It has two entry points that share everything below: **add** (one package or several candidates, before depending — `references/adoption.md`) and **update** (a package already in the project, before moving to a newer version — `references/update.md`).

This file holds what both entry points share: stance, context gathering, metadata, source acquisition, the risk sweep, both axes, and tensions. The mode file holds that mode's steps, exits, and output format.

## Stance (non-negotiable)

These are what separate this from a generic checklist. Hold them throughout.

- **Anchor every claim to observable facts.** Cite `file:line`, a concrete construct, or a named metadata field (e.g. `isDiscontinued` from the pub.dev API). Do not fill gaps from your general recollection of how packages like this usually work — if you have not read it, you do not know it. This matters most on the risk axis, where the finding *is* the depth.
- **The two axes are independent, and so are the lenses within each.** A package can be excellent on functionality and high on risk; clean in cohesion and dead in maintenance. Do not average across axes, and do not let a strong reading soften a separate weak one. The **same observation can read as quality on one axis and risk on the other** — that is normal; state it plainly.
- **No thresholds, no proxy metrics.** There is no "minimum downloads", no "≤ N dependencies", no "pub points ≥ X". Popularity and pub points are **not** criteria — a package can hold a perfect points total and tens of thousands of likes and still be a poor dependency; a tightly-built package can have almost no downloads and be exactly right. The most-downloaded package is often the worst.
- **Trust the source over the README.** The README states intent; the code states fact. Where they diverge, the divergence is itself a finding.
- **No verdict.** Do not recommend, rank, pick a winner, score, or tell the user to avoid or choose a package — anywhere, including inside strength labels, tables, or the hand-off. The strength scale below describes consequences, not decisions.
- **Absence is reported, not implied.** Every lens and risk category ends in an explicit state — in an add evaluation: *found* (with evidence), *checked — none* (with what was searched), or *not checked* (with the reason); in an update evaluation, the delta states defined in `references/update.md`. Never omit a category silently, and never report a category as clean on code you did not read.

## Step 0 — Context from the operator (one message, before any fetch)

Ask once, in a single message, covering only what the request and any project path do not already answer, and wait for the reply. Then proceed with defaults for anything left unanswered. The one item without a default is the current version in an update with no project path: if it is still unknown, say the diff cannot be computed without it and stop. A subagent that receives this context from a parent (see *Comparing several packages* in `references/adoption.md`) treats Step 0 as done and does not ask.

1. **Entry point and packages.** Add: which package, or which candidates. Update: which package, its current version (skip if a project path is given — it is in `pubspec.lock`), and the target version (default: latest stable).
2. **Project path** (optional): a directory with `pubspec.yaml`. If given, read from it rather than asking further: the SDK constraint, existing dependencies (`pubspec.yaml`), resolved versions (`pubspec.lock`), and target platforms (the presence of `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`).
3. **Distribution and license constraints** (optional): e.g. closed-source app store distribution, or "no copyleft". Without an answer, report license facts without judging compatibility.
4. **Trusted authors** (optional): *"Any developers you trust enough to skip scrutiny on?"* Identify each as a pub.dev publisher ID (e.g. `dart.dev`) or a repository owner handle — the two things the gate can match against.

Defaults when no project path is supplied: rate every dependency-shaped risk as a fresh addition; treat target platforms as unknown (report the package's support matrix without comparing it); and record every project-dependent check as *not checked — no project path*.

**Then read the mode file now:** add → `references/adoption.md`; update → `references/update.md`. Both continue from Steps 1–2 below.

## Step 1 — Metadata (no source yet)

Fetch these first; they are cheap, and some of them change what follows. Send the header `Accept: application/vnd.pub.v2+json` for the `/api/packages/` endpoints.

- `https://pub.dev/api/packages/<package>` — every version with its `published` timestamp, `retracted` flag, `archive_url`, `archive_sha256`, and pubspec; `isDiscontinued` and `replacedBy` at the top level.
- `https://pub.dev/api/packages/<package>/publisher` — `publisherId` (`null` when uploaded without a verified publisher).
- `https://pub.dev/api/packages/<package>/score` — use only its `tags`: `license:*`, `platform:*`, `sdk:*`, `runtime:*`, `is:wasm-ready`, `is:dart3-compatible`, `is:null-safe`. Ignore points, likes, and download counts except as the weak signal described under *Download base*.
- `https://pub.dev/api/packages/<package>/advisories` — security advisories in OSV format; match the evaluated version against each advisory's `affected[].versions`.
- The repository (from the pubspec's `repository` / `homepage`): with `gh`, read the contributor list, recent commit dates, open/closed issue and PR activity, and release tags.

If a fetch fails (no network, sandbox), record the field as *not checked — <reason>* in the coverage record and continue from source.

**Author gate.** If the `publisherId` or the repository owner matches a trusted author the operator named, the operator's trust permits skipping the source scrutiny — the track record substitutes for it. This skill holds **no list of names**; who qualifies is the operator's call, supplied at runtime (it is also a courtesy not to publish evaluations aimed at named individuals). Default: **do not skip** — the gate fires only on an explicit match; a near-match or an uploader-only match does not fire it. The gate grants only *"need not read"* and never softens a reading: if you do read a gated package, the lenses report exactly what the source shows (a global static is still a global static). Skipping is permitted; flattering is not. Metadata findings (discontinued, advisories, license) are reported for gated packages too — they cost nothing, and the gate is about reading code, not about facts.

## Step 2 — Get the source

Work in a scratch directory outside the user's project: the agent's scratchpad directory if one exists, else `$TMPDIR/pkg-eval`. Below, `<scratch>` stands for that directory. Run each command on its own.

```bash
mkdir -p <scratch>
dart pub unpack <package>@<version> --output=<scratch> --no-resolve
# then resolve dependencies, so the transitive graph exists:
flutter pub get -C <scratch>/<package>-<version>   # package depends on the Flutter SDK
dart pub get -C <scratch>/<package>-<version>      # pure Dart package
dart pub deps --style=compact -C <scratch>/<package>-<version>
```

`--force` overwrites an existing extraction. Omit `@<version>` for the latest stable. Which version(s) to unpack is set by the mode file.

**Archive vs. repository.** For the version being judged (the target, in update mode), clone the repository at the tag matching the version (`git clone --depth 1 --branch <tag> <repo>`) and compare its package directory with the unpacked archive (`diff -r`, excluding `.git`, generated files, and files pub strips). Code present in the archive but absent from the tagged repo is a risk finding (see *Published archive diverges*). If no matching tag exists, record that as a fact. If `dart` or pub.dev is unreachable, the clone becomes the source — and the version match must then be verified from the tag and the pubspec version field.

## Classify the package

Settle one question before judging, because it changes what counts as a defect. Decide it from the pubspec `description`, the README's opening section, and the names and types in the public export file — and cite which of these settled it.

**Is the package's declared purpose to bring a specific paradigm or style** (e.g. functional-programming primitives, reactive primitives), **or is it a general-purpose package** that happens to use one?

- **Paradigm package** — that paradigm on its public API is the promise being kept, not a defect. The user decides separately whether they want it at all.
- **General package** — a foreign paradigm leaking onto the public surface is a risk finding.

## Risk sweep and coverage record

**Risk sweep.** Across the code in scope (all of `lib/`, `hook/`, and platform code when adding; the changed files when updating), search exhaustively — don't sample — for every construct that belongs to these categories: global mutable state; network access and remote code or asset loading; process execution; native library loading; platform-specific imports reachable on other platforms; environment access; generated-code parts. Record the search terms used for each category. Every hit is read in context before it becomes a finding.

**Coverage record.** Keep a running list: files read in full, files skimmed, directories not read, metadata not fetched, and for every lens and risk category its state (see *Absence is reported, not implied*). It goes into the output.

If a metrics tool is available — named by the operator or already installed — (e.g. one computing LCOM4, CBO, or efferent coupling), run it on the source and use its numbers as evidence for the cohesion and coupling lenses, not as a gate.

## Axis 1 — Functionality & quality

What the package solves, and how well. Report each lens against the source, with evidence.

- **Method correctness — the spine.** Does it use the right mechanism, in both directions?
  - Reaches for **native/OS capabilities when it should** (file system, codecs, OS imaging/security stacks, existing native libraries) instead of doing that work in Dart — and conversely stays in pure Dart for work that genuinely completes in Dart (e.g. building a URL string).
  - Chooses the **right interop mechanism**: FFI for C-based stacks, JNI for Android Java/Kotlin, web APIs (`package:web`, `dart:js_interop`) for the browser.
  - **Dart hooks (native assets) — judge the *usage*, not the fact.** Hooks are the current standard way to build and bundle native code, so a hook is **never a risk on its own**. Judge whether the package uses what the SDK versions it supports offer: statically linkable bindings over runtime symbol lookup, tree-shaking of unused native symbols, a lean and pinned native build. Shipping one whole shared library with lookup-table bindings is a quality gap where the SDK floor allowed better. Check current hook capabilities against the docs, not recollection. Where FFI is used, confirm unmanaged resources are released (finalizers or an explicit `dispose`).
  - Spans backends with **deliberate behavioral consistency**, documenting where they diverge rather than pretending uniformity.
  - (The *reimplementation* face of this same spine — rebuilding the SDK or a proven engine instead of using it — is the top item on Axis 2. Same observation, opposite axis.)
- **Platform coverage vs. the project's targets.** Build the support matrix from `flutter.plugin.platforms`, the platform directories, the `platform:*` tags, and conditional imports. For federated plugins, check which platforms have an endorsed implementation and which require a separate package. For web, confirm `is:wasm-ready` in code (legacy web interop or unconditional `dart:io` imports block a Wasm or web build). With a project path, state each project target as *supported / unsupported / partially supported* with evidence.
- **Cohesion & scope.** Do the exported symbols converge on a single, statable responsibility? Cohesion is the LCOM4 intuition: are the pieces connected (shared fields, mutual calls) into one component, or split into unrelated islands? A large package is fine **iff** a unifying purpose ties its parts together — size alone is not the defect, decision-failure is. Public surface should be minimal and judged **separately** from internal size (a large engine can expose a deliberately tiny public API). A disconnected grab-bag tips from a quality concern here into the util-contamination risk on Axis 2.
- **Boundary declaration.** Does it say what it *won't* do? Explicit "for X, write your own / pair with another layer" statements, and typed capability gaps that distinguish a **permanent** platform limit from a **missing-but-installable** one, are the positive form of responsibility-decision.
- **API design.** Is the API straight — a direct mapping from what the library does to what it exposes, not over-broad? Are errors a typed hierarchy, thrown for async operations? A single operation returning a `sealed` Success / Failure / Empty is good design: **one operation, several outcomes** (contrast with *several operations, one return type* on Axis 2). Read `example/` as the author's own consumer: an example that needs workarounds or reaches into `src/` is API-design evidence. Unnecessarily **re-exporting SDK or dependency types** is a minor sign: it ties consumers to those types' version changes.
- **Tests.** What `test/` covers relative to the exported surface and the edge cases the implementation handles (platform branches, error paths, lifecycle). Absent tests for a branch the implementation clearly cares about is a finding; "well-tested" in the README is a claim to check, not evidence.
- **Widget lifecycle & SDK composition** (UI packages). Does it cover the `Widget` lifecycle (`initState`/`dispose`, gesture-arena handoff, `Hero` edge cases) and **compose with SDK primitives** (accept `ImageProvider`, build on `PageView`/slivers) rather than inventing parallel types? Is a custom widget actually necessary, or is the SDK's enough?
- **Accessibility & i18n** (UI packages). Semantics, focus and keyboard handling, and text scaling on custom widgets; hard-coded user-visible strings; RTL and locale-dependent formatting.
- **Resource characteristics (CPU / memory).** Decode-size / resize handling, isolate or `compute` offloading for heavy work (with a default right for the common case), lazy/on-demand construction. Note whether any benchmark or measurement exists in the repo; without one, say the reading is structural. A first-class lens, not a footnote.

## Axis 2 — Risk

What should make a user cautious about depending on the package **regardless of how good the functionality is**. Treat risk as a **strength spectrum**, not a pass/fail gate. The strength describes *the consequence if the risk bites*, combined with *how likely it is to bite in this project's context*:

| strength | consequence if it bites |
|---|---|
| **severe** | The project must remove, replace, or fork the dependency; or the build/legal/security position becomes untenable (unshipped code running in the user's environment, an incompatible license, an unpatched advisory on the resolved version). |
| **high** | Significant unplanned work across the project: dependency-resolution conflicts, workarounds spread through call sites, owning a fork of part of it. |
| **moderate** | Contained cost: a local workaround, a wrapper, a pinned constraint. |
| **low** | Noticeable but cheap, or a burden that is shrinking over time. |

For each finding give: the category, the strength, **evidence** (`file:line`, construct, or metadata field), *why it bites*, and *under what project conditions it bites hardest*. Strength is modulated by the project's context (target platforms, lifespan, existing dependencies) — a bespoke engine is severe for a long-lived product and moderate for a throwaway tool.

**Against the project's dependency graph.** When a project path is supplied, set the strength of dependency-shaped risks against that reality: a dependency the project *already* has adds no increment; a codegen or version constraint that *collides* with what's already pinned (e.g. an `analyzer` ceiling, an SDK lower bound above the project's) is higher; one that fits is lower. This shifts the *strength*, never the *reading* — the dependency is still reported exactly as found.

**Strongest (top of the spectrum — typically severe/high, but still reported with strength and evidence, never as a silent gate):**

- **Reimplementing the SDK or proven infrastructure.** Rebuilding `Navigator`, `MediaQuery`, `Theme`, the reactivity primitive (`ChangeNotifier`/`Listenable`/streams), or the `Widget` lifecycle — or shipping a bespoke engine (a database when SQLite exists). A bus-factor bomb: when the author steps back, no one can maintain a from-scratch foundation, and it tends to detonate exactly then. A near-empty dependency list is often a *symptom* of this. Functionality can be excellent and this still reads severe/high.
- **Global static / rejecting the framework's model.** App-wide navigation/DI/theme/locale routed through global singletons; rejecting Flutter's context/`InheritedWidget` model. In class-based Dart, `static` is exceptional — treat unnecessary static as a competence risk **unless** it is one of two legitimate shapes: (1) a **stateless, idempotent, side-effect-free pure function**; or (2) a **single deliberate replacement hook or inherently process-global resource that *exposes* its injection points** (settable) rather than hiding them. The failing kind hides injection that constructor injection should handle, or holds app state that should be instance/scoped.
- **Utility grab-bag — directly or transitively.** A pile of unrelated helpers with no shared concept; or **depending on one**, especially the author's own personal "utils/helpers" package. The supply-chain risk propagates through the dependency graph, so a clean package that pulls in a junk-drawer inherits it — read the resolved graph from `dart pub deps`, not just the direct list. **But trace propagation only through third-party dependencies the author chose**, and their pinning/hygiene. Platform and first-party packages (the SDKs, and packages from the Dart/Flutter teams' publishers) are outside the author's control; stop at that boundary.
- **Several operations, one return type.** One method returning a union of results from genuinely different operations, the caller discriminating by type to learn what it even did, is a design-judgment signal that makes the whole dependency risky. (Errors stuffed into the return union rather than thrown belong here too.) Contrast the good shape on Axis 1: one operation, several outcomes.
- **Claim–implementation divergence.** The README promises behavior the code does not deliver, or ships subtly-broken "equivalents" sold as drop-in replacements. If the headline value isn't cashed out by the code, you cannot trust the rest of its claims.
- **Published archive diverges from the repository.** Files or code in the pub.dev archive that are absent from (or differ from) the repository at the matching tag. Whatever the cause, the code you would run is not the code anyone reviewed in public.

**Further risks, strength assigned by evidence and context:**

- **Not a risk: using Dart hooks / native builds.** Do **not** add risk for "it has a build hook" or "it compiles native code"; poor usage is an Axis-1 finding. A toolchain the target environment can't provide is a real but low risk.
- **External resources pulled in — at runtime or build time.** A package that reaches outside its own published bytes for code or assets carries supply-chain risk; judge *how* it's done, not the mere fact.
  - **Runtime dynamic code fetch — severe/high.** Code that pulls executable resources at *runtime*: injecting `<script src=…>` from a CDN, loading a remote JS/WASM module via `dart:js_interop`, or fetching a code asset over `HttpClient`/`fetch` (e.g. a renderer that loads `pdf.js` from a CDN at run time). Off-distribution code then runs in the user's environment, bound to that CDN's availability, version, and integrity, breaking under offline/CSP constraints, with the attack surface open at runtime. Mitigated if documented **and** a locally-bundled option is offered.
  - **Build-time unverified fetch — high.** A `hook/` or build script that `git clone`/`curl`/`wget`s an unpinned ref (HEAD/latest) with no commit or hash verification. The build changes over time and upstream tampering flows straight into it.
  - **Build-time pinned fetch — low.** The same fetch, but pinned (fixed commit/tag, hash-verified where possible), re-run only on change (declared as a build dependency), and documented. Often the resource can instead be **added as a compile-time asset** via the build hook rather than fetched at all: treat a runtime fetch that *could* have been a compile-time asset as itself the finding.
- **Security advisories.** Advisories from the `/advisories` endpoint whose `affected[].versions` include the evaluated version. Also bundled native libraries (vendored sources or pinned fetches in `hook/`, `ios/`, `android/`): identify their versions and search for known CVEs against those versions. An advisory fixed only in a version the project cannot resolve is stronger than one fixed in a compatible release.
- **License.** The package's `LICENSE` file and `license:*` tags, plus the licenses of the third-party dependencies the author chose and of any vendored native code. Report the facts always; judge compatibility only against the distribution/license constraint the operator gave. A `LICENSE` that disagrees with the tag, or vendored code under a different license than the package, is itself a finding.
- **SDK and constraint compatibility.** The package's SDK lower bound vs. the project's; upper bounds or pins on shared dependencies that the project resolves differently. With a project path, `dart pub add --dry-run` shows whether it resolves at all — an unresolvable package is reported as such, not evaluated as if it fit.
- **Platform and native requirements imposed on the app.** Android permissions and components merged from the plugin's `AndroidManifest.xml`; `minSdkVersion`/`compileSdk` and iOS/macOS deployment targets; required `Info.plist` usage-description keys; whether the plugin ships a `PrivacyInfo.xcprivacy` privacy manifest when it touches required-reason APIs; Swift Package Manager support vs. CocoaPods-only. These surface at build or store review, not at `pub get`.
- **Maintenance reality.** `isDiscontinued` with `replacedBy` (report the successor by name); retracted versions; a major version stalled in prerelease for years; self-flagging as not production-ready; legacy SDK or interop assumptions past their time; absent semver discipline (breaking changes in minor/patch releases, visible in `CHANGELOG.md` against the code). Judge the *reality* of activity, not the pub.dev score. **Read a stale last-commit date in context, not as a number:** a tiny package on a stable SDK layer (e.g. a `RenderBox`/`RenderSliver` widget) with no recent commits usually reads as *finished*, not abandoned; the same gap on a large, young, or fast-moving package reads as *stalling*. A widely-depended-on package whose whole dependency chain went quiet together is a sharper signal than one stale leaf.
- **Single-maintainer concentration.** The contributor list and who merges/publishes: one person holding all commit and publish rights on a package the project would lean on heavily is a bus-factor risk even without reimplementation. A missing verified publisher (`publisherId: null`) means the package's identity rests on an individual account.
- **Code-generation coupling — only the kind imposed on consumers.** The risk is consumer-time codegen: a package that makes *every consumer* run `build_runner` (`@annotation` + `part '*.g.dart'`, with `build_runner` / `source_gen` / `analyzer` as **regular** dependencies), adding a build step and dragging in tight version constraints — notably `analyzer`'s — that become whole-project dependency-resolution conflicts. **Distinguish author dev-time generation:** a generator used as a **dev_dependency** to produce checked-in output the consumer never regenerates imposes nothing. Check which side of the line the generator sits on before flagging.
- **Download base — a weak signal.** A real user base means edge cases get exercised — more so for widgets than for pure logic. Read it as one weak, easily-overridden question ("have enough real users hit the rough edges?"), **never** as "more is better."

## Tensions

After both axes, state explicitly where they diverge — this is the payload:

- Where **functionality is strong but risk is high** (the case the user most needs named).
- Where the **same observation reads on both axes** (deep native interop = Axis-1 sophistication; if it crossed into reimplementing infrastructure, severe on Axis 2).
- Where a dependency reads as bloat under one lens and correct native interop under another.

Do not resolve tensions into a number. Naming them *is* the value.

## Hand-off (both entry points)

End by naming the exits the mode file lists and, for each, the facts from the reading that bear on it. Summarize how the project's context — target platforms, lifespan, existing dependencies, distribution constraints — modulates the risk strengths. Then stop. **Do not pick an exit, and do not score.** The reading is the deliverable.

The output formats in the mode files fix structure, not wording: headings and labels (strength levels, coverage states, exit names) may be written in whatever language the output is in.

Keep every reading evidence-first and terse. The value is in pointing at the code — especially on the risk axis — not in adjectives.
