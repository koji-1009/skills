# Upgrade — evaluating a move to a newer version

Everything in `SKILL.md` applies.

The question is not "is this package good" but "what changes if the project moves from the current version to the target". Read the **diff**, through both axes.

## Versions

- **Current** = the version in the project's `pubspec.lock`, or the version the user stated when no project path was given. When the lock's entry is not hosted (`source: git` or `path`), the current code is that ref or path: read it from there, not from an unpacked archive of the same version number; the version history starts at the version its pubspec states, and the diff is taken against that tree. If it is still unknown, run `SKILL.md` Step 1, report the package status (discontinued and `replacedBy`, retracted versions, advisories on any version), say the diff cannot be computed without the current version, and stop.
- **Target** = what the user named, else the latest stable.

Unpack both (`SKILL.md` Step 2), each with the platform implementations it selects — the current version's as the project's `pubspec.lock` (else a consumer resolution of it) gives them, the target's from its consumer resolution. The archive-vs-repository comparison applies to the target only — it is the code the project would start running.

## Gate

Run the author gate (`SKILL.md` Step 1) on the `publisherId`. If it fires, steps 1, 5 and 6 are done as written; step 4 is read from the diff of the files directly under `lib/` and the hunks that touch an exported symbol's declaration in `lib/src`, nothing else of the diff; step 9 lists *stops compiling* from step 4 and the requirement changes from the diff of the build and manifest files (`references/adoption.md`, *Large packages*), and records *changes behavior* as *not checked — gate fired*. Steps 2, 3, 7 and 8 are not done. pub.dev exposes one `publisherId`, the package's present one, not one per version; if the identity delta (step 6) shows a change of hands between the two versions, the gate does not fire.

## Steps

1. **Version history.** List every version between current and target with its `published` date, and flag retracted ones. Report any advisory whose `affected[].versions` include the current version — that makes the upgrade a fix, not just a change — and any that include the target.
2. **Source diff.** `diff -r` the two unpacked trees, platform implementations included. *Changed* means added or modified. Read every changed file within the risk-sweep scope (`SKILL.md`) in full in its new form — for a modified file, its old form is the diff hunks — and every deleted file in that scope in full in its old form. Where a hunk's new side names a declaration no hunk touches, read it one level (`SKILL.md`, *Reading terms*). Unchanged files, and files outside the scope, are not read, except that step 9's reach passes through unchanged files skimmed; the coverage record says so. **Large diffs:** when the changed and deleted files in scope are *too large to read in full*, `pubspec.yaml`, the changed files directly under `lib/`, `hook/`, the changed files in the reach of `hook/build.dart` and `hook/link.dart` in the target (`SKILL.md`, *Reading terms*), the build and manifest files (`references/adoption.md`, *Large packages*), and the risk sweep over every changed file in scope remain complete; among changed `lib/src` files, read in full those holding a declaration in the reach of a changed exported symbol (one whose declaration lies in a changed file), read the hit context of those with a risk-sweep hit, and list the rest as *not read*.
3. **Classification.** Classify the target (`SKILL.md`, *Classify the package*). If the diff changes the public export surface, check whether the change introduces or removes a paradigm on it.
4. **Public API delta.** Removed, renamed, or re-typed exported symbols; changed defaults; changed thrown types — each with `file:line` in the target (or the current version, for removals).
5. **Dependency delta.** Compare both pubspecs: added, removed, or re-constrained dependencies; SDK lower-bound changes. With a project path, run `dart pub add <package>@<target> --dry-run -C <project>` (or `flutter pub add`; `dev:<package>@<target>` for a dev dependency, which the plain form moves to `dependencies`) to see what else in the project's graph would move, or whether it resolves at all. Build the dependency inventory (`SKILL.md`) for the target and mark what is added or removed relative to the project's `pubspec.lock` (without a project path, relative to a second consumer resolution of the current version); the checkpoint covers the added non-platform packages and the added *Outside pub* dependencies.
6. **Identity and license delta.** A change of hands is a supply-chain fact to report even when the code looks fine. Sources: the `repository`/`homepage` fields in each version's pubspec (from the versions list in Step 1); the `LICENSE` file in both unpacked trees; and the commit count per author between the two tags (deepen the Step 2 clone with `git fetch --unshallow`, then `git shortlog -s <current tag>..<target tag>`) and the taggers — commit messages and diffs are not read. Report the present `publisherId`, and record the publisher at the current version as *not checked — no per-version source* unless the user supplies it.
7. **Changelog vs. diff.** Check every `CHANGELOG.md` entry between the two versions against the diff. A breaking change in the diff that the changelog omits or labels as minor is a semver-discipline finding; a changelog claim with no corresponding code, or that the code of either version contradicts, is a claim–implementation finding.
8. **Risk delta.** Run the risk sweep (`SKILL.md`) on the changed files, read the Axis 1 lenses and Axis 2 categories against the diff, and give each category not reported under *Package status* one state:
   - **new** — the diff introduces it, or a hunk newly names unchanged code that carries it (step 2; evidence in the target);
   - **resolved** — the diff removes it (evidence in the current version);
   - **carried over** — present in both versions on lines the diff rewrote (evidence in the target);
   - **untouched by the diff** — the changed files were searched and contain nothing bearing on it. This says nothing about whether the risk exists in unchanged code;
   - **not checked** — with the reason.

   Platform and native requirement changes (new permissions, raised `minSdkVersion` or deployment target, new plist keys, privacy-manifest changes) belong here.
