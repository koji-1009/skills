---
name: pub-review
description: >-
  Evaluate a Flutter or Dart package (or compare several candidates for the same job) before
  depending on it, by reading the package's actual source — not its reputation, likes, downloads, or
  pub points — and producing two independent readings: a functionality/quality assessment and a
  separate risk assessment (bus-factor from reimplementing infrastructure, maintenance decay,
  supply-chain/util contamination, consumer-imposed code generation, global state, external resources
  fetched at runtime or via unpinned build steps). The result is
  handed to the user, who makes the final call. Use this whenever someone is choosing, vetting,
  reviewing, comparing, auditing, or questioning a pub.dev package or a dependency — "is this package
  any good", "should I use X", "X vs Y vs Z", adopt-vs-build — even if they never say "evaluate".
  Pulls source via `dart pub unpack` (or a repo clone) and anchors every finding to file:line.
---

# Flutter / Dart package evaluation

## What this is

This skill carries one senior Flutter engineer's axes for judging a library and applies them — at AI
speed, against the package's actual source — to whatever package the user is weighing. The output is
handed to the user, who makes the adopt / build / skip decision. The skill lends the engineer's eyes;
it does not decide.

It is different from an ordinary "is this package good?" check in three ways:

- It produces **two independent readings**, not one score: **functionality & quality** (what the package
  solves, and how well) and **risk** (what should make a user cautious about depending on it,
  *regardless of how good the functionality is*). "The functionality is excellent, but the risk is high"
  is the most valuable thing it can say — and exactly what a score hides.
- It refuses to emit a verdict. Because the judgment stays with the user, the **depth** of the
  evaluation becomes visible: the functionality reading is something most models approximate from the
  README and API, but the **risk reading is where capability shows** — how far a risk is traced, how
  precisely, with source evidence. Anchoring risk to `file:line` exposes that depth instead of burying
  it in a number.
- It handles **one package or several at once**. For a set of candidates solving the same problem, the
  value is precisely what the pub.dev download-sort hides (see *Comparing several packages*).

## Stance (non-negotiable)

These are what separate this from a generic checklist. Hold them throughout.

- **Anchor every claim to observable code facts.** Cite `file:line` or a concrete construct. Do not
  fill gaps from your general recollection of how packages like this usually work — if you have not
  read it in the source, you do not know it. This matters most on the risk axis, where the finding *is*
  the depth.
- **The two axes are independent, and so are the lenses within each.** A package can be excellent on
  functionality and high on risk; clean in cohesion and dead in maintenance. Do not average across axes,
  and do not let a strong reading soften a separate weak one. The **same observation can read as quality
  on one axis and risk on the other** — that is normal; state it plainly.
- **No thresholds, no proxy metrics.** There is no "minimum downloads", no "≤ N dependencies", no "pub
  points ≥ X". Popularity and pub points are **not** criteria — a package can hold a perfect points total
  and tens of thousands of likes and still be a poor dependency; a tightly-built package can have almost
  no downloads and be exactly right. The most-downloaded package is often the worst.
- **Trust the source over the README.** The README states intent; the code states fact. Where they
  diverge, the divergence is itself a finding.

## Get the source

Work in a scratch directory so nothing touches the user's project.

```bash
mkdir -p /tmp/pkg-eval && cd /tmp/pkg-eval
dart pub unpack <package>            # extracts to ./<package>-<version>/ (latest stable)
dart pub unpack <package>:<version>  # a specific version (e.g. a stalled prerelease)
# Flags: --output=<dir> to choose where; --no-resolve for source-only (skip the auto `pub get`);
#        --force to overwrite an existing extraction.
```

If `dart` or pub.dev egress is unavailable (some sandboxes), fetch the published source straight from
the repository instead: `git clone --depth 1 <repo>` (the repo URL is in `pubspec.yaml` / on the
pub.dev page). The download mechanism is incidental; reading the real source is the point. Verify the
cloned ref matches the version under evaluation — a repo's HEAD can be ahead of the published release.

Read in roughly this order:

1. **`pubspec.yaml`** — SDK constraints, supported platforms, version, dependencies. Do not count
   dependencies naively (a near-empty list can be a *symptom* of reimplementing everything — read it
   with the method-correctness lens).
2. **`lib/<package>.dart`** — the public export surface; what consumers actually touch. Note what is
   exported vs. kept in `src/`.
3. **`lib/src/**`** — the implementation: static usage, cohesion, native interop, API shape, lifecycle.
4. **`README.md` / `CHANGELOG.md`** — stated purpose and claims (to check against the code), release
   cadence, breaking-change discipline.
