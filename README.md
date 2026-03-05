# How to use jj workspaces with Claude Code

Hooks that make Claude Code worktrees use jj workspaces instead of git worktrees.

## Why

Claude Code creates git worktrees that get a dead copy of `.jj/` — the worktree and your repo can't see each other's changes. jj workspaces share the same repo store, so changes are visible from both sides.

## Setup

> These hooks would normally ship as a plugin, but plugin-level lifecycle hooks don't fire yet ([#16288](https://github.com/anthropics/claude-code/issues/16288)). Until that's fixed, they must be installed manually into `~/.claude/settings.json`.

Requires `jj` and `jq`. Clone, then from the repo root:

```sh
# Merges WorktreeCreate/WorktreeRemove hook entries into your existing
# settings.json, pointing at the hook scripts with absolute paths.
jq -s '.[0] * .[1]' ~/.claude/settings.json <(jq -n \
  --arg c "$(pwd)/hooks/jj-worktree-create.sh" \
  --arg r "$(pwd)/hooks/jj-worktree-remove.sh" \
  '{hooks: {WorktreeCreate: [{hooks: [{type: "command", command: $c, timeout: 30}]}], WorktreeRemove: [{hooks: [{type: "command", command: $r, timeout: 30}]}]}}') \
  > /tmp/claude-settings.json && mv /tmp/claude-settings.json ~/.claude/settings.json
```

Restart Claude Code for hooks to take effect.

To uninstall, remove the `WorktreeCreate` and `WorktreeRemove` entries from `~/.claude/settings.json`.
