# Add — evaluating a package before depending on it

Read after `SKILL.md` Step 0. Everything in `SKILL.md` applies; this file adds the add-specific steps, exits, and output formats.

## Which version

With a project path: evaluate the version the project would actually resolve — run `dart pub add <package> --dry-run -C <project>` (or `flutter pub add`), which reports the resolution without changing anything. If it does not resolve, report that as the SDK-and-constraint finding and evaluate the latest stable, saying so. Without a project path: the latest stable.

## Read order

Start with the import scan, the dependency inventory, and its checkpoint (`SKILL.md`, *Dependency inventory*), then:

1. **`pubspec.yaml`** — SDK constraint, `flutter.plugin.platforms`, dependencies vs. dev_dependencies. Do not count dependencies naively (a near-empty list can be a *symptom* of reimplementing everything).
2. **`lib/<package>.dart`** and every other file directly under `lib/` — the public export surface. Note what is exported vs. kept in `src/`. Classify the package here (`SKILL.md`, *Classify the package*).
3. **`lib/src/**`** — follow paths from the exported API inward. Read in full every file that an exported symbol's implementation passes through, within the package and its own platform implementations (`SKILL.md` Step 2); where the path enters another dependency, it continues only if the checkpoint approved that dependency.
4. **Risk sweep** (`SKILL.md`) across its full add-mode scope.
5. **`test/`** and **`example/`** — what is tested, and how a consumer is expected to use the API.
6. **`README.md` / `CHANGELOG.md`** — claims to check against the code; release cadence; breaking-change discipline.
7. **Plugin platform code, build hooks, builders, and analyzer plugins** (`android/`, `ios/`, `macos/`, `web/`, `windows/`, `linux/`, `hook/`, `src/` native sources, `build.yaml` builders, analyzer plugin code), including endorsed federated implementations (`SKILL.md` Step 2) — interop mechanism, manifest/permission/plist requirements, native library versions, and what runs on the developer's machine.

**Large packages.** When `lib/src`, the native sources, or `example/` are too large to read in full, the risk sweep, `pubspec.yaml`, the export files, the manifests, build files, and permission declarations remain complete. Read fully the implementation behind the exported symbols the user's use case touches, in Dart and in each platform's native code (ask what they will use if unknown; when no one can answer, take the operations the README leads with and name that choice), and list the rest as *not read* in the coverage record.

## Exits

- **Adopt** — depend on the package as-is.
- **Hold it yourself** — solve it without this dependency, either **inline in the app** or **extracted to your own library**. Do not choose between the two; state the facts from the package's own source that bear on the split — the edge cases it handles (lifecycle, gesture-arena handoff, platform differences, decode/resize subtleties), how much of it is reusable, and how entangled it is with lifecycle and platforms. The difficulty the package absorbed estimates the difficulty the user would take on.
- **Skip** — neither adopt nor rebuild (the need isn't real, or an SDK primitive already covers it).

When `isDiscontinued` is true, name `replacedBy` among the facts bearing on the exits.

## Comparing several packages

When several packages solve the same problem, evaluate them together. The pub.dev download-sort already names the popular choice, so a comparison is only worth running to surface what that sort hides.

- **Evaluate each candidate independently** — a full two-axis reading per package, with evidence and its own coverage record. Do **not** let the candidate count dilute per-package depth; the risk reading on each must be as deep as a solo evaluation.
- **Subagents.** If subagents are available, evaluate each candidate in its own subagent and let the parent assemble the cross-cut. Tell each subagent to read `SKILL.md` and this file (give their absolute paths), and pass it the same context: the project path (or the facts read from it: SDK constraint, existing dependencies, target platforms), the distribution/license constraint, and the trusted-author list — and tell it that Step 0 is already done, so it must not ask the operator anything. Each subagent classifies its own package and returns the single-package format in a structured form (it is read by the parent, not a person), coverage record included. Subagents cannot run the dependency-inventory checkpoint: have each return its inventory first, ask the user once for all candidates, then pass each subagent the packages and *Outside pub* dependencies approved for further reading.
- **Gate status.** For each candidate, note whether the gate fired (`publisherId` matched the operator's trusted list → scrutiny skipped) or not (stands on its source). If none matched, say so — all are judged on code. Gate status is a fact about what was read, not a ranking.
- **Difference table — relative facts, not a ranking.** Tabulate only the axes that actually differ, cells anchored to facts/`file:line`. **Never** add a "winner" or "recommended" row.
- **Surface what the download-sort hides.** Name the most-downloaded candidate, and set its highest-strength risk findings and main functionality gaps beside the other candidates' on the same categories — facts side by side, without saying which way they point.
- **Cross-cut only two things:** shared risks (all candidates fall into the same trap — e.g. all depend on the same stale chain — stated once rather than repeated per package) and the difference table.
- **Hand-off:** the pick is the user's. For each exit, state which candidate facts bear on it, and highlight what downloads hide. Do not choose.

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
Entry: add · Project: <path or "none (fresh addition)"> · Targets: <list or unknown> · Distribution/license constraint: <given or none> · Defaulted: <Step 0 items not answered>
Paths: <alias> = <unpacked package or clone>, …   ← short aliases used in `file:line` below

## Gate
Publisher: <publisherId or null> · Gate: fired (scrutiny skipped) | not fired (read the source)

## Classification
Paradigm package | General package — <one line, why it matters here; which source settled it>

## Dependency inventory
- Platform: <count> · Author's own: <count, names; those read with the package marked> · Third-party: <count, names; unverified publishers marked> · Outside pub: <name version (`file:line`), …> · Already in project: <names>
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

### Not found
- Checked — none: <category (what was searched)>, …
- Not checked: <category — reason>, …

### Facts without a strength
- **License** — <package license; dependency and vendored licenses> (with a distribution/license constraint, a mismatch is a finding under its level instead)
- **Download base** — <weak signal, one line>

## Tensions
- <functionality-vs-risk divergences; same-observation-two-axes notes>

## Coverage
- Read in full: <files>
- Skimmed: <files>
- Not read: <directories/files, why>
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
- Per candidate: Findings: max <n> · xhigh <n> · high <n> · medium <n> · low <n> — then its findings from medium up, one line each, with evidence pointers

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