5. **Plugin platform code / build hooks** (`android/`, `ios/`, …, `hook/`) — how the Dart side reaches
   native (platform channels vs. FFI vs. JNI vs. web APIs vs. Dart-hook native assets).
6. **pub.dev / the repo** — for maintenance *reality*: last publish, a major version stalled in
   prerelease, how issues are handled. Activity facts, not the score.

If a Dart metrics tool that computes LCOM4 / CBO / efferent coupling is available, run it on the source
to anchor the cohesion and coupling readings in numbers. Treat its output as evidence for a lens, not a
gate.

## Classify the package (do this first)

Settle one question before judging, because it changes what counts as a defect:

**Is the package's declared purpose to bring a specific paradigm or style** (e.g. functional-programming
primitives), **or is it a general-purpose package** that happens to use one?

- **Paradigm package** — that paradigm on its public API (functional result types, reactive primitives)
  is the promise being kept, not a defect. The user decides separately whether they want it at all.
- **General package** — a foreign paradigm leaking onto the public surface is a risk finding.

## Gate: the author (zero cost, before reading code)

If the package is authored by someone the operator recognizes as having created widely-adopted paradigms
or infrastructure in this ecosystem, the operator may **skip the source scrutiny entirely** — the track
record substitutes for it.

This skill holds **no list of names.** Who qualifies is the operator's call, supplied at runtime, and it
changes over time (it is also a courtesy not to publish evaluations aimed at named individuals). Default:
**do not skip** — the gate fires only on an explicit operator signal; when in doubt, read.

**Get the roster from the user, in conversation, before evaluating** (kept conversational rather than a
config file, to keep the skill stateless): *"Any developers you trust enough to skip scrutiny on? (optional)"*
If they name some (e.g. the ecosystem's core authors, or their own packages), those authors' packages are
gate-eligible. If they name none, fall through to the default — read every package on its source.

Keep the gate distinct from the risk axis: the gate is a shortcut taken *before* reading. A finding like
"this reimplements a database engine, a bus-factor risk regardless of how well it works" is a *product
of* reading and belongs in the risk axis. And the gate only grants *"need not read"* — it never softens
a reading: if you do read a trusted author's package, the lenses report exactly what the source shows
(a global static is still a global static). Skipping is permitted; flattering is not.

## Axis 1 — Functionality & quality

What the package solves, and how well. Report each lens against the source, with evidence.

- **Method correctness — the spine.** Does it use the right mechanism, in both directions?
  - Reaches for **native/OS capabilities when it should** (file system, codecs, OS imaging/security
    stacks, existing native libraries) instead of doing that work in Dart — and conversely stays in pure
    Dart for work that genuinely completes in Dart (e.g. building a URL string).
  - Chooses the **right interop mechanism**: FFI for C-based stacks, JNI for Android Java/Kotlin, web
    APIs for the browser.
  - **Dart hooks (native assets) — judge the *usage*, not the fact.** Build hooks are standard from Dart
    3.10+ and build Android native code through the NDK directly, with no AGP/Gradle, so a hook is the
    forward-looking, recommended approach — **never a risk on its own**. Good usage looks like:
    `@ffi.Native` bindings (statically linkable) rather than a runtime `DynamicLibrary.lookup` symbol
    table; **both a build hook and a link hook** (build emits static archives with `StaticLinking()`
    routed `ToLinkHook`; the link hook tree-shakes via `CLinker` + `LinkerOptions.treeshake(symbolsToKeep:)`
    so only referenced symbols ship — this is where the binary-size win is) with a `DynamicLoadingBundled()`
    fallback when linking is unavailable; the tree-shake keep-list **auto-generated from the bindings** so
    it can't drift; Android via the NDK in the hook (ABI, STL, 16 KB page support); per-target toolchain
    config; and a **lean, pinned** native build. Merely compiling the whole native library and shipping
    one shared object — no link hook, no tree-shaking, lookup-table bindings — is a lower bar even if it
    works; that gap is a quality finding here. And where FFI is used, check release discipline for
    unmanaged resources — C allocations paired with `free` via `NativeFinalizer` or an explicit `dispose`,
    and correct autorelease/ARC handling across an Objective-C bridge; this is niche, so confirm it's
    handled and defer the platform specifics to the agent's knowledge or a search rather than spelling
    them out here.
  - Spans backends with **deliberate behavioral consistency**, documenting where they diverge rather than
    pretending uniformity.
  - (The *reimplementation* face of this same spine — rebuilding the SDK or a proven engine instead of
    using it — is the top item on Axis 2. Same observation, opposite axis.)
- **Cohesion & scope.** Do the exported symbols converge on a single, statable responsibility? Cohesion
  is the LCOM4 intuition: are the pieces connected (shared fields, mutual calls) into one component, or
  split into unrelated islands? A large package is fine **iff** a unifying purpose ties its parts together
  — size alone is not the defect, decision-failure is. Public surface should be minimal and judged
  **separately** from internal size (a large engine can expose a deliberately tiny public API). A
  disconnected grab-bag tips from a quality concern here into the util-contamination risk on Axis 2.
- **Boundary declaration.** Does it say what it *won't* do? Explicit "for X, write your own / pair with
  another layer" statements, and typed capability gaps that distinguish a **permanent** platform limit
  from a **missing-but-installable** one, are the positive form of responsibility-decision.
- **API design.** Is the API straight — a direct mapping from what the library does to what it exposes,
  not over-broad? Are errors a typed hierarchy, thrown for async operations? A single operation returning
  a `sealed` Success / Failure / Empty is good design (one operation, several outcomes). Minor notice:
  unnecessarily **re-exporting Flutter/Dart SDK or dependency types** from the public surface is a yellow
  sign — it can break consumers on those SDK/dependency version bumps and bleeds others' types into the
  caller; low priority, but worth flagging.
- **Widget lifecycle & SDK composition** (UI packages). Does it cover the `Widget` lifecycle
  (`initState`/`dispose`, gesture-arena handoff, `Hero` edge cases) and **compose with SDK primitives**
  (accept `ImageProvider`, build on `PageView`/slivers) rather than inventing parallel types? Is a custom
  widget actually necessary, or is the SDK's enough?
- **Resource characteristics (CPU / memory).** Decode-size / resize handling, isolate or `compute`
  offloading for heavy work (with a default right for the common case), lazy/on-demand construction. A
  first-class lens, not a footnote.

## Axis 2 — Risk

What should make a user cautious about adopting the package **regardless of how good the functionality
is**. Treat risk as a **strength spectrum**, not a pass/fail gate:

> **avoid** · **high** · **moderate** · **low**

For each finding give: the category, a strength rating, **`file:line` evidence**, *why it bites*, and
*under what project conditions it bites hardest*. Strength is modulated by the project's context (target
platforms, lifespan, existing dependencies) — a bespoke engine is severe for a long-lived product and
mild for a throwaway tool.

