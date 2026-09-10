# Recto 成稿站 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 做出 Recto 静态成稿站：Markdown 进 `posts/`，`gen.sh` 生成首页、文章页和 RSS，生成物进 Git，GitHub Action 只发布到 `recto.haotrr.com`。

**Architecture:** `gen.sh` 是唯一生成器。它读 `posts/*.md`，用 pandoc 转正文，再把 `{{PLACEHOLDER}}` 套进 `templates/`，先写临时目录，成功后只替换 `index.html`、`p/`、`feed.xml`。测试时用 `POSTS_DIR` / `OUT_DIR` 指到 `testdata` 和临时目录。

**Tech Stack:** bash、pandoc、python3（只做 YAML 解析、转义和模板替换）、GitHub Pages 官方 Action。不用 Go、Hugo、Jekyll。

**Spec:** `docs/superpowers/specs/2026-09-10-recto-blog-design.md`

## Global Constraints

- 站点名恒为 `haotrr`，站点 URL 恒为 `https://recto.haotrr.com`。
- 读者页只有 `/`、`/p/<slug>/`、`/feed.xml`。
- 源文件名必须是 `YYYY-MM-DD-slug.md`；`title` 必填，`summary` 可选，都是单行标量。
- 视觉从 Verso 抽同一套纸页变量，不新发明皮肤。
- 生成物进 Git；`.github/workflows/pages.yml` 不跑 `gen.sh`。
- 不做标签、归档、About、搜索、评论、草稿、双语、相关文章、封面、首页摘要。
- 图片只用绝对 URL；不设 `media/`。
- 提交说明用中文。代码能跑通再提交。

## File Structure

- `testdata/posts/*.md`：happy-path 两篇固定稿。
- `testdata/empty/`：空目录，测空站。
- `testdata/bad/notes.md`：坏文件名。
- `testdata/dup/`：两篇相同 slug。
- `test.sh`：调用 `gen.sh` 并断言。
- `gen.sh`：唯一生成器，暴露 `POSTS_DIR`、`OUT_DIR`。
- `templates/chrome.html`：页头页脚。
- `templates/home.html`：首页主列。
- `templates/post.html`：文章主列。
- `templates/feed.xml`：RSS 骨架。
- `styles.css`：纸页样式。
- `posts/*.md`：正式成稿。
- `index.html`、`p/<slug>/index.html`、`feed.xml`：生成物。
- `CNAME`、`.nojekyll`、`.github/workflows/pages.yml`：发布。
- `README.md`：怎么写一篇、怎么生成。

---

### Task 1: 测试夹具和失败的 happy-path

**Files:**
- Create: `testdata/posts/2026-09-10-newer.md`
- Create: `testdata/posts/2026-01-01-older.md`
- Create: `test.sh`

**Interfaces:**
- Consumes: 无。仓库还不是 Git 仓库。
- Produces: `test.sh` 约定 `POSTS_DIR` / `OUT_DIR` 传给 `./gen.sh`；夹具标题为「较新的一篇」「较早的一篇」；newer 的 summary 为「这是较新摘要」。

- [ ] **Step 1: 初始化 Git 仓库**

仓库根还没有 `.git`。在 `/Users/haotrr/Cody/haotrr/recto` 执行：

```bash
cd /Users/haotrr/Cody/haotrr/recto
git init -b main
```

Expected: 出现 `.git/`，当前分支 `main`。

- [ ] **Step 2: 写两篇测试稿**

`testdata/posts/2026-09-10-newer.md`：

```markdown
---
title: 较新的一篇
summary: 这是较新摘要
---

较新正文里有一段 **强调**。
```

`testdata/posts/2026-01-01-older.md`：

```markdown
---
title: 较早的一篇
---

只有正文没有摘要。后面再写一句凑字。
```

- [ ] **Step 3: 写会失败的 `test.sh`**

```bash
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
```

然后：

```bash
chmod +x test.sh
```

- [ ] **Step 4: 跑测试，确认失败**

Run: `cd /Users/haotrr/Cody/haotrr/recto && ./test.sh`

Expected: FAIL，因为 `gen.sh` 不存在（`No such file or directory`）。

- [ ] **Step 5: 提交**

```bash
cd /Users/haotrr/Cody/haotrr/recto
git add testdata/posts/2026-09-10-newer.md testdata/posts/2026-01-01-older.md test.sh .cursorignore docs
git commit -m "$(cat <<'EOF'
先写 Recto 生成器的失败测试。

EOF
)"
```

---

### Task 2: 模板、样式和能通过 happy-path 的 `gen.sh`

