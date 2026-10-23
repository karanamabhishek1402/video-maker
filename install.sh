#!/bin/sh
# Installs the video-maker skill for Claude Code into ~/.claude/skills
set -e
REPO="${SKILL_REPO:-karanamabhishek1402/video-maker}"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
TMP=$(mktemp -d)
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" | tar -xz -C "$TMP"
mkdir -p "$DEST"
rm -rf "$DEST/video-maker"
cp -R "$TMP"/*/skills/video-maker "$DEST/video-maker"
rm -rf "$TMP"
echo "Installed video-maker skill to $DEST/video-maker. Restart Claude Code, then type /video-maker."
