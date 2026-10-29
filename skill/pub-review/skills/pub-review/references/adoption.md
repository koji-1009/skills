# Add — evaluating a package before depending on it

Everything in `SKILL.md` applies.

## Which version

With a project path: evaluate the version the project would actually resolve — run `dart pub add <package> --dry-run -C <project>` (or `flutter pub add`), which reports the resolution without changing anything. If it does not resolve, report that as the SDK-and-constraint finding and evaluate the latest stable, saying so. Without a project path: the latest stable. The resolution result and the package's requirements (`SKILL.md`, *Platform and native requirements imposed on the app*) against the project's declared values go under *Project fit*.

## Gate

If the author gate (`SKILL.md` Step 1) fires, these are still done and nothing else is read: `SKILL.md` Step 1; Step 2's unpack, consumer resolution, and archive-vs-repository comparison (platform implementations are unpacked; of them only read-order steps 1 and 2 are read); the import scan and the inventory without its checkpoint; read-order steps 1 and 2; Classification; and Project fit, reading the build and manifest files listed under *Large packages*. The risk sweep is not run. Every lens and risk category not settled by these is *not checked — gate fired*.

## Read order

Start with the import scan, the dependency inventory, and its checkpoint (`SKILL.md`, *Dependency inventory*), then:

1. **`pubspec.yaml`** — SDK constraint, `flutter.plugin.platforms`, dependencies vs. dev_dependencies.
2. **`lib/<package>.dart`** and every other file under `lib/` outside `lib/src/` — the public export surface. Note what is exported vs. kept in `src/`. Classify the package here (`SKILL.md`, *Classify the package*).
3. **`lib/src/**`** — every `.dart` file under `lib/` not read in step 2, in full, in the package and its own platform implementations (`SKILL.md` Step 2). A dependency's code is read only when the checkpoint approved it, to the depth *On approval* sets.
4. **Risk sweep** (`SKILL.md`).
5. **`test/`** — every file skimmed, with each `group`/`test` description read; bodies are not read. **`example/`** — the example entry file (`example/lib/main.dart`, else `example/main.dart`, else `example/example.dart`, else the single `.dart` file directly under `example/`, else the `lib/main.dart` of each app directly under `example/`, else every `.dart` file directly under `example/`) and every file under `example/` it reaches by `import`, in full; nothing else under `example/`.
6. **`README.md` / `CHANGELOG.md`**, and any other top-level document addressed to developers or AI tools (e.g. `AI_GUIDE.md`) — claims to check against the code; release cadence; breaking-change discipline.
7. **The rest of the risk-sweep scope** (`SKILL.md`, *Risk sweep*) outside `lib/`, in full — interop mechanism, manifest/permission/plist requirements, native library versions, and what runs on the developer's machine.

**Large packages.** Before the checkpoint, measure what steps 3 and 7 would read in full, compiled artifacts (`SKILL.md`, *Reading terms*) excluded. When it is *too large to read in full* (`SKILL.md`, *Reading terms*), the risk sweep, `pubspec.yaml`, the files under `lib/` outside `lib/src/`, `hook/`, and the build and manifest files (`AndroidManifest.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle`, `*.podspec`, `Package.swift`, `CMakeLists.txt`, `Info.plist`, `*.entitlements`, `PrivacyInfo.xcprivacy`, `build.yaml`) remain complete, and the developer-machine entry points — `hook/build.dart`, `hook/link.dart`, each builder factory `build.yaml` names, and the analyzer plugin entry (`lib/main.dart` of a package that depends on `analysis_server_plugin`, or `tools/analyzer_plugin/`) — are read with their reach (`SKILL.md`, *Reading terms*), through `lib/src` included. Steps 3 and 7 then read only the reach of the used symbols, Dart and native alike: the exported symbols the user named at the checkpoint (a feature named by description is mapped to the exported symbols the README documents for it; record the mapping), else those called in the README's first code block that calls the package's API, else those called in the example entry files (step 5) — saying which. A file is *read in full* only when every declaration in it was reached, else *skimmed* with the declarations read; everything else is *not read*.

## Exits