**Files:**
- Create: `templates/chrome.html`
- Create: `templates/home.html`
- Create: `templates/post.html`
- Create: `templates/feed.xml`
- Create: `styles.css`
- Create: `gen.sh`
- Test: `test.sh`

**Interfaces:**
- Consumes: `POSTS_DIR`（默认 `posts`）、`OUT_DIR`（默认 `.`）；夹具标题和 summary 见 Task 1。
- Produces: 成功时在 `$OUT_DIR` 写出 `index.html`、`p/<slug>/index.html`、`feed.xml`；`$OUT_DIR` 不是仓库根时顺便拷 `styles.css`。模板占位符：`{{PAGE_TITLE}}`、`{{HOME_HREF}}`、`{{CSS_HREF}}`、`{{FEED_HREF}}`、`{{CONTENT}}`、`{{TITLE}}`、`{{DATE}}`、`{{BODY}}`、`{{ITEMS}}`。

- [ ] **Step 1: 写 `templates/chrome.html`**

```html
<!DOCTYPE html>
<html lang="zh-Hans">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{PAGE_TITLE}}</title>
  <link rel="stylesheet" href="{{CSS_HREF}}">
  <link rel="alternate" type="application/rss+xml" title="haotrr" href="{{FEED_HREF}}">
</head>
<body>
<header class="site-header">
  <div class="wrap site-header-inner">
    <a class="brand" href="{{HOME_HREF}}">
      <span class="avatar">h</span>
      <span class="brand-name">haotrr</span>
    </a>
    <nav class="nav">
      <a href="{{HOME_HREF}}" class="is-active">文章</a>
      <a href="{{FEED_HREF}}">RSS</a>
    </nav>
  </div>
</header>
<main class="wrap page">
{{CONTENT}}
</main>
<footer class="wrap site-footer">
  haotrr · <a href="{{FEED_HREF}}">RSS</a>
</footer>
</body>
</html>
```

- [ ] **Step 2: 写 `templates/home.html`**

```html
<p class="section-label">文章</p>
{{ITEMS}}
```

- [ ] **Step 3: 写 `templates/post.html`**

```html
<article>
  <h1 class="page-title">{{TITLE}}</h1>
  <p class="entry-date">{{DATE}}</p>
  <div class="prose">
{{BODY}}
  </div>
</article>
```

- [ ] **Step 4: 写 `templates/feed.xml`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>haotrr</title>
    <link>https://recto.haotrr.com/</link>
    <description>haotrr</description>
{{ITEMS}}
  </channel>
</rss>
```

- [ ] **Step 5: 写 `styles.css`**

从 Verso 抽同一套变量，只留成稿站用到的规则。完整文件见实现时按下面整段写入，不要自行改色或换字体。

```css
:root {
  --background: oklch(0.985 0.008 85);
  --foreground: oklch(0.22 0.02 55);
  --muted: oklch(0.96 0.008 85);
  --muted-foreground: oklch(0.5 0.02 55);
  --border: oklch(0.9 0.012 85);
  --accent: oklch(0.45 0.07 250);
  --quote: oklch(0.32 0.03 55);
  --meta: oklch(0.66 0.012 55);
  --ring: oklch(0.45 0.07 250 / 0.35);
  --font-body: "Iowan Old Style", "Palatino Linotype", Palatino, "Songti SC", "Noto Serif SC", "Source Han Serif SC", Georgia, serif;
  --font-heading: var(--font-body);
  --font-site-title: var(--font-body);
  --font-ui: ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Noto Sans SC", sans-serif;
  --font-mono: ui-monospace, "SF Mono", Menlo, monospace;
  --content-max-width: 42rem;
  --site-padding: 1.5rem;
  --avatar-size: 28px;
}

@media (prefers-color-scheme: dark) {
  :root {
    --background: oklch(0.18 0.012 70);
    --foreground: oklch(0.93 0.01 85);
    --muted: oklch(0.24 0.012 70);
    --muted-foreground: oklch(0.72 0.02 75);
    --border: oklch(0.32 0.015 70);
    --accent: oklch(0.78 0.06 250);
    --quote: oklch(0.9 0.015 85);
    --meta: oklch(0.58 0.01 75);
    --ring: oklch(0.78 0.06 250 / 0.4);
  }
}

* { box-sizing: border-box; }
html { color-scheme: light dark; }
html, body { margin: 0; padding: 0; }
body {
  font-family: var(--font-ui);
  background: var(--background);
  color: var(--foreground);
  line-height: 1.6;
  min-height: 100vh;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
}

a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
a:focus-visible {
  outline: 2px solid var(--ring);
  outline-offset: 2px;
}
img { max-width: 100%; height: auto; display: block; }

