# Add — evaluating a package before depending on it

Read after `SKILL.md` Step 0. Everything in `SKILL.md` applies; this file adds the add-specific steps, exits, and output formats.

## Which version

With a project path: evaluate the version the project would actually resolve — run `dart pub add <package> --dry-run -C <project>` (or `flutter pub add`), which reports the resolution without changing anything. If it does not resolve, report that as the SDK-and-constraint finding and evaluate the latest stable, saying so. Without a project path: the latest stable.

## Read order

1. **`pubspec.yaml`** — SDK constraint, `flutter.plugin.platforms`, dependencies vs. dev_dependencies. Do not count dependencies naively (a near-empty list can be a *symptom* of reimplementing everything).
2. **`lib/<package>.dart`** and every other file directly under `lib/` — the public export surface. Note what is exported vs. kept in `src/`. Classify the package here (`SKILL.md`, *Classify the package*).
3. **`lib/src/**`** — follow paths from the exported API inward. Read in full every file that an exported symbol's implementation passes through.
4. **Risk sweep** (`SKILL.md`) across all of `lib/`, `hook/`, and platform code.
5. **`test/`** and **`example/`** — what is tested, and how a consumer is expected to use the API.
6. **`README.md` / `CHANGELOG.md`** — claims to check against the code; release cadence; breaking-change discipline.
7. **Plugin platform code and build hooks** (`android/`, `ios/`, `macos/`, `web/`, `windows/`, `linux/`, `hook/`, `src/` native sources) — interop mechanism, manifest/permission/plist requirements, native library versions.

**Large packages.** When `lib/src` is too large to read in full, every step except 3 remains complete; for step 3, read fully the implementation behind the exported symbols the user's use case touches (ask what they will use if unknown), and list the rest as *not read* in the coverage record.

## Exits

- **Adopt** — depend on the package as-is.
- **Hold it yourself** — solve it without this dependency. This splits two ways, and the split is itself a lens-driven judgment:
  - **Inline in the app** — write the code directly where it's used.
  - **Extract to your own library** — when the work has enough fiddly edge cases (lifecycle, gesture-arena handoff, platform differences, decode/resize subtleties) or enough reuse that a reusable, tested unit pays off. A thing you *could* write inline may still deserve a library precisely because the details are easy to get wrong once and good to get right once.

  Drive this with the edge-case granularity, reuse likelihood, and lifecycle/platform entanglement seen in the package's own source — the difficulty it absorbed estimates the difficulty you'd take on.
- **Skip** — neither adopt nor rebuild (the need isn't real, or an SDK primitive already covers it).

When `isDiscontinued` is true, name `replacedBy` among the facts bearing on the exits.

## Comparing several packages

When several packages solve the same problem, evaluate them together. The pub.dev download-sort already names the popular choice, so a comparison is only worth running to surface what that sort hides.

- **Evaluate each candidate independently** — a full two-axis reading per package, with evidence and its own coverage record. Do **not** let the candidate count dilute per-package depth; the risk reading on each must be as deep as a solo evaluation.
- **Subagents.** If subagents are available, evaluate each candidate in its own subagent and let the parent assemble the cross-cut. Tell each subagent to read `SKILL.md` and this file (give their absolute paths), and pass it the same context: the project path (or the facts read from it: SDK constraint, existing dependencies, target platforms), the distribution/license constraint, and the trusted-author list — and tell it that Step 0 is already done, so it must not ask the operator anything. Each subagent classifies its own package and returns the single-package format, coverage record included.
- **Gate status.** For each candidate, note whether the gate fired (publisher or owner matched the operator's trusted list → scrutiny skipped) or not (stands on its source). If none matched, say so — all are judged on code. Gate status is a fact about what was read, not a ranking.
- **Difference table — relative facts, not a ranking.** Tabulate only the axes that actually differ, cells anchored to facts/`file:line`. **Never** add a "winner" or "recommended" row.
- **Surface the download-vs-design-risk conflict.** When the download-sort points to one package but the two-axis reading points elsewhere, state the divergence outright — that divergence is the reason the user ran this skill instead of reading the sort.
- **Cross-cut only two things:** shared risks (all candidates fall into the same trap — e.g. all depend on the same stale chain — stated once rather than repeated per package) and the difference table.
- **Hand-off:** the pick is the user's. For each exit, state which candidate facts bear on it, and highlight what downloads hide. Do not choose.

## Output formats

### Single package

```markdown
# Evaluation: <package> <version>

## Context
Entry: add · Project: <path or "none (fresh addition)"> · Targets: <list or unknown> · Distribution/license constraint: <given or none>

## Gate
Publisher: <publisherId or null> · Repo owner: <handle> · Gate: fired (scrutiny skipped) | not fired (read the source)

## Classification
Paradigm package | General package — <one line, why it matters here; which source settled it>

## Functionality & quality
For each lens:
- **<lens>**: <finding with `file:line`> | checked — none (<what was read>) | not checked (<reason>)

## Risk
For each category:
- **<category>** — strength: severe | high | moderate | low
  - evidence: `file:line` / construct / metadata field
  - why it bites: <one or two lines>
  - bites hardest when: <project condition>
- **<category>** — checked — none (<what was searched>) | not checked (<reason>)

## Tensions
- <functionality-vs-risk divergences; same-observation-two-axes notes>

## Coverage
- Read in full: <files>
- Skimmed: <files>
- Not read: <directories/files, why>
- Metadata not fetched: <fields, why>

## Hand-off
- Exits: adopt | hold it yourself (inline ↔ extract to library) | skip — with the facts bearing on each.
- How the project's context modulates the risks.
- (No chosen exit. No score.)
```

### Comparison

```markdown
# Comparison: <problem> — <pkg A> / <pkg B> / <pkg C>

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
| downloads (weak) | … | … | … |
(rows = only the axes that differ; cells = facts)

## Shared risks
- <any trap all candidates fall into, stated once>

## Download-vs-design-risk conflict
- <if the download-sort's choice differs from the two-axis picture, name the divergence>

## Hand-off
- For each exit, the candidate facts bearing on it; what downloads hide. (No pick. No score.)
```
