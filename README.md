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