.wrap {
  width: min(var(--content-max-width), 100% - 2 * var(--site-padding));
  margin-inline: auto;
}

.site-header {
  position: sticky;
  top: 0;
  z-index: 20;
  background: color-mix(in oklch, var(--background) 88%, transparent);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border);
}
.site-header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.85rem 0;
}
.brand {
  display: flex;
  align-items: center;
  gap: 0.65rem;
  color: inherit;
  text-decoration: none;
  min-width: 0;
}
.brand:hover { text-decoration: none; }
.avatar {
  width: var(--avatar-size);
  height: var(--avatar-size);
  border-radius: 50%;
  background: var(--foreground);
  color: var(--background);
  display: grid;
  place-items: center;
  font-size: 0.75rem;
  font-weight: 650;
  flex: 0 0 auto;
}
.brand-name {
  font-family: var(--font-site-title);
  font-size: 1.15rem;
  font-weight: 750;
  letter-spacing: -0.02em;
}
.nav {
  display: flex;
  align-items: center;
  gap: 0.15rem;
  flex-wrap: wrap;
  justify-content: flex-end;
}
.nav a {
  font-size: 0.82rem;
  font-weight: 500;
  color: var(--muted-foreground);
  padding: 0.35rem 0.5rem;
  border-radius: 6px;
  text-decoration: none;
}
.nav a:hover, .nav a.is-active {
  color: var(--foreground);
  background: var(--muted);
  text-decoration: none;
}

.page { padding: 1.75rem 0 4rem; }
.section-label {
  font-size: 0.72rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--meta);
  font-weight: 600;
  margin: 0 0 0.85rem;
}

.entry {
  padding: 0 0 1.85rem;
  margin-bottom: 1.85rem;
  border-bottom: 1px solid var(--border);
}
.entry:last-child {
  border-bottom: 0;
  margin-bottom: 0;
  padding-bottom: 0;
}
.entry-title {
  font-family: var(--font-heading);
  font-size: 1.35rem;
  font-weight: 650;
  letter-spacing: -0.02em;
  line-height: 1.3;
  margin: 0 0 0.35rem;
}
.entry-title a { color: inherit; }
@media (hover: hover) {
  .entry-title a:hover { color: var(--accent); text-decoration: none; }
}
.entry-date {
  font-family: var(--font-ui);
  font-size: 0.85rem;
  color: var(--meta);
  margin: 0 0 1rem;
  font-variant-numeric: tabular-nums;
}

.page-title {
  font-family: var(--font-heading);
  font-size: 1.8rem;
  font-weight: 700;
  letter-spacing: -0.03em;
  margin: 0 0 0.4rem;
}

.prose {
  font-family: var(--font-body);
  font-size: 1.05rem;
  line-height: 1.7;
  overflow-wrap: anywhere;
}
.prose > *:first-child { margin-top: 0; }
.prose > *:last-child { margin-bottom: 0; }
.prose p { margin: 0.7em 0; }
.prose h2, .prose h3 {
  font-family: var(--font-heading);
  letter-spacing: -0.02em;
  line-height: 1.3;
}
.prose ul, .prose ol { margin: 0.7em 0; padding-left: 1.4rem; }
.prose code, .prose pre { font-family: var(--font-mono); font-size: 0.9em; }
.prose pre {
  background: var(--muted);
  padding: 0.85rem 1rem;
  overflow: auto;
  border-radius: 8px;
}
.prose blockquote {
  margin: 1.25rem 0;
  padding-left: 1rem;
  border-left: 1px solid var(--border);
  color: var(--quote);
}

.site-footer {
  color: var(--muted-foreground);
  font-size: 0.8rem;
  padding: 0 0 2.5rem;
}
.empty { color: var(--muted-foreground); padding: 2rem 0; }

