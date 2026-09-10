# Recto 个人成稿站设计

日期：2026-09-10  
状态：待审  
站点：https://recto.haotrr.com

## 1. 一句话

Recto 是 haotrr 站点家族里的成稿页：用 Markdown 写文章，Git 托管内容和生成后的 HTML，`gen.sh` 整站生成，GitHub Action 只负责发布到 GitHub Pages。

## 2. 在家族里的位置

| 站点 | 角色 | 写法 |
| --- | --- | --- |
| https://haotrr.com | 门户，只列当前项目 | 纸色、衬线签名、项目卡片 |
| https://page.haotrr.com | 摘录、备忘、随笔 | Markdown + `gen.sh`，一页长卷 |
| https://verso.haotrr.com | 阅读、书影、时间线 | 数据库、随手一条 |
| https://recto.haotrr.com | 成稿长文 | Markdown + `gen.sh`，一篇一页 |

Verso 的 PRD 已把 Recto 写成对页：Verso 是叶的背面，Recto 是正面。两边气质同一套纸页，单位不同：Verso 是帖，Recto 是篇。

本仓库不改门户。上线后在 haotrr.com 加一张 Recto 卡片，当作另一件事。

## 3. v1 范围

读者能看到的页面只有三个：

- `/`：按日期倒序的文章列表
- `/p/<slug>/`：一篇完整文章
- `/feed.xml`：全站 RSS

不做：标签、归档、About、搜索、评论、草稿、中英切换、相关文章、上一篇 / 下一篇、封面图、首页摘要、Hero、CTA、卡片栅格、友情链接条。

## 4. 仓库结构

```
recto/
  posts/                      只放成稿，一篇一个 md
    YYYY-MM-DD-slug.md
  templates/
    chrome.html               页头页脚
    home.html                 首页列表
    post.html                 文章页
    feed.xml                  RSS 骨架
  testdata/posts/             两篇固定稿，只给测试用
  styles.css                  从 Verso 抽同一套纸页变量
  gen.sh                      读 posts/，重写生成物
  test.sh                     用 testdata 跑生成并断言
  index.html                  生成：文章列表
  p/<slug>/index.html         生成：文章 permalink
  feed.xml                    生成
  CNAME                       recto.haotrr.com
  .nojekyll                   禁止 GitHub Pages 当 Jekyll 再处理
  .github/workflows/pages.yml 只发布，不生成
```

`posts/` 是源。`index.html`、`p/`、`feed.xml` 是生成物，和源一起提交。

## 5. 文章约定

文件名必须是 `YYYY-MM-DD-slug.md`。日期和 slug 都从文件名来。

- `YYYY-MM-DD` 必须是合法日历日。
- `slug` 只含小写字母、数字和连字符，不能为空、不能只是连字符。
- 两个文件不能抢同一个 slug。

文首 YAML：

```yaml
---
title: 文章标题
summary: 可选，只给 RSS 用
---
```

`title` 必填。`summary` 可选。两者都是单行标量，不做多行 YAML、不做嵌套。没有 `summary` 时，RSS 用正文纯文本的开头 160 个字，不够就全用。正文是普通 Markdown。v1 图片只用绝对 URL，仓库不设 `media/`，`gen.sh` 不拷图片。

仓库里的稿就是已发布。没有草稿目录，也没有 `draft` 字段。不想公开就不要提交到 `main`。

第一次提交放一篇很短的示例稿，只为打通生成和发布，不当正式文章。

## 6. 页面与视觉

不新发明皮肤。颜色、字体、栏宽、顶栏结构从 Verso 的 `internal/web/static/css/app.css` 抽同一套变量。

**纸页变量（浅色）**

- 背景 `oklch(0.985 0.008 85)`，正文 `oklch(0.22 0.02 55)`
- 强调蓝 `oklch(0.45 0.07 250)`，分割线 `oklch(0.9 0.012 85)`，meta `oklch(0.66 0.012 55)`
- 引用字色 `oklch(0.32 0.03 55)`
- 栏宽 `42rem`，页边 `1.5rem`，头像 `28px`