If the user supplies the target project's **existing dependency graph** (optional — ask, or read its
`pubspec.yaml` if pointed at it), use it to set the strength of dependency-shaped risks against that
reality rather than against a blank slate: a dependency the project *already* has adds no increment (a
candidate that pulls in a package the project already uses is neutral, not a cost); a codegen or version
constraint that *collides* with what's already pinned (e.g. an `analyzer` ceiling) is higher; one that
fits is lower. With no graph supplied, rate as if the candidate is a fresh addition. This shifts the
*strength*, never the *reading* — the dependency is still reported exactly as found — and it never
becomes a verdict: report the contextualized strength and leave adopt/skip to the user.

**Strongest (top of the spectrum — typically avoid/high, but still reported with strength and evidence,
never as a silent gate):**

- **Reimplementing the SDK or proven infrastructure.** Rebuilding `Navigator`, `MediaQuery`, `Theme`, the
  reactivity primitive (`ChangeNotifier`/`Listenable`/streams), or the `Widget` lifecycle — or shipping a
  bespoke engine (a database when SQLite exists). A bus-factor bomb: when the author steps back, no one can
  maintain a from-scratch foundation, and it tends to detonate exactly then. A near-empty dependency list
  is often a *symptom* of this. Functionality can be excellent and this still reads avoid/high.
- **Global static / rejecting the framework's model.** App-wide navigation/DI/theme/locale routed through
  global singletons; rejecting Flutter's context/`InheritedWidget` model. In class-based Dart, `static` is
  exceptional — treat unnecessary static as a competence risk **unless** it is one of two legitimate shapes:
  (1) a **stateless, idempotent, side-effect-free pure function**; or (2) a **single deliberate replacement
  hook or inherently process-global resource that *exposes* its injection points** (settable) rather than
  hiding them. The failing kind hides injection that constructor injection should handle, or holds app
  state that should be instance/scoped.
- **Utility grab-bag — directly or transitively.** A pile of unrelated helpers with no shared concept; or
  **depending on one**, especially the author's own personal "utils/helpers" package. The supply-chain
  risk propagates through the dependency graph, so a clean package that pulls in a junk-drawer inherits it.
