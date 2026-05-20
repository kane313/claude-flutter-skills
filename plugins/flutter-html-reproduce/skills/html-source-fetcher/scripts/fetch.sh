#!/usr/bin/env bash
# fetch.sh <kind> <source> <out-dir>
# kind: local-file | url-static | url-js | image | snippet
set -euo pipefail

kind="${1:?kind required}"
src="${2:?source required}"
out="${3:?out-dir required}"
mkdir -p "$out"

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
vision_only=false
url_field='"url": null'

case "$kind" in
  local-file)
    [[ -f "$src" ]] || { echo "file not found: $src" >&2; exit 1; }
    src_dir="$(dirname "$src")"
    # Inline <link rel="stylesheet" href="...">
    python3 - "$src" "$src_dir" > "$out/normalized.html" <<'PYEOF'
import sys, re, os
src_path = sys.argv[1]
src_dir  = sys.argv[2]
with open(src_path, 'r', encoding='utf-8') as f:
    html_text = f.read()

def inline_link(m):
    href = m.group(1)
    path = os.path.join(src_dir, href)
    try:
        with open(path, 'r', encoding='utf-8') as f:
            css = f.read()
        return '<style>/* inlined from ' + href + ' */\n' + css + '</style>'
    except FileNotFoundError:
        return m.group(0)  # leave tag intact

out = re.sub(
    r'<link\s+rel="stylesheet"\s+href="([^"]+)"\s*/?>',
    inline_link,
    html_text,
)
sys.stdout.write(out)
PYEOF
    ;;

  snippet)
    # source is the snippet string itself (passed verbatim as arg 2)
    printf '%s\n' "$src" > "$out/normalized.html"
    # Warn on referenced external resources
    if grep -qE '<link[^>]+stylesheet|<script[^>]+src=|@import' "$out/normalized.html"; then
      echo "fetch.sh: snippet references external resources; downstream may need them" >&2
    fi
    ;;

  image)
    [[ -f "$src" ]] || { echo "image not found: $src" >&2; exit 1; }
    cp "$src" "$out/screenshot.png"
    printf '<!-- vision-only: source was image %s -->\n' "$(basename "$src")" > "$out/normalized.html"
    vision_only=true
    ;;

  url-static)
    # The orchestrating SKILL is expected to call Claude's WebFetch tool itself,
    # write the body to a temp file, then invoke fetch.sh local-file <temp> <out>.
    # This script does not network — keeps the test harness offline.
    echo "fetch.sh: url-static must be dispatched from the SKILL via WebFetch (see references/fetch-strategies.md)" >&2
    exit 64
    ;;

  url-js)
    # Same separation of concerns: Playwright invocation belongs in the SKILL,
    # not in this script (so test harness stays hermetic). See playwright-setup.md.
    echo "fetch.sh: url-js must be dispatched from the SKILL via Playwright (see references/playwright-setup.md)" >&2
    exit 64
    ;;

  *)
    echo "fetch.sh: unknown kind: $kind" >&2
    exit 1
    ;;
esac

# Write source.meta.json
cat > "$out/source.meta.json" <<JSON
{
  "kind": "$kind",
  "render": "static",
  $url_field,
  "vision_only": $vision_only,
  "spa_suspected": false,
  "fetched_at": "$ts"
}
JSON

echo "fetch.sh: ok kind=$kind out=$out" >&2
