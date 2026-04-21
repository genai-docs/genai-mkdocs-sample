# 生成AI時代のドキュメント基盤

生成AI時代におけるドキュメント基盤テンプレート。

人が書きやすく読みやすいMarkdownを中心に、`MkDocs`、Mermaid、Draw.io、Marp、PDF出力を組み合わせた文書基盤のサンプルである。主役はサンプル本体であり、実行環境（Dockerイメージ・Azureデプロイ）は別リポジトリ [genai-docs/genai-docs-env](https://github.com/genai-docs/genai-docs-env) に分離している。

- [デモサイト](https://stgenaimkdocssampleprod.z11.web.core.windows.net/genai-mkdocs-sample/main/)

## 最短セットアップ

ローカル開発では `mise` を共通のエントリポイントとして利用する。初回セットアップは次の通り。

```bash
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
exec "$SHELL"
mise install
mise run setup-system  # Debian/Ubuntu のみ、sudo 実行（初回だけ）
mise run setup
```

- `setup-system` はaptでChromium / フォント / WeasyPrint / PlaywrightのChromium依存を導入する。sudoが必要なので初回に1度だけ実行する。
- `setup` は `uv sync` / `pnpm install` / `playwright install chromium` を実行する。sudoは不要で何度でも実行できる。

主なコマンド：

```bash
pnpm mkdocs
pnpm mkdocs:build
pnpm marp
pnpm marp:build
pnpm lint:text
```

## リポジトリ構成

- サンプル本体： `docs/`, `mkdocs.yml`, `pyproject.toml`, `package.json`, `mise.toml`
- DevContainer設定： `.devcontainer/`（`ghcr.io/genai-docs/genai-docs-env:latest` をベースに起動）
- ローカル向けapt依存導入： `scripts/setup-system.sh`

実行環境（Dockerイメージ定義、Azure Container Appsデプロイ、Bicep、GHCR公開CI）は [genai-docs/genai-docs-env](https://github.com/genai-docs/genai-docs-env) にある。

## 詳細ドキュメント

- [ドキュメントサイトのホーム](docs/index.md)
- [ユーザーガイド](docs/usage-guide.md)
- [実行環境の概要](docs/実行環境/index.md)
- [ハンズオン環境設計](docs/実行環境/handson.md)
- [ハンズオン環境情報](docs/実行環境/environment.md)

## ハンズオン用イメージ

ハンズオン配布用code-serverコンテナーのビルド・ローカル起動・Azureデプロイ・イメージ更新・CI公開の手順は、[genai-docs/genai-docs-env](https://github.com/genai-docs/genai-docs-env) のREADMEを参照する。