- **Cramming unrelated operations into one return type (pattern B).** One method returning a union of
  results from genuinely different operations, the caller discriminating by type to learn what it even did,
  is a design-judgment signal that makes the whole dependency risky. (Errors stuffed into the return union
  rather than thrown belong here too.)
- **Claim–implementation divergence.** The README promises behavior the code does not deliver, or ships
  subtly-broken "equivalents" sold as drop-in replacements. If the headline value isn't cashed out by the
  code, you cannot trust the rest of its claims.

**Further risks, strength assigned by evidence and context:**

- **Not a risk: using Dart hooks / native builds.** Build hooks (native assets) are standard from Dart
  3.10+ and build native code — including Android, through the NDK with no AGP/Gradle — the recommended
  way. Do **not** add risk for "it has a build hook" or "it compiles native code." Poor *usage* (no link
  hook / no tree-shaking / lookup-table bindings) is an Axis-1 quality finding, not a risk. A genuine
  toolchain burden (needs CMake/NDK a target environment can't provide) is real but **low-and-shrinking**
  as hooks become the norm.
- **External resources pulled in — at runtime or build time.** A package that reaches outside its own
  published bytes for code or assets carries supply-chain risk; as with hooks, judge *how* it's done, not
  the mere fact. Two faces, three strengths:
  - **Runtime dynamic code fetch — heaviest, avoid/high.** Code that pulls executable resources at
    *runtime*: injecting `<script src=…>` from a CDN, loading a remote JS/WASM module via
    `dart:js`/`dart:js_interop`, or fetching a code asset over `HttpClient`/`fetch` (e.g. a renderer that
    loads `pdf.js` from a CDN at run time). Off-distribution code then runs in the user's environment,
    bound to that CDN's availability, version, and integrity, breaking under offline/CSP constraints, with
    the attack surface open at runtime. Mitigated if documented **and** a locally-bundled option is
    offered. Detect: `<script src=` injection, CDN URL strings, remote-module loads, or code fetched over
    HTTP anywhere in `lib/`.
  - **Build-time unverified fetch — high.** A `hook/` or build script that `git clone`/`curl`/`wget`s an
    unpinned ref (HEAD/latest) with no commit or hash verification. The build changes over time and
    upstream tampering flows straight into it.
  - **Build-time pinned fetch — low.** The same fetch, but pinned (fixed commit/tag, hash-verified where
    possible), re-run only on change (declared as a build dependency), and documented — correct build
    hygiene, not a defect. And often the resource can instead be **added as a compile-time asset** via the
    build hook rather than fetched at all: prefer that where it applies, and treat a runtime fetch that
    *could* have been a compile-time asset as itself the finding.
- **Maintenance reality.** A major version stalled in prerelease for years; self-flagging as not
  production-ready; legacy SDK or interop assumptions past their time; absent semver discipline. Judge the
  *reality* of activity, not the pub.dev score. **Read a stale last-commit date in context, not as a
  number:** a tiny package on a stable SDK layer (e.g. a `RenderBox`/`RenderSliver` widget) with no recent
  commits usually reads as *finished*, not abandoned — there is nothing to change; the same gap on a large,
  young, or fast-moving package reads as *stalling*. Size and the stability of what it builds on modulate
  what "old" means. A widely-depended-on package whose whole dependency chain went quiet together is a
  sharper signal than one stale leaf.
- **Code-generation coupling — only the kind imposed on consumers.** The risk is consumer-time codegen: a
  package that makes *every consumer* run `build_runner` (`@annotation` + `part '*.g.dart'`, with
  `build_runner` / `source_gen` / `analyzer` as **regular** dependencies), adding a build step and dragging
  in tight version constraints — notably `analyzer`'s — that become whole-project dependency-resolution
  conflicts. **Distinguish author dev-time generation:** a generator used as a **dev_dependency** to produce
  checked-in output the consumer never regenerates imposes nothing. Check which side of the line the
  generator sits on before flagging.
- **Download base — a weak signal.** A real user base means edge cases get exercised — more so for widgets
  than for pure logic. Read it as one weak, easily-overridden question ("have enough real users hit the
  rough edges?"), **never** as "more is better."

## Tensions

After both axes, state explicitly where they diverge — this is the payload:

- Where **functionality is strong but risk is high** (the case the user most needs named).
- Where the **same observation reads on both axes** (deep native interop = Axis-1 sophistication; if it
  crossed into reimplementing infrastructure, avoid on Axis 2).
- Where a dependency reads as bloat under one lens and correct native interop under another.

Do not resolve tensions into a number. Naming them *is* the value.

## Exit & hand-off

End by handing the decision to the user. The exits:

- **Adopt** — depend on the package as-is.
- **Hold it yourself** — solve it without this dependency. This splits two ways, and the split is itself a
  lens-driven judgment:
  - **Inline in the app** — write the code directly where it's used.
  - **Extract to your own library** — when the work has enough fiddly edge cases (lifecycle, gesture-arena
    handoff, platform differences, decode/resize subtleties) or enough reuse that a reusable, tested unit
    pays off. A thing you *could* write inline may still deserve a library precisely because the details
    are easy to get wrong once and good to get right once.
  Drive this with the edge-case granularity, reuse likelihood, and lifecycle/platform entanglement seen in
  the package's own source — the difficulty it absorbed estimates the difficulty you'd take on.
- **Skip** — neither adopt nor rebuild (the need isn't real, or an SDK primitive already covers it).

Summarize how the project's context — target platforms, lifespan, existing dependencies — modulates the
risk strengths. Then stop. **Do not pick an exit, and do not score.** The reading is the deliverable.

## Comparing several packages

When several packages solve the same problem, evaluate them together. This is exactly the case where the
skill earns its keep: the pub.dev download-sort already names the popular choice, so a comparison is only
worth running to surface what that sort hides.

- **Evaluate each candidate independently** — a full two-axis reading per package, with `file:line`
  evidence. Do **not** let the candidate count dilute per-package depth; the risk reading on each must be
  as deep as a solo evaluation. (If running in an agent with subagents, evaluate each in its own subagent
  and let the parent assemble the cross-cut, to protect depth.)
- **Gate-derived recommend/not.** For each candidate, note whether the gate fired (author in the operator's
  trusted set → recommendable on reputation, scrutiny optional) or not (stands on its source). If none are
  gated, say so — none gets a reputation pass; all are judged on code.
- **Difference table — relative facts, not a ranking.** Tabulate only the axes that actually differ, cells
  anchored to facts/`file:line`. **Never** add a "winner" or "recommended" row, and never say "pick B"; a
  ranking is a baked verdict and reintroduces the un-weighted checklist this skill avoids.
- **Surface the download-vs-design-risk conflict.** When the download-sort points to one package but the
  two-axis reading points elsewhere, state the divergence outright — that divergence is the reason the user
  ran this skill instead of reading the sort.
- **Cross-cut only two things:** shared risks (all candidates fall into the same trap — e.g. all depend on
  the same stale chain — stated once rather than repeated per package) and the difference table.
- **Hand-off:** the pick is the loop's. Tie the exits to what the user needs, and highlight what downloads
  hide. Do not choose.

## Output formats

### Single package

```markdown
# Evaluation: <package> <version>

## Classification
Paradigm package | General package — <one line, why it matters here>

## Gate
Operator-supplied: trusted author (scrutiny skipped) | not gated (read the source)

## Functionality & quality
For each lens with something to say:
- **<lens>**: <what it solves / how well>, anchored to `file:line` or a named construct.

## Risk
For each finding:
- **<category>** — strength: avoid|high|moderate|low
  - evidence: `file:line` / concrete construct
  - why it bites: <one or two lines>
  - bites hardest when: <project condition>

## Tensions
- <functionality-vs-risk divergences; same-observation-two-axes notes>

## Hand-off
- Exits: adopt | hold it yourself (inline ↔ extract to library) | skip — with the inline-vs-library
  reasoning if "hold it yourself" is live.
- How the project's context modulates the risks.
- (No chosen exit. No score.)
```

### Comparison

```markdown
# Comparison: <problem> — <pkg A> / <pkg B> / <pkg C>

## Gate (all candidates)
Per candidate: gated (reputation pass) | not gated. If none, state that all stand on source.

## <pkg A> <version>
- **Functionality & quality**: <lenses, evidence>
- **Risk**: <findings with strength + file:line + why-it-bites>
[repeat for each candidate, full and independent]

## Differences (relative facts — no ranking)
| axis | <pkg A> | <pkg B> | <pkg C> |
|------|---------|---------|---------|
| scope | … | … | … |
| design / reimplementation | … | … | … |
| dependencies | … | … | … |
| top risk | … | … | … |
| maintenance | … | … | … |
| downloads (weak) | … | … | … |
(rows = only the axes that differ; cells = facts)

## Shared risks
- <any trap all candidates fall into, stated once>

## Download-vs-design-risk conflict
- <if the download-sort's choice differs from the two-axis picture, name the divergence>

## Hand-off
- Tie exits to what the user needs; highlight what downloads hide. (No pick. No score.)
```

Keep every reading evidence-first and terse. The value is in pointing at the code — especially on the
risk axis — not in adjectives.