**字体**

- 签名、标题、文章正文：`"Iowan Old Style", "Palatino Linotype", Palatino, "Songti SC", "Noto Serif SC", Georgia, serif`
- 导航、日期、页脚：系统无衬线（与 Verso `--font-ui` 相同）
- 代码：系统等宽

暗色跟 `prefers-color-scheme`，不单独做开关。暗色变量同样从 Verso 拷。

**顶栏**

左侧圆点头像 + 衬线签名 `haotrr`，点签名回首页。右侧导航只有「文章」和「RSS」。当前站时「文章」高亮。不要链到 Verso / Page；互链仍放在门户。

**首页**

```
haotrr                         文章  RSS
────────────────────────────────────────
文章

标题一
2026-09-10

标题二
2026-09-08
```

- 小节标题「文章」用 Verso 的 `section-label`（小字、大写间距、meta 色）。
- 列表按文件名日期倒序。同一天按 slug 字母序，保证生成稳定。
- 标题用衬线，比正文大一号；日期用灰色 meta，写在标题下面。
- 有 `summary` 也不上首页。
- 空站：`还没有文章。`

**文章页**

```
haotrr                         文章  RSS
────────────────────────────────────────
标题
2026-09-10

正文
```

- 标题和日期在正文之上，没有卡片，没有作者栏。
- 正文处理：标题、段落、引用、列表、链接、行内代码、代码块、图片。
- 引用跟 Verso 接近：左 1px 细线、字色用 `--quote`。
- 回首页只靠顶栏签名。
- 页面语言 `zh-Hans`。`<title>` 为 `文章标题 · haotrr`。首页 `<title>` 为 `haotrr`。

**页脚**

`haotrr · RSS`，字号和颜色跟 Verso footer 一样。

**RSS**

- 地址固定 `/feed.xml`。
- `channel.title` 为 `haotrr`，`channel.link` 为 `https://recto.haotrr.com/`。
- 每篇：标题、permalink `https://recto.haotrr.com/p/<slug>/`、`pubDate`（文件名日期的 `00:00:00 +0800`）、description 为 `summary` 或正文开头。
- 空站仍输出合法 RSS 2.0：有 `rss/channel`，`title` / `link` / `description` 齐，没有 `item`。
- 顶栏和页脚都挂这个链接。

## 7. gen.sh

`gen.sh` 是唯一生成器。每次整站重跑，不增量、不缓存。

脚本头顶常量：

```
SITE_URL=https://recto.haotrr.com
SITE_NAME=haotrr
```

不另做配置文件。页面不出现作者栏。

默认：

- `POSTS_DIR=posts`
- `OUT_DIR=.`（仓库根）

测试时可覆盖这两个变量，把结果写到临时目录。

步骤：

1. 检查本机有 `pandoc`，以及 `templates/`、`styles.css` 在。
2. 扫 `$POSTS_DIR/*.md`。无匹配不算错误，按空站生成。
3. 用文首第一对 `---` 取出 YAML。只认单行 `title:` / `summary:`。校验文件名、`title`、slug 唯一。
4. 用 pandoc 把正文（去掉 YAML）转成 HTML：`--from markdown --to html --syntax-highlighting=none --wrap=none`。
5. 模板占位符是 `{{TITLE}}`、`{{DATE}}`、`{{SLUG}}`、`{{BODY}}`、`{{SUMMARY}}`、`{{PERMALINK}}`、`{{PUBDATE}}`、`{{ITEMS}}`、`{{EMPTY}}` 这类明文标记，由 `gen.sh` 做字符串替换，不用 Go template，也不用 `envsubst`。
6. 先写到临时目录。成功后只替换生成物：`index.html`、`p/`、`feed.xml`。每次都会丢掉旧的 `p/`，已删除的文章从站点消失。不碰 `posts/`、`templates/`、`styles.css`。
7. 当 `OUT_DIR` 不是仓库根时，把 `styles.css` 拷过去，保证预览能加上样式。发布用的根目录样式文件仍是仓库里那一份，脚本不覆盖它。