@media (max-width: 640px) {
  :root { --site-padding: 1.1rem; }
}
```

- [ ] **Step 6: 写 `gen.sh`**

`gen.sh` 是 bash 入口，真正解析和渲染放在同文件内嵌的 python3。完整脚本按下面写入后 `chmod +x gen.sh`。

关键行为必须同时满足：

1. 常量 `SITE_URL=https://recto.haotrr.com`、`SITE_NAME=haotrr`。
2. `POSTS_DIR` 默认 `$ROOT/posts`，`OUT_DIR` 默认 `$ROOT`。
3. 没有 pandoc 时退出并打印 `brew install pandoc`。
4. 文件名用正则 `^(\d{4}-\d{2}-\d{2})-([a-z0-9]+(?:-[a-z0-9]+)*)\.md$`，日期用 `datetime.strptime` 校验。
5. 文首第一对 `---` 取 YAML，只认单行 `title:` / `summary:`，缺标题或未知键就失败。
6. pandoc 参数：`--from markdown --to html --syntax-highlighting=none --wrap=none`。
7. 无 `summary` 时，RSS description 用去标签后的正文前 160 个字。
8. `pubDate` 为该日 `00:00:00 +0800` 的 RFC 822。
9. 排序：日期倒序，同一天 slug 升序。
10. 模板替换是明文 `{{NAME}}`，不用 Go template，不用 envsubst。
11. 先写 `$TMP`，python 成功后再替换 `$OUT_DIR` 的 `index.html`、`p/`、`feed.xml`。
12. `$OUT_DIR` 不是 `$ROOT` 时拷 `styles.css`。
13. 空站首页含 `还没有文章。`，RSS 有 channel 的 title/link/description，没有 item。

`gen.sh` 全文：

```bash
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
    for line in raw_meta.splitlines():
        if not line.strip():
            continue
        if line.startswith("title:"):
            title = line[6:].strip()
            continue
        if line.startswith("summary:"):
            summary = line[8:].strip()
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
```

- [ ] **Step 7: 跑 happy-path 测试**

Run: `cd /Users/haotrr/Cody/haotrr/recto && ./test.sh`

Expected: 打印 `PASS: happy-path`，退出码 0。若没有 pandoc，先 `brew install pandoc` 再跑，不要改测试去跳过。

- [ ] **Step 8: 提交**

```bash
cd /Users/haotrr/Cody/haotrr/recto
git add templates/chrome.html templates/home.html templates/post.html templates/feed.xml styles.css gen.sh
git commit -m "$(cat <<'EOF'
用 gen.sh 从 Markdown 生成首页、文章和 RSS。

EOF
)"
```

---

### Task 3: 空站和校验失败

**Files:**
- Create: `testdata/empty/.gitkeep`
- Create: `testdata/bad/notes.md`
- Create: `testdata/dup/2026-09-10-same.md`
- Create: `testdata/dup/2026-01-01-same.md`
- Modify: `test.sh`
- Test: `test.sh`

**Interfaces:**
- Consumes: Task 2 的 `gen.sh`，同一套 `POSTS_DIR` / `OUT_DIR`。
- Produces: `test.sh` 额外覆盖空站、坏文件名、重复 slug；失败时退出码非 0，且不得在失败后留下 `$OUT_DIR/index.html`。

- [ ] **Step 1: 写失败用例夹具**

`testdata/empty/.gitkeep` 为空文件。

`testdata/bad/notes.md`：

```markdown
---
title: 坏文件名
---

这篇文件名不合法。
```

`testdata/dup/2026-09-10-same.md`：

```markdown
---
title: 第一篇同 slug
---

重复 slug 甲。
```

`testdata/dup/2026-01-01-same.md`：

```markdown
---
title: 第二篇同 slug
---

重复 slug 乙。
```

- [ ] **Step 2: 用下面这份完整 `test.sh` 覆盖旧文件**

```bash
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
```

- [ ] **Step 3: 跑全套测试**

Run: `cd /Users/haotrr/Cody/haotrr/recto && ./test.sh`

Expected: 四行 PASS：`happy-path`、`empty-site`、`bad-filename`、`duplicate-slug`。若失败却写出了 `$OUT_DIR/index.html`，检查 `gen.sh` 是否在 python 失败后仍执行 `cp`；`set -euo pipefail` 必须保留，python 调用不能跟 `|| true`。

- [ ] **Step 4: 提交**

```bash
cd /Users/haotrr/Cody/haotrr/recto
git add testdata/empty/.gitkeep testdata/bad/notes.md testdata/dup/2026-09-10-same.md testdata/dup/2026-01-01-same.md test.sh gen.sh
git commit -m "$(cat <<'EOF'
补上空站、坏文件名和重复 slug 的校验。

EOF
)"
```

---

### Task 4: 示例稿和仓库根上的生成物

**Files:**
- Create: `posts/2026-09-10-hello.md`
- Create: `index.html`（生成）
- Create: `p/hello/index.html`（生成）
- Create: `feed.xml`（生成）
- Create: `README.md`

**Interfaces:**
- Consumes: `./gen.sh` 默认 `POSTS_DIR=$ROOT/posts`、`OUT_DIR=$ROOT`。
- Produces: 仓库根可被静态服务器直接打开；示例稿标题「你好，Recto」。

- [ ] **Step 1: 写示例稿**

