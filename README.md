# skills

Agent skills by koji-1009.

## Skills

[**pub-review**](skill/pub-review/skills/pub-review/SKILL.md) — Source-level review of a pub.dev (Flutter/Dart) dependency. Two entry points: add (vet one package, or compare candidates, before depending on it) and update (vet moving an existing dependency from its locked version to a target by reading the diff). Produces two independent readings — functionality/quality and risk — anchored to `file:line`, with a coverage record, and hands the decision to the user without a verdict.

The skill is a directory: `SKILL.md` holds the shared core and routes to `references/adoption.md` or `references/update.md`. Install all three files together.

## Setup

### Claude Code (plugin)

This repository is a Claude Code plugin marketplace. Add it, then install pub-review:

```bash
claude plugin marketplace add koji-1009/skills
claude plugin install pub-review@koji-1009-skills
```

Plugins install at user scope by default; pass `--scope project` or `--scope local` to change it. The skill is invoked as `/pub-review:pub-review`, and also loads automatically when a request matches its description.

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
```

### Claude Code (global)

Same as above with `~/.claude/skills/pub-review` as the destination.

### Codex (project / global)

Same as above with `.agents/skills/pub-review` (project) or `~/.agents/skills/pub-review` (global) as the destination.

## License

MIT