文章页和首页用相对路径引用 CSS 和 RSS：

- 首页：`styles.css`、`feed.xml`
- 文章：`../../styles.css`、`../../feed.xml`

这样本地直接打开文件也能看。

## 8. 出错

失败就退出码 1，不跳过坏文件，不留下半套页面。先写到临时目录，成功后再替换目标，避免中途失败把旧 `p/` 拆坏。

| 情况 | 行为 |
| --- | --- |
| 没有 pandoc | 退出，提示 `brew install pandoc` |
| 缺少模板或 `styles.css` | 退出，打印缺的路径 |
| 文件名不合法 | 退出，打印文件名和规则 |
| YAML 坏掉或缺 `title` | 退出，打印是哪一篇 |
| slug 冲突 | 退出，打印两个文件名 |
| 某篇 pandoc 失败 | 退出，不提交这次生成结果 |
| 本地改了 md 却没跑脚本 | Git 会看到源和生成物对不上；靠 diff 发现 |

GitHub Action 不跑 `gen.sh`，也不在 CI 里补生成。

## 9. 发布

`.github/workflows/pages.yml`：

- 触发：push 到 `main`
- 动作：用 GitHub 官方 Pages Action（`actions/configure-pages`、`upload-pages-artifact`、`deploy-pages`）发布仓库根目录
- 不安装 pandoc，不跑 `gen.sh`
- 源文件（`posts/`、`templates/`、`testdata/`）会出现在站点路径上，可以接受，不为发布另做白名单

根目录 `CNAME` 内容为 `recto.haotrr.com`。另放 `.nojekyll`，避免 Pages 把仓库当 Jekyll 站点。

DNS 和 GitHub Pages 自定义域在仓库外配置，本设计只要求仓库带上 `CNAME`。

日常发布：改 `posts/` → `./gen.sh` → 提交 md 和生成物 → push `main`。

## 10. 怎么验

`test.sh` 调 `gen.sh`，`POSTS_DIR=testdata/posts`，`OUT_DIR` 为临时目录。

`testdata/posts/` 固定两篇：

- `2026-09-10-newer.md`：有 `title` 和 `summary`
- `2026-01-01-older.md`：只有 `title`

断言：

1. 退出码 0，产出 `index.html`、`p/newer/index.html`、`p/older/index.html`、`feed.xml`。
2. 首页里 `newer` 的标题出现在 `older` 前面。
3. `p/newer/index.html` 含标题和 pandoc 转出的正文。
4. `feed.xml` 里 newer 用 `summary`，older 用正文开头。
5. 空目录生成成功：首页含「还没有文章。」，RSS 是合法空 channel。
6. 坏文件名（如 `notes.md`）时 `gen.sh` 退出码非 0。
7. 两篇相同 slug 时退出码非 0。

本地看真页面：在仓库根跑 `./gen.sh`，再用静态服务器打开，点首页、一篇文章、`/feed.xml`。

## 11. 明确不做

- 用 Go / goldmark 重写生成器
- 在 CI 里生成 HTML
- 把生成物排除出 Git
- 收编 Page，或把 Recto 做成新的 haotrr.com
- 草稿、标签、归档、About、搜索、评论、双语
- 发现流、登录、发帖后台

## 12. 已定选择

- 家族位置：第四站，只放成稿
- 页面：首页列表 + 文章 + RSS
- 视觉：和 Verso 同一套纸页
- 生成：HTML 进 Git，Action 只发布
- 源文件：`posts/YYYY-MM-DD-slug.md` + `title` / 可选 `summary`
