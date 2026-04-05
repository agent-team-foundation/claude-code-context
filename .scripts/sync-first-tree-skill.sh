#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${FIRST_TREE_REPO_URL:-https://github.com/agent-team-foundation/first-tree.git}"
REPO_REF="${FIRST_TREE_REPO_REF:-main}"
LOCAL_SKILL_NAME="first-tree"
LEGACY_LOCAL_SKILL_NAME="first-tree-cli-framework"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
CLONE_DIR="$TMP_DIR/first-tree"
CLAUDE_SKILL_DIR="$ROOT_DIR/.claude/skills/$LOCAL_SKILL_NAME"
AGENTS_SKILL_DIR="$ROOT_DIR/.agents/skills/$LOCAL_SKILL_NAME"
PROGRESS_PATH="$AGENTS_SKILL_DIR/progress.md"
LEGACY_PROGRESS_PATH="$ROOT_DIR/skills/$LOCAL_SKILL_NAME/progress.md"
TMP_PROGRESS="$TMP_DIR/progress.md"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

echo "Cloning $REPO_URL@$REPO_REF ..."
git clone --depth=1 --branch "$REPO_REF" "$REPO_URL" "$CLONE_DIR" >/dev/null

UPSTREAM_SKILL_DIR=""
for candidate in "skills/first-tree" "skills/first-tree-cli-framework"; do
  if [[ -d "$CLONE_DIR/$candidate" ]]; then
    UPSTREAM_SKILL_DIR="$CLONE_DIR/$candidate"
    break
  fi
done

if [[ -z "$UPSTREAM_SKILL_DIR" ]]; then
  echo "Missing expected upstream path under skills/first-tree or skills/first-tree-cli-framework" >&2
  exit 1
fi

if [[ -f "$PROGRESS_PATH" ]]; then
  cp "$PROGRESS_PATH" "$TMP_PROGRESS"
elif [[ -f "$LEGACY_PROGRESS_PATH" ]]; then
  cp "$LEGACY_PROGRESS_PATH" "$TMP_PROGRESS"
fi

mkdir -p \
  "$CLAUDE_SKILL_DIR" \
  "$AGENTS_SKILL_DIR"

for legacy_dir in \
  "$ROOT_DIR/.skills/$LOCAL_SKILL_NAME" \
  "$ROOT_DIR/.skills/$LEGACY_LOCAL_SKILL_NAME" \
  "$ROOT_DIR/.claude/skills/$LEGACY_LOCAL_SKILL_NAME" \
  "$ROOT_DIR/.agents/skills/$LEGACY_LOCAL_SKILL_NAME" \
  "$ROOT_DIR/skills/$LOCAL_SKILL_NAME" \
  "$ROOT_DIR/skills/$LEGACY_LOCAL_SKILL_NAME"; do
  if [[ -d "$legacy_dir" ]]; then
    rm -rf "$legacy_dir"
  fi
done

for target_dir in "$CLAUDE_SKILL_DIR" "$AGENTS_SKILL_DIR"; do
  rsync -a --delete \
    --exclude progress.md \
    "$UPSTREAM_SKILL_DIR/" \
    "$target_dir/"
done

if [[ -f "$TMP_PROGRESS" ]]; then
  cp "$TMP_PROGRESS" "$PROGRESS_PATH"
fi

rmdir "$ROOT_DIR/skills" 2>/dev/null || true

echo "Synchronized $LOCAL_SKILL_NAME from $REPO_URL@$REPO_REF"
