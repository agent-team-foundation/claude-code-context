#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${FIRST_TREE_REPO_URL:-https://github.com/agent-team-foundation/first-tree.git}"
REPO_REF="${FIRST_TREE_REPO_REF:-main}"
LOCAL_SKILL_NAME="first-tree"
LEGACY_LOCAL_SKILL_NAME="first-tree-cli-framework"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
CLONE_DIR="$TMP_DIR/first-tree"

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

mkdir -p \
  "$ROOT_DIR/.skills/$LOCAL_SKILL_NAME" \
  "$ROOT_DIR/.claude/skills/$LOCAL_SKILL_NAME" \
  "$ROOT_DIR/.agents/skills/$LOCAL_SKILL_NAME"

for legacy_dir in \
  "$ROOT_DIR/.skills/$LEGACY_LOCAL_SKILL_NAME" \
  "$ROOT_DIR/.claude/skills/$LEGACY_LOCAL_SKILL_NAME" \
  "$ROOT_DIR/.agents/skills/$LEGACY_LOCAL_SKILL_NAME"; do
  if [[ -d "$legacy_dir" ]]; then
    rm -rf "$legacy_dir"
  fi
done

rsync -a --delete \
  "$UPSTREAM_SKILL_DIR/" \
  "$ROOT_DIR/.skills/$LOCAL_SKILL_NAME/"

rsync -a --delete \
  "$ROOT_DIR/.skills/$LOCAL_SKILL_NAME/" \
  "$ROOT_DIR/.claude/skills/$LOCAL_SKILL_NAME/"

rsync -a --delete \
  "$ROOT_DIR/.skills/$LOCAL_SKILL_NAME/" \
  "$ROOT_DIR/.agents/skills/$LOCAL_SKILL_NAME/"

echo "Synchronized $LOCAL_SKILL_NAME from $REPO_URL@$REPO_REF"