9. **Project impact.** With a project path, search the project's source — `lib/`, `bin/`, `test/`, `integration_test/`, in every workspace member or path package that depends on the package — for every import of the package (through a package whose files directly under `lib/` re-export it too) and every symbol the project's code names from it, members accessed on values of package-declared types included. *Stops compiling*: each `path:line` naming a symbol from step 4. *Changes behavior*: each `path:line` naming a symbol whose reach (`SKILL.md`, *Reading terms*) contains the `file:line` of a step 7–8 finding. Set the requirement changes (step 8) against the project's declared values. Traced by reading, never by compiling; say so.

Facts not carried by the diff — `isDiscontinued`/`replacedBy`, a retracted target, maintenance reality, single-maintainer concentration, download base — go under *Package status*, not as deltas; those carrying a strength are counted in the Summary.

## Tensions (in addition to `SKILL.md`)

- Where the upgrade improves one axis and worsens the other (e.g. fixes an advisory but adds consumer-time codegen).

## Exits

- **Upgrade** — move to the target; the touched call sites and dependency moves are the work.
- **Stay pinned** — remain on the current version; the advisories, discontinuation, or SDK drift that accumulate there are the cost.
- **Leave the package** — move to `replacedBy`, another package (an add evaluation, `references/adoption.md`), or hold it yourself.

## Output format

```markdown
# Upgrade: <package> <current> → <target>

## Summary
- Resolves: yes, moving <packages> | no — <conflict> | not checked — no project path
- Project impact: <n> call sites stop compiling, <n> change behavior (traced, not compiled) | not checked — no project path
- Advisories: fixed by the upgrade <ids> | none · on the target <ids> | none
- Findings: max <n> · xhigh <n> · high <n> · medium <n> · low <n>
- <strength> — <new, resolved, carried-over, or package-status finding, one line> (`file:line` / field)   ← every finding from medium up, ordered by strength; low findings are counted above and listed in Risk delta or Package status
- Not checked: <lens or category that matters most> — <reason>
- Tension: <main tension, one line>
- Scope: this reading covers the diff only; risks in unchanged code are not assessed here.

## Project impact
Traced by reading the project's source, not by compiling it.
- Stops compiling: <symbol, `file:line` in the target> — `path:line` in the project, … | none
- Changes behavior: <finding, `file:line` in the target> — `path:line` in the project, … | none
- Requirements vs. the project: <SDK and Flutter floors, platform minimums, toolchain> — <the project's declared value | not declared in the project>
(Without a project path: not checked — no project path.)

## Context
Entry: upgrade · Project: <path or "none"> · Targets: <list or unknown> · Distribution/license constraint: <given or none> · Defaulted: <Step 0 items the request left open>
Paths: <alias> = <unpacked package or clone>, …   ← short aliases used in `file:line` below

## Gate
Publisher: <publisherId or null> · Gate: fired (diff read for steps 4 and 9 only) | not fired

## Package status (not a delta)
- Discontinued: <isDiscontinued; replacedBy> · Target retracted: <yes/no>
- Maintenance, maintainers, download base: <facts about the target, with strength where the category carries one>

## Version history
- <version — published date — retracted?>

## Classification
<target's classification; any paradigm change on the export surface>

## Public API delta
- <removed/renamed/re-typed symbol, changed default or thrown type, `file:line`> | none

## Dependency delta
- <added/removed/re-constrained>; project graph moves from the dry run | not checked — no project path
- Inventory change: added <platform / author's own / third-party / outside pub, names> · removed <names>
- Carries (added packages): <name: hook | analyzer plugin | builders | devtools | native build (<platforms>) | compiled artifacts>, … | none
- Checkpoint: <question as asked> | skipped — nothing added to offer | not asked — <reason>; <the question that would have been asked>
- Read in detail (user-approved): <names> | none · Outside pub investigated: <names — what was done> | none

## Identity and license delta
- <publisher/repo/maintainer/license changes> | none

## Functionality & quality delta
- **<lens>**: <what changed, `file:line`>
- Untouched by the diff: <lenses> · Not checked: <lens — reason>, …

## Risk delta
### <level>   ← one heading per level with findings, highest first; max, xhigh, and high carry the full detail
- **<category>** · <new | resolved | carried over> [<platforms, when not all>] — <finding>
  - evidence, why it bites, bites hardest when
### <level>   ← medium and low: one line per finding
- **<category>** · <new | resolved | carried over> [<platforms, when not all>] — <finding> (`file:line` / field)

### No finding
- Untouched by the diff: <categories>
- Not checked: <category — reason>, …

## Changelog vs. diff
- <omissions, mislabeled breaking changes, unbacked claims> | consistent

## Tensions
- <where the upgrade helps one axis and hurts the other>

## Coverage
- Changed files read: <files>
- Changed files not read: <files, why> | none
- Not read — compiled: <path, size, sha256 old → new>, … | none
- Unchanged declarations read one level because a hunk names them: <file:declaration> | none
- Unchanged areas not re-read: <dirs> · Unchanged files skimmed for step 9's reach: <files> | none
- Sweep terms per category: <category: terms>
- Metadata not fetched: <fields, why>
- Run: <date> · Dart <version> · Flutter <version> · archive_sha256 <hash, one per archive read> · repository <url>@<commit> (tag <matched>; one per archive when they differ)

## Hand-off
- Exits: upgrade | stay pinned | leave the package — with the facts bearing on each.
- How the project's context modulates the risks.
- (No chosen exit. No score.)
```
