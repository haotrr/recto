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

EMPTY_OUT="$(mktemp -d)"
POSTS_DIR="$ROOT/testdata/empty" OUT_DIR="$EMPTY_OUT" "$GEN"
assert_contains "$EMPTY_OUT/index.html" "还没有文章。"
python3 -c '
import sys
import xml.etree.ElementTree as ET
tree = ET.parse(sys.argv[1])
ch = tree.getroot().find("channel")
if ch is None:
    raise SystemExit("feed missing channel")
for tag in ("title", "link", "description"):
    node = ch.find(tag)
    if node is None or not (node.text or "").strip():
        raise SystemExit("feed missing " + tag)
if ch.find("item") is not None:
    raise SystemExit("empty feed should have no item")
' "$EMPTY_OUT/feed.xml"
rm -rf "$EMPTY_OUT"
echo "PASS: empty-site"

BAD_OUT="$(mktemp -d)"
if POSTS_DIR="$ROOT/testdata/bad" OUT_DIR="$BAD_OUT" "$GEN"; then
  rm -rf "$BAD_OUT"
  fail "bad filename should fail"
fi
[[ ! -f "$BAD_OUT/index.html" ]] || fail "bad filename left generated files"
rm -rf "$BAD_OUT"
echo "PASS: bad-filename"

DUP_OUT="$(mktemp -d)"
if POSTS_DIR="$ROOT/testdata/dup" OUT_DIR="$DUP_OUT" "$GEN"; then
  rm -rf "$DUP_OUT"
  fail "duplicate slug should fail"
fi
[[ ! -f "$DUP_OUT/index.html" ]] || fail "duplicate slug left generated files"
rm -rf "$DUP_OUT"
echo "PASS: duplicate-slug"
