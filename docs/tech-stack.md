# 技術スタック

このリポジトリで採用している主要な技術と、その用途をまとめる。

## ドキュメント生成

| 技術 | 用途 |
|------|------|
| Python + uv | MkDocs の実行環境と依存関係管理 |
| MkDocs + Material for MkDocs | 静的サイトジェネレーター |
| MkDocs プラグイン群 | Mermaid の SVG/PNG 変換、PDF 出力、表読込 |
| WeasyPrint | PDF 生成 |
| Noto CJK フォント | PDF での日本語レンダリング |

## 図表・スライド

| 技術 | 用途 |
|------|------|
| Mermaid | Markdown 内での図表作成 |
| Draw.io | SVG 図表作成 |
| Marp | Markdown スライド作成 |
| Chromium | Mermaid 変換と Marp のレンダリングに使用するブラウザエンジン |

## 品質チェック

| 技術 | 用途 |
|------|------|
| Node.js + pnpm | Marp と textlint の実行基盤 |
| textlint | ドキュメント品質チェック |

## 開発・ハンズオン環境

| 技術 | 用途 |
|------|------|
| Docker | devcontainer とハンズオン環境のコンテナー基盤 |
| code-server | ブラウザ版 VS Code（ハンズオン環境の IDE 本体） |
| VS Code 拡張機能 | Markdown / Mermaid / Draw.io / Marp / textlint などの執筆支援 |