- **Adopt** — depend on the package as-is.
- **Hold it yourself** — solve it without this dependency, either **inline in the app** or **extracted to your own library**. Do not choose between the two; state the facts that bear on the split — the edge cases the package handles, how much of it is reusable, and how entangled it is with lifecycle and platforms. The difficulty the package absorbed estimates the difficulty the user would take on.
- **Skip** — neither adopt nor rebuild (the need isn't real, or an SDK primitive already covers it).

## Comparing several packages

When several packages solve the same problem, evaluate them together. The pub.dev download-sort already names the popular choice, so a comparison is only worth running to surface what that sort hides.

- **Evaluate each candidate independently** — a full reading per package, as deep as a solo evaluation, with its own coverage record. The dependency-inventory checkpoint is one question covering all candidates.
- **Subagents.** If subagents are available, evaluate each candidate in its own subagent and let the parent assemble the cross-cut. Tell each subagent to read `SKILL.md` and this file (give their absolute paths), pass it the Step 0 context (project path or the facts read from it, constraints, trusted publishers), and tell it that Step 0 is already done and it must not ask the user anything. Each subagent returns the single-package format, coverage record included. Subagents cannot run the dependency-inventory checkpoint: tell each to stop after the inventory and return it, run the checkpoint, and continue each subagent with the packages and *Outside pub* dependencies approved for further reading.
- **Gate status.** Per candidate, fired or not; if none fired, say all stand on source.
- **Difference table.** Only the axes that differ, cells anchored to facts/`file:line`.
- **Surface what the download-sort hides.** Name the most-downloaded candidate, and set its highest-strength risk findings and main functionality gaps beside the other candidates' on the same categories — facts side by side, without saying which way they point.
- **Shared risks.** A trap all candidates fall into (e.g. the same stale dependency chain) is stated once, not per package.

## Output formats

### Single package

```markdown
# Evaluation: <package> <version>

## Summary
- Project fit: resolves <yes | no — conflict>; requirements vs. the project <fit | the gaps, see Project fit> | not checked — no project path
- Findings: max <n> · xhigh <n> · high <n> · medium <n> · low <n>
- <strength> — <finding, one line> (`file:line` / field)   ← every finding from medium up, ordered by strength; low findings are counted above and listed in Risk
- Not checked: <lens or category that matters most> — <reason>
- Tension: <main tension, one line>

## Project fit
- Resolves: yes, adding <packages> | no — <conflict> | not checked — no project path
- Requirements imposed on the app — SDK and Flutter floors, platform minimums, permissions and manifest or plist entries, toolchain: <requirement, `file:line`> — <the project's declared value | not declared in the project | not checked — no project path>

## Context
Entry: add · Project: <path or "none (fresh addition)"> · Targets: <list or unknown> · Distribution/license constraint: <given or none> · Defaulted: <Step 0 items the request left open>
Paths: <alias> = <unpacked package or clone>, …   ← short aliases used in `file:line` below

## Gate
Publisher: <publisherId or null> · Gate: fired (scrutiny skipped) | not fired (read the source)

## Classification
Paradigm package | General package — <one line, why it matters here; which source settled it>

## Dependency inventory
- Platform: <count> · Author's own: <count, names> · Third-party: <count, names; unverified publishers marked> · Outside pub: <name version (`file:line`), …> · Already in project: <names> · (read with the package marked in any group)
- Carries: <name: hook | analyzer plugin | builders | devtools | native build (<platforms>) | compiled artifacts>, … | none
- Compiled artifacts: <path sha256 — source: repository <path> | third-party <name> | not found>, … | none
- Checkpoint: <question as asked, delegated-core packages marked> | skipped — nothing to offer | not asked — <reason>; <the question that would have been asked>
- Read in detail (user-approved): <names> | none · Outside pub investigated: <names — what was done> | none

## Functionality & quality
- **<lens>**: <finding with `file:line`>
- Checked — none: <lens (what was read)>, … · Not checked: <lens — reason>, …

## Risk
### <level>   ← one heading per level with findings, highest first; max, xhigh, and high carry the full detail
- **<category>** [<platforms, when not all>] — <finding>
  - evidence: `file:line` / construct / metadata field
  - why it bites: <one or two lines>
  - bites hardest when: <project condition>
### <level>   ← medium and low: one line per finding
- **<category>** [<platforms, when not all>] — <finding> (`file:line` / field)

### No finding
- Checked — none: <category (what was searched)>, …
- Not checked: <category — reason>, …

### Facts without a strength
- **License** — <package license; dependency and vendored licenses> (a `LICENSE` that disagrees with the tag, vendored code under a different license, or, with a distribution/license constraint, a mismatch, is a finding under its level instead)
- **Download base** — <weak signal, one line>

## Tensions
- <functionality-vs-risk divergences; same-observation-two-axes notes>

## Coverage
- Read in full: <files>
- Skimmed: <files; for a large package, each with the declarations read in full>
- Not read: <directories/files, why>
- Not read — compiled: <path, size, sha256>, … | none
- Sweep terms per category: <category: terms>
- Metadata not fetched: <fields, why>
- Run: <date> · Dart <version> · Flutter <version> · archive_sha256 <hash, one per archive read> · repository <url>@<commit> (tag <matched>; one per archive when they differ)

## Hand-off
- Exits: adopt | hold it yourself (inline ↔ extract to library) | skip — with the facts bearing on each.
- How the project's context modulates the risks.
- (No chosen exit. No score.)
```

### Comparison

```markdown
# Comparison: <problem> — <pkg A> / <pkg B> / <pkg C>

## Summary
- Per candidate: <the single-package Summary>

## Context
<as in the single-package format>

## Gate (all candidates)
Per candidate: fired | not fired. If none fired, state that all stand on source.

## <pkg A> <version>
<the full single-package body, coverage included>
[repeat for each candidate, full and independent]

## Differences (relative facts — no ranking)
| axis | <pkg A> | <pkg B> | <pkg C> |
|------|---------|---------|---------|
| scope | … | … | … |
| platform coverage | … | … | … |
| design / reimplementation | … | … | … |
| dependencies | … | … | … |
| license | … | … | … |
| top risk | … | … | … |
| maintenance | … | … | … |
| downloads (weak, no strength) | … | … | … |
(rows = only the axes that differ; cells = facts)

## Shared risks
- <any trap all candidates fall into, stated once>

## What the download-sort hides
- <most-downloaded candidate's highest-strength findings and gaps, beside the others' on the same categories>

## Hand-off
- For each exit, the candidate facts bearing on it; what downloads hide. (No pick. No score.)
```
