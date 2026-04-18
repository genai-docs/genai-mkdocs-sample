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
# 簡易ビルド（PRプレビュー相当）
pnpm mkdocs:build

# 本番Web用ビルド（MermaidのSVG化を含む）
pnpm mkdocs:build:svg

# ドキュメント品質チェック（textlint）
pnpm lint:text

# ドキュメント品質チェック（自動修正）
pnpm lint:text:fix
```

## PDF生成

正式公開版と同様に、Mermaid を PNG に変換して PDF を生成する。

### Windows

```shell
pnpm mkdocs:build:pdf
```

## 実行コマンドの補足

ドキュメントのビルドや品質チェックは `package.json` の scripts に定義しており、`pnpm` から実行する。`infra/scripts` 配下の PowerShell スクリプトは `mise.toml` のタスクとして定義しており、`mise run` から実行する。両者は重複せず排他的に定義されている。

```shell
mise run test
mise run build-image
mise run deploy-handson-env -- -UserCount 20
mise run remove-handson-env -- -All
```
