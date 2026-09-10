#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
GEN="$ROOT/gen.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "missing $1"
}

assert_contains() {
  local file="$1"
  local needle="$2"
  grep -F -q -- "$needle" "$file" || fail "$file does not contain: $needle"
}

assert_order() {
  local file="$1"
  local first="$2"
  local second="$3"
  python3 -c '
import sys
text = open(sys.argv[1], encoding="utf-8").read()
a, b = sys.argv[2], sys.argv[3]
ia, ib = text.find(a), text.find(b)
if ia < 0 or ib < 0 or ia > ib:
    raise SystemExit("expected %r before %r in %s" % (a, b, sys.argv[1]))
' "$file" "$first" "$second"
}

OUT="$(mktemp -d)"
POSTS_DIR="$ROOT/testdata/posts" OUT_DIR="$OUT" "$GEN"

assert_file "$OUT/index.html"
assert_file "$OUT/p/newer/index.html"
assert_file "$OUT/p/older/index.html"
assert_file "$OUT/feed.xml"

assert_contains "$OUT/index.html" "较新的一篇"
assert_contains "$OUT/index.html" "较早的一篇"
assert_order "$OUT/index.html" "较新的一篇" "较早的一篇"

assert_contains "$OUT/p/newer/index.html" "较新的一篇"
assert_contains "$OUT/p/newer/index.html" "<strong>强调</strong>"

assert_contains "$OUT/feed.xml" "这是较新摘要"
assert_contains "$OUT/feed.xml" "只有正文没有摘要。后面再写一句凑字。"
rm -rf "$OUT"
echo "PASS: happy-path"
