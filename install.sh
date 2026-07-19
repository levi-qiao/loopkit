#!/usr/bin/env sh
# graphkit installer — drops the skill into your Claude Code skills folder.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/levi-qiao/graphkit/main/install.sh | sh
set -eu

SKILL_NAME="graphkit"
REPO="https://github.com/levi-qiao/graphkit.git"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
DEST="$SKILLS_DIR/$SKILL_NAME"

echo "Installing $SKILL_NAME -> $DEST"
mkdir -p "$SKILLS_DIR"

if [ -d "$DEST/.git" ]; then
  echo "Already installed; updating..."
  git -C "$DEST" pull --ff-only
else
  git clone --depth 1 "$REPO" "$DEST"
fi

echo ""
echo "✅ graphkit installed."
echo "   In Claude Code, run:  /graphkit"
