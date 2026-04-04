#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${FIRST_TREE_REPO_URL:-https://github.com/agent-team-foundation/first-tree.git}"
REPO_REF="${FIRST_TREE_REPO_REF:-main}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
CLONE_DIR="$TMP_DIR/first-tree"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

echo "Cloning $REPO_URL@$REPO_REF ..."
git clone --depth=1 --branch "$REPO_REF" "$REPO_URL" "$CLONE_DIR" >/dev/null

UPSTREAM_SKILL_DIR="$CLONE_DIR/skills/first-tree-cli-framework"

if [[ ! -d "$UPSTREAM_SKILL_DIR" ]]; then
  echo "Missing expected upstream path: $UPSTREAM_SKILL_DIR" >&2
  exit 1
fi

mkdir -p \
  "$ROOT_DIR/.skills/first-tree-cli-framework" \
  "$ROOT_DIR/.claude/skills/first-tree-cli-framework" \
  "$ROOT_DIR/.agents/skills/first-tree-cli-framework"

rsync -a --delete \
  "$UPSTREAM_SKILL_DIR/" \
  "$ROOT_DIR/.skills/first-tree-cli-framework/"

rsync -a --delete \
  "$ROOT_DIR/.skills/first-tree-cli-framework/" \
  "$ROOT_DIR/.claude/skills/first-tree-cli-framework/"

rsync -a --delete \
  "$ROOT_DIR/.skills/first-tree-cli-framework/" \
  "$ROOT_DIR/.agents/skills/first-tree-cli-framework/"

echo "Synchronized first-tree-cli-framework from $REPO_URL@$REPO_REF"
