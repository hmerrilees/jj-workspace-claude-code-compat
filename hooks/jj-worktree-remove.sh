#!/usr/bin/env bash
set -euo pipefail

# WorktreeRemove hook for jj workspaces.
# Input: JSON on stdin with { worktree_path, cwd, ... }
# Output: ignored (just exit 0 on success)

input=$(cat)
worktree_path=$(jq -re '.worktree_path' <<< "$input") || { printf 'Error: worktree_path missing from input\n' >&2; exit 1; }

# Extract and validate the workspace name, then reconstruct the path.
# This sidesteps path traversal entirely — we never use worktree_path
# for filesystem operations, only the name component rebuilt under our
# known-safe prefix.
name=$(basename -- "$worktree_path")

if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
  printf 'Error: invalid workspace name derived from path: %s\n' "$name" >&2
  exit 1
fi

dest="$HOME/.claude/worktrees/$name"

# Forget the workspace from within it (jj allows self-forget).
# If the .jj dir is missing or the repo is gone, skip gracefully.
if [ -d "$dest/.jj" ]; then
  (cd "$dest" && jj workspace forget -- "$name") || true
fi

rm -rf -- "$dest"