`posts/2026-09-10-hello.md`：

```markdown
---
title: 你好，Recto
---

这是 Recto 的第一篇示例稿，用来打通生成和发布。
```

- [ ] **Step 2: 在仓库根生成**

Run: `cd /Users/haotrr/Cody/haotrr/recto && ./gen.sh`

Expected: 生成 `index.html`、`p/hello/index.html`、`feed.xml`。`index.html` 含「你好，Recto」。不要出现 `p/newer/`。

- [ ] **Step 3: 写 `README.md`**

```markdown
# Recto

haotrr 的成稿站。线上：https://recto.haotrr.com

## 写一篇

1. 在 `posts/` 新增 `YYYY-MM-DD-slug.md`。
2. 文首写 `title`，可选 `summary`（只进 RSS）。
3. 运行 `./gen.sh`。
4. 提交 Markdown 和生成出的 `index.html`、`p/`、`feed.xml`。
5. push `main`，GitHub Action 会发布，不再跑生成。

依赖：pandoc、python3。安装：`brew install pandoc`。

## 本地看

先跑 `./test.sh`，再跑 `./gen.sh`，然后 `python3 -m http.server 4173`。
打开 http://127.0.0.1:4173 、一篇文章和 http://127.0.0.1:4173/feed.xml 。
```

- [ ] **Step 4: 再跑测试**

Run: `cd /Users/haotrr/Cody/haotrr/recto && ./test.sh`

Expected: 仍是四行 PASS。

- [ ] **Step 5: 提交**

```bash
cd /Users/haotrr/Cody/haotrr/recto
git add posts/2026-09-10-hello.md index.html p/hello/index.html feed.xml README.md
git commit -m "$(cat <<'EOF'
加入示例稿并生成可发布的静态页。

EOF
)"
```

---

### Task 5: GitHub Pages 发布文件

**Files:**
- Create: `CNAME`
- Create: `.nojekyll`
- Create: `.github/workflows/pages.yml`

**Interfaces:**
- Consumes: 仓库根已是可发布静态站。
- Produces: push `main` 时用官方 Pages Action 发布根目录；不安装 pandoc，不跑 `gen.sh`。

- [ ] **Step 1: 写 `CNAME` 和 `.nojekyll`**

`CNAME` 只有一行：

```
recto.haotrr.com
```

`.nojekyll` 为空文件。

- [ ] **Step 2: 写 `.github/workflows/pages.yml`**

```yaml
name: pages

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: .
      - id: deployment
        uses: actions/deploy-pages@v4
```

工作流里不能出现 `pandoc`、`gen.sh`、`test.sh`。

- [ ] **Step 3: 确认测试和发布文件**

Run:

```bash
cd /Users/haotrr/Cody/haotrr/recto
./test.sh
test -f CNAME
test -f .nojekyll
test -f .github/workflows/pages.yml
! grep -E 'gen\.sh|pandoc' .github/workflows/pages.yml
```

Expected: 测试 PASS；三个文件存在；workflow 不含 `gen.sh` 或 `pandoc`。

- [ ] **Step 4: 提交**

```bash
cd /Users/haotrr/Cody/haotrr/recto
git add CNAME .nojekyll .github/workflows/pages.yml
git commit -m "$(cat <<'EOF'
加上 GitHub Pages 发布，不在 CI 里生成。

EOF
)"
```

DNS 和 GitHub 仓库的 Pages / 自定义域在仓库外配置，不在本任务里做。

---

## Self-review

**Spec coverage**

| Spec | Task |
| --- | --- |
| 第四站、只放成稿、不管门户 | 全局约束，无代码 |
| `/`、`/p/<slug>/`、`/feed.xml` | Task 2、Task 4 |
| `YYYY-MM-DD-slug.md` + `title` / `summary` | Task 1、Task 2 |
| 同一套纸页变量和顶栏 | Task 2 |
| 首页无摘要、空站文案 | Task 2、Task 3 |
| RSS summary 或正文开头 160 字 | Task 1、Task 2 |
| 先写临时目录再替换生成物 | Task 2、Task 3 |
| 坏文件名 / 重复 slug 失败 | Task 3 |
| 示例稿 | Task 4 |
| Action 只发布 | Task 5 |
| `CNAME` / `.nojekyll` | Task 5 |

**Placeholder scan:** 无 TBD。`gen.sh` 空站节点用 `'<p class="empty">还没有文章。</p>'`。

**Type consistency:** 全程 `POSTS_DIR`、`OUT_DIR`、占位符名字与 spec 一致。slug 来自文件名，permalink 为 `$SITE_URL/p/<slug>/`。
