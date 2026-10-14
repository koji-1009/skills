# Update — evaluating a move to a newer version

Read after `SKILL.md` Step 0. Everything in `SKILL.md` applies; this file adds the update-specific steps, exits, and output format.

The question is not "is this package good" but "what changes if the project moves from the current version to the target". Read the **diff**, through both axes.

## Versions

- **Current** = the version in the project's `pubspec.lock`, or the version the operator stated when no project path was given.
- **Target** = what the operator named, else the latest stable.

Unpack both (`SKILL.md` Step 2). The archive-vs-repository comparison applies to the target only — it is the code the project would start running.

## Gate

Run the author gate (`SKILL.md` Step 1) on the `publisherId`. If it fires, the diff reading may be skipped; steps 1, 4, 5 and 6 below are still reported, because they are metadata and project facts the user needs to move. pub.dev exposes only the current `publisherId`, so the gate cannot show who published the target; if the identity delta (step 6) shows a change of hands between the two versions, the gate does not fire.

## Steps

1. **Version history.** List every version between current and target with its `published` date, and flag retracted ones. Report any advisory whose `affected[].versions` include the current version — that makes the upgrade a fix, not just a change — and any that include the target. Report package-level status — `isDiscontinued`/`replacedBy`, whether the target is retracted, `publisherId` — as facts in their own section, not as deltas.
2. **Source diff.** `diff -r` the two unpacked trees. Read every changed file within the risk-sweep scope (`SKILL.md`) in its new form, and every deleted file in its old form. Where a changed line newly calls into unchanged code, read the called code too. Unchanged areas get no new reading; the coverage record says so. **Large diffs:** `pubspec.yaml`, the changed export files directly under `lib/`, `hook/`, platform directories, and the risk sweep over all changed files remain complete; among changed `lib/src` files, read fully those on paths from changed exported symbols and those with risk-sweep hits, and list the rest as *not read*.
3. **Classification.** Classify the target (`SKILL.md`, *Classify the package*). If the diff changes the public export surface, check whether the change introduces or removes a paradigm on it.
4. **Public API delta.** Removed, renamed, or re-typed exported symbols; changed defaults; changed thrown types — each with `file:line` in the target (or the current version, for removals). With a project path, search the project's own source for the imports and symbols affected and list each call site the upgrade touches with `file:line` in the project — both those that stop compiling and those whose behavior changes (a finding from steps 7–8 that lies on a path the project calls). The impact is traced by reading, never by compiling; say so. Without a project path, record *project impact: not checked — no project path*.
5. **Dependency delta.** Compare both pubspecs: added, removed, or re-constrained dependencies; SDK lower-bound changes. With a project path, run `dart pub add <package>@<target> --dry-run -C <project>` (or `flutter pub add`) to see what else in the project's graph would move, or whether it resolves at all. Without one, record the dry run as *not checked — no project path*. Build the dependency inventory (`SKILL.md`) for the target and mark what is added or removed relative to the current version; the checkpoint covers the added non-platform packages and the added *Outside pub* dependencies.
6. **Identity and license delta.** A change of hands is a supply-chain fact to report even when the code looks fine. Sources: the `repository`/`homepage` fields in each version's pubspec (from the versions list in Step 1); the `LICENSE` file in both unpacked trees; and, with `gh`, the commit authors and release-tag authors between the two tags. The pub.dev API gives only the *current* `publisherId`, not a per-version one: report it, and record the publisher at the current version as *not checked — no per-version source* unless the operator supplies it.
7. **Changelog vs. diff.** Check every `CHANGELOG.md` entry between the two versions against the diff. A breaking change in the diff that the changelog omits or labels as minor is a semver-discipline finding; a changelog claim with no corresponding code is a claim–implementation finding.
8. **Risk delta.** Run the risk sweep (`SKILL.md`) on the changed files, read the Axis 1 lenses and Axis 2 categories against the diff, and give each category one state:
   - **new** — the diff introduces it (evidence in the target);
   - **resolved** — the diff removes it (evidence in the current version);
   - **carried over** — present in both versions on lines the diff rewrote (evidence in the target);
   - **untouched by the diff** — the changed files were searched and contain nothing bearing on it. This says nothing about whether the risk exists in unchanged code;
   - **not checked** — with the reason.

   Platform and native requirement changes (new permissions, raised `minSdkVersion` or deployment target, new plist keys, privacy-manifest changes) belong here. Categories not carried by code — maintenance reality, single-maintainer concentration, download base — have no delta: report them as facts about the target under *Package status*.

