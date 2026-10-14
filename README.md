# skills

Agent skills by koji-1009.

## Skills

[**skill/pub-review.md**](skill/pub-review/skills/pub-review/SKILL.md) — Source-level review of a pub.dev (Flutter/Dart) dependency. Two entry points: add (vet one package, or compare candidates, before depending on it) and update (review in full a move from the locked version to a target by reading the whole diff). Produces two independent readings — functionality/quality and risk — anchored to `file:line`, with a coverage record, and hands the decision to the user without a verdict.

The skill is a directory: `SKILL.md` holds the shared core and routes to `references/adoption.md` or `references/update.md`. Install all three files together.

[**skill/pub-upgrade-check.md**](skill/pub-review/skills/pub-upgrade-check/SKILL.md) — Routine check of whether an app is affected by upgrading its pub.dev dependencies. Reads the package diff only where the app reaches it — used symbols, behavior on called paths, requirements, advisories — and flags supply-chain changes that call for a full pub-review. A single `SKILL.md`; needs a project path.

Both skills ship in the `pub-review` plugin, which Claude Code and Codex both read. Each skill has one file, `skill/pub-review/skills/<name>/SKILL.md`; `skill/pub-review.md` and `skill/pub-upgrade-check.md` are symlinks to it.

## Setup

### Claude Code (plugin)

This repository is a Claude Code plugin marketplace. Add it, then install the pub-review plugin:

```bash
claude plugin marketplace add koji-1009/skills
claude plugin install pub-review@koji-1009-skills
```

Plugins install at user scope by default; pass `--scope project` or `--scope local` to change it. The skills are invoked as `/pub-review:pub-review` and `/pub-review:pub-upgrade-check`, and also load automatically when a request matches their descriptions.

Auto-update is off by default for third-party marketplaces. Enable it under `/plugin` → Marketplaces, or update manually:

```bash
claude plugin marketplace update koji-1009-skills
claude plugin update pub-review@koji-1009-skills
```

### Codex (plugin)

Codex reads the same marketplace:

```bash
codex plugin marketplace add koji-1009/skills
codex plugin add pub-review@koji-1009-skills
```

Otherwise, copy the skill directory to your agent's configuration:

### Claude Code (project)

```bash
mkdir -p .claude/skills/pub-review/references
curl -o .claude/skills/pub-review/SKILL.md https://raw.githubusercontent.com/koji-1009/skills/main/skill/pub-review/skills/pub-review/SKILL.md
curl -o .claude/skills/pub-review/references/adoption.md https://raw.githubusercontent.com/koji-1009/skills/main/skill/pub-review/skills/pub-review/references/adoption.md
curl -o .claude/skills/pub-review/references/update.md https://raw.githubusercontent.com/koji-1009/skills/main/skill/pub-review/skills/pub-review/references/update.md
mkdir -p .claude/skills/pub-upgrade-check
curl -o .claude/skills/pub-upgrade-check/SKILL.md https://raw.githubusercontent.com/koji-1009/skills/main/skill/pub-review/skills/pub-upgrade-check/SKILL.md
```

### Claude Code (global)

Same as above with `~/.claude/skills/` as the base directory.

### Codex (project / global)

Same as above with `.agents/skills/` (project) or `~/.agents/skills/` (global) as the base directory.

## License

MIT
