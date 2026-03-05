#!/usr/bin/env bash
set -euo pipefail

# WorktreeCreate hook for jj workspaces.
# Input: JSON on stdin with { name, cwd, ... }
# Output: absolute path to created workspace directory on stdout

input=$(cat)
name=$(jq -re '.name' <<< "$input") || { printf 'Error: name missing from input\n' >&2; exit 1; }
cwd=$(jq -re '.cwd' <<< "$input") || { printf 'Error: cwd missing from input\n' >&2; exit 1; }

if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
  printf 'Error: invalid workspace name: %s\n' "$name" >&2
  exit 1
fi

# Find the jj repo root from the session's cwd
repo_root=$(cd "$cwd" && jj root)

# Place workspaces under ~/.claude/worktrees/{name}
dest="$HOME/.claude/worktrees/$name"

# Clean up stale workspace at this path if it exists
if [ -d "$dest" ]; then
  (cd "$repo_root" && jj workspace forget -- "$name") || true
  rm -rf -- "$dest"
fi

mkdir -p "$(dirname "$dest")"

# Create the workspace. New working-copy commit shares the same parents
# as the main workspace's @, so the agent starts with identical code.
(cd "$repo_root" && jj workspace add "$dest" --name "$name") >&2

# Stdout = absolute path (the hook contract)
printf '%s\n' "$dest"