If no prior reading of the current version exists, do not evaluate it in full; evaluate the diff, and list the current version's unread areas in the coverage record. "Untouched by the diff" is never to be read as "clean".

## Tensions (in addition to `SKILL.md`)

- Where the upgrade improves one axis and worsens the other (e.g. fixes an advisory but adds consumer-time codegen).

## Exits

- **Upgrade** — move to the target; the touched call sites and dependency moves are the work.
- **Stay pinned** — remain on the current version; the advisories, discontinuation, or SDK drift that accumulate there are the cost.
- **Leave the package** — move to `replacedBy`, another package (an add evaluation, `references/adoption.md`), or hold it yourself.

When `isDiscontinued` is true, name `replacedBy` among the facts bearing on the exits.

## Output format

```markdown
# Update: <package> <current> → <target>

## Summary
- Resolves: yes, moving <packages> | no — <conflict> | not checked — no project path
- Project impact: <n> call sites stop compiling, <n> change behavior (traced, not compiled) | not checked — no project path
- <strength> — <new, resolved, or carried-over finding, one line> (`file:line` / field)   ← the findings at the highest strength level present, one line each; lower levels stay in Risk delta
- Not checked: <lens or category that matters most> — <reason>
- Tension: <main tension, one line>
- Scope: this reading covers the diff only; risks in unchanged code are not assessed here.

## Project impact
Traced by reading the project's source, not by compiling it.
- Stops compiling: <symbol, `file:line` in the target> — `path:line` in the project, … | none
- Changes behavior: <finding, `file:line` in the target> — `path:line` in the project, … | none
- Requirements vs. the project: <SDK and Flutter floors, platform minimums, toolchain> — <the project's declared value, or not checked — not declared in the project>
(Without a project path: not checked — no project path.)

## Context
Entry: update · Project: <path or "none"> · Targets: <list or unknown> · Distribution/license constraint: <given or none> · Defaulted: <Step 0 items not answered>
Run: <date> · Dart <version> · Flutter <version> · archive_sha256 <current> / <target> (plus one per own implementation read) · repository <url>@<commit> (tag <matched>; one per archive when they differ)

## Gate
Publisher: <publisherId or null> · Gate: fired (diff reading skipped) | not fired

## Package status (not a delta)
- Discontinued: <isDiscontinued; replacedBy> · Target retracted: <yes/no> · Verified publisher: <publisherId or null>
- Maintenance, maintainers, download base: <facts about the target, with strength where the category carries one>

## Version history
- <version — published date — retracted?>
- Advisories on current: <id, affected, fixed in> | none · on target: <…> | none

## Classification
<target's classification; any paradigm change on the export surface>

## Public API delta
- <removed/renamed/re-typed symbol, changed default or thrown type, `file:line`> | none

## Dependency delta
- <added/removed/re-constrained>; project graph moves from the dry run | not checked — no project path
- Inventory change: added <platform / author's own / third-party / outside pub, names> · removed <names>
- Checkpoint: <question as asked> | skipped — nothing added to offer | not asked — <reason>; <the question that would have been asked>
- Read in detail (user-approved): <names> | none · Outside pub investigated: <names — what was done> | none

## Identity and license delta
- <publisher/repo/maintainer/license changes> | none

## Functionality & quality delta
- **<lens>**: <what changed, `file:line`>
- Untouched by the diff: <lenses> · Not checked: <lens — reason>, …

## Risk delta
Findings across all categories, ordered by strength:
- <strength: max | xhigh | high | medium | low> · <category> · <new | resolved | carried over> — <finding>
  - evidence, why it bites, bites hardest when

- Untouched by the diff: <categories>
- Not checked: <category — reason>, …

## Changelog vs. diff
- <omissions, mislabeled breaking changes, unbacked claims> | consistent

## Tensions
- <where the upgrade helps one axis and hurts the other>

## Coverage
- Changed files read: <files>
- Unchanged areas not re-read: <dirs>
- Archive vs. repository (target): <result>
- Sweep terms per category: <category: terms>
- Metadata not fetched: <fields, why>

## Hand-off
- Exits: upgrade | stay pinned | leave the package — with the facts bearing on each.
- How the project's context modulates the risks.
- (No chosen exit. No score.)
```
