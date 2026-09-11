# Recto

haotrr 的成稿站。线上：https://recto.haotrr.com

## 写一篇

1. 在 `posts/` 新增 `YYYY-MM-DD-slug.md`。
2. 文首写 `title`，可选 `summary`（只进 RSS）。
3. 运行 `./gen.sh`。
4. 提交 Markdown 和生成出的 `index.html`、`p/`、`feed.xml`。
5. push `main`，GitHub Action 会发布，不再跑生成。

隐藏文章：在文首增加 `hide: true`，再运行 `./gen.sh`。文章将从首页、RSS 和文章页中移除；省略或设为 `hide: false` 则正常发布。发布仅上传站点生成物，不包含 Markdown 源文件；源文件和 Git 历史仍保留在仓库中。

依赖：pandoc、python3。安装：`brew install pandoc`。

## 本地看

先跑 `./test.sh`，再跑 `./gen.sh`，然后 `python3 -m http.server 4173`。
打开 http://127.0.0.1:4173 、一篇文章和 http://127.0.0.1:4173/feed.xml 。
