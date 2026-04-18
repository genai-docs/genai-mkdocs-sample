# 利用方法

本ドキュメントでは、ドキュメント基盤の日常的な利用方法を説明する。

## 文書記述

MkDocsを起動してプレビューを確認しながら文書を記述する。

```shell
# ローカルプレビュー（http://127.0.0.1:8000）
pnpm mkdocs
```

## Pull Request作成前チェック

文書のリンク切れや、ドキュメント品質をチェックする。

```shell
# PDF ビルド（Mermaid の SVG/PNG 変換を含む本番相当）
pnpm mkdocs:build

# ドキュメント品質チェック（textlint）
pnpm lint:text

# ドキュメント品質チェック（自動修正）
pnpm lint:text:fix
```

## スライド

Marp スライドのプレビューと PDF 生成は以下で実行する。

```shell
# 変更監視つきプレビュー
pnpm marp

# PDF へビルド（docs/スライド/dist 配下に出力）
pnpm marp:build
```

## 実行コマンドの補足

ドキュメントのビルドや品質チェックは `package.json` の scripts に定義しており、`pnpm` から実行する。`infra/scripts` 配下の PowerShell スクリプトは `mise.toml` のタスクとして定義しており、`mise run` から実行する。両者は重複せず排他的に定義されている。

```shell
mise run test
mise run build-image
mise run deploy-handson-env -- -UserCount 20
mise run remove-handson-env -- -All
```
