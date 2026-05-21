#!/usr/bin/env bash
#
# Sync the installed skills into this plugin repo.
#
#   ./sync-skills.sh           copy skills in, show what changed, then stop
#   ./sync-skills.sh --push    copy, bump the patch version, commit & push
#
# Skills are read from ~/.claude/skills by default; override with
#   SKILLS_DIR=/path/to/skills ./sync-skills.sh
#
# The skill directories under ~/.claude/skills are usually symlinks, so the
# copy uses `cp -RL` to dereference them into real files.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${SKILLS_DIR:-$HOME/.claude/skills}"
DEST="$REPO/plugins/flutter-html-reproduce/skills"
PLUGIN_JSON="$REPO/plugins/flutter-html-reproduce/.claude-plugin/plugin.json"

# The skills bundled by this plugin — keep in sync with plugin.json.
SKILLS=(
  flutter-html-reproduce
  html-source-fetcher
  html-flutter-align-table
  html-dom-to-widget-tree
  html-css-to-flutter-style
  html-asset-export
  html-flutter-pixel-diff
)

echo "==> Syncing skills from $SKILLS_SRC"
for s in "${SKILLS[@]}"; do
  src="$SKILLS_SRC/$s"
  if [ ! -e "$src" ]; then
    echo "ERROR: skill not found: $src" >&2
    exit 1
  fi
  rm -rf "${DEST:?}/$s"
  cp -RL "$src" "$DEST/$s"
  echo "    synced $s"
done

# Strip dev-only artifacts — they should not ship in the distributed plugin.
find "$DEST" -type d \
  \( -name tests -o -name eval -o -name __pycache__ -o -name node_modules \) \
  -prune -exec rm -rf {} +
find "$DEST" \( -name '.DS_Store' -o -name '*.pyc' \) -delete

echo "==> Bundled skill files: $(find "$DEST" -type f | wc -l | tr -d ' ')"

cd "$REPO"
if [ -z "$(git status --porcelain)" ]; then
  echo "==> No changes — plugin already up to date."
  exit 0
fi

echo "==> Changed files:"
git status -s

if [ "${1:-}" != "--push" ]; then
  echo
  echo "Review the changes above, then commit yourself or re-run with --push."
  exit 0
fi

# --push: bump the patch version so colleagues are offered the update.
NEW_VERSION="$(python3 - "$PLUGIN_JSON" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
major, minor, patch = (int(x) for x in data["version"].split("."))
data["version"] = f"{major}.{minor}.{patch + 1}"
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(data["version"])
PY
)"
echo "==> Bumped plugin version to $NEW_VERSION"

git add -A
git commit -m "Sync skills, release v$NEW_VERSION"
git push
echo
echo "==> Pushed. Colleagues update with: /plugin marketplace update claude-flutter-skills"
