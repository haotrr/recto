#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SITE_URL="https://recto.haotrr.com"
SITE_NAME="haotrr"
POSTS_DIR="${POSTS_DIR:-$ROOT/posts}"
OUT_DIR="${OUT_DIR:-$ROOT}"
TEMPLATES="$ROOT/templates"
STYLES="$ROOT/styles.css"

die() {
  echo "ERROR: $1" >&2
  exit 1
}

if ! command -v pandoc >/dev/null 2>&1; then
  die "pandoc is required (brew install pandoc)"
fi
command -v python3 >/dev/null 2>&1 || die "python3 is required"

[[ -f "$STYLES" ]] || die "missing $STYLES"
[[ -f "$TEMPLATES/chrome.html" ]] || die "missing $TEMPLATES/chrome.html"
[[ -f "$TEMPLATES/home.html" ]] || die "missing $TEMPLATES/home.html"
[[ -f "$TEMPLATES/post.html" ]] || die "missing $TEMPLATES/post.html"
[[ -f "$TEMPLATES/feed.xml" ]] || die "missing $TEMPLATES/feed.xml"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/p"

python3 - "$ROOT" "$POSTS_DIR" "$TMP" "$SITE_URL" "$SITE_NAME" <<'PYCODE'
import html
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

root = Path(sys.argv[1])
posts_dir = Path(sys.argv[2])
tmp = Path(sys.argv[3])
site_url = sys.argv[4]
site_name = sys.argv[5]
templates = root / "templates"

NAME_RE = re.compile(
    r"^(\d{4}-\d{2}-\d{2})-([a-z0-9]+(?:-[a-z0-9]+)*)\.md$"
)
TZ = timezone(timedelta(hours=8))


def die(msg):
    raise SystemExit("ERROR: " + msg)


def render(template, mapping):
    out = template
    for key, value in mapping.items():
        out = out.replace("{{" + key + "}}", value)
    return out


def parse_post(path):
    name = path.name
    matched = NAME_RE.match(name)
    if not matched:
        die(
            "invalid filename %s; expected YYYY-MM-DD-slug.md "
            "with slug of lowercase letters, digits, and hyphens" % name
        )
    date_s, slug = matched.group(1), matched.group(2)
    try:
        datetime.strptime(date_s, "%Y-%m-%d")
    except ValueError:
        die("invalid calendar date in %s" % name)

    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        die("missing YAML front matter in %s" % name)
    rest = text[4:]
    end = rest.find("\n---\n")
    if end < 0:
        die("unclosed YAML front matter in %s" % name)
    raw_meta, body = rest[:end], rest[end + 5 :]
    title = None
    summary = ""
    hide = False
    for line in raw_meta.splitlines():
        if not line.strip():
            continue
        if line.startswith("title:"):
            title = line[6:].strip()
            continue
        if line.startswith("summary:"):
            summary = line[8:].strip()
            continue
        if line.startswith("hide:"):
            value = line[5:].strip()
            if value not in ("true", "false"):
                die("hide must be true or false in %s" % name)
            hide = value == "true"
            continue
        die("unsupported YAML line in %s: %s" % (name, line))
    if not title:
        die("missing title in %s" % name)

    proc = subprocess.run(
        [
            "pandoc",
            "--from",
            "markdown",
            "--to",
            "html",
            "--syntax-highlighting=none",
            "--wrap=none",
        ],
        input=body,
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        die("pandoc failed on %s: %s" % (name, proc.stderr.strip()))
    body_html = proc.stdout
    plain = re.sub(r"<[^>]+>", "", body_html)
    plain = re.sub(r"\s+", " ", html.unescape(plain)).strip()
    excerpt = summary if summary else plain[:160]
    pubdate = datetime.strptime(date_s, "%Y-%m-%d").replace(tzinfo=TZ).strftime(
        "%a, %d %b %Y 00:00:00 +0800"
    )
    return {
        "name": name,
        "hide": hide,
        "date": date_s,
        "slug": slug,
        "title": title,
        "excerpt": excerpt,
        "body_html": body_html,
        "permalink": "%s/p/%s/" % (site_url, slug),
        "pubdate": pubdate,
    }


posts = []
if posts_dir.exists():
    posts = [parse_post(item) for item in sorted(posts_dir.glob("*.md"))]

slugs = {}
for post in posts:
    other = slugs.get(post["slug"])
    if other:
        die("duplicate slug %s: %s and %s" % (post["slug"], other, post["name"]))
    slugs[post["slug"]] = post["name"]

posts = [post for post in posts if not post["hide"]]
posts.sort(key=lambda item: (-int(item["date"].replace("-", "")), item["slug"]))

chrome = (templates / "chrome.html").read_text(encoding="utf-8")
home_tpl = (templates / "home.html").read_text(encoding="utf-8")
post_tpl = (templates / "post.html").read_text(encoding="utf-8")
feed_tpl = (templates / "feed.xml").read_text(encoding="utf-8")

if posts:
    blocks = []
    for post in posts:
        blocks.append(
            '<article class="entry">\n'
            '  <h2 class="entry-title"><a href="p/%s/">%s</a></h2>\n'
            '  <p class="entry-date">%s</p>\n'
            "</article>"
            % (post["slug"], html.escape(post["title"]), post["date"])
        )
    home_items = "\n".join(blocks)
else:
    home_items = '<p class="empty">还没有文章。</p>'

home_inner = render(home_tpl, {"ITEMS": home_items})
(tmp / "index.html").write_text(
    render(
        chrome,
        {
            "PAGE_TITLE": site_name,
            "HOME_HREF": "index.html",
            "CSS_HREF": "styles.css",
            "FEED_HREF": "feed.xml",
            "CONTENT": home_inner,
        },
    ),
    encoding="utf-8",
)

for post in posts:
    inner = render(
        post_tpl,
        {
            "TITLE": html.escape(post["title"]),
            "DATE": post["date"],
            "BODY": post["body_html"],
        },
    )
    dest = tmp / "p" / post["slug"] / "index.html"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(
        render(
            chrome,
            {
                "PAGE_TITLE": "%s · %s" % (html.escape(post["title"]), site_name),
                "HOME_HREF": "../../index.html",
                "CSS_HREF": "../../styles.css",
                "FEED_HREF": "../../feed.xml",
                "CONTENT": inner,
            },
        ),
        encoding="utf-8",
    )

feed_items = []
for post in posts:
    feed_items.append(
        "    <item>\n"
        "      <title>%s</title>\n"
        "      <link>%s</link>\n"
        "      <guid>%s</guid>\n"
        "      <pubDate>%s</pubDate>\n"
        "      <description>%s</description>\n"
        "    </item>"
        % (
            html.escape(post["title"], quote=False),
            html.escape(post["permalink"], quote=False),
            html.escape(post["permalink"], quote=False),
            post["pubdate"],
            html.escape(post["excerpt"], quote=False),
        )
    )
(tmp / "feed.xml").write_text(
    render(feed_tpl, {"ITEMS": "\n".join(feed_items)}),
    encoding="utf-8",
)
PYCODE

if [[ "$OUT_DIR" != "$ROOT" ]]; then
  mkdir -p "$OUT_DIR"
  cp "$STYLES" "$OUT_DIR/styles.css"
fi

rm -rf "$OUT_DIR/p"
mkdir -p "$OUT_DIR/p"
if compgen -G "$TMP/p/*" > /dev/null; then
  cp -R "$TMP/p/." "$OUT_DIR/p/"
fi
cp "$TMP/index.html" "$OUT_DIR/index.html"
cp "$TMP/feed.xml" "$OUT_DIR/feed.xml"
