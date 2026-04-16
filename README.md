# 生成AI時代のドキュメント基盤

生成AI時代におけるドキュメント基盤テンプレート。

人が書きやすく読みやすい Markdown を中心に、`MkDocs`、Mermaid、Draw.io、Marp、PDF 出力を組み合わせた文書基盤のサンプルである。主役はサンプル本体であり、`.devcontainer/` や `infra/` 配下にはこのリポジトリ専用の開発・配布環境を同居させている。

- デモサイト
  - [GitHub Pages](https://genai-docs.github.io/genai-mkdocs-sample/)
  - [Azure Static Web Apps](https://white-stone-0b8d2c100.4.azurestaticapps.net/)

## 最短セットアップ

ローカル開発では `mise` を共通のエントリポイントとして利用する。初回セットアップは次の通り。

```bash
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
exec "$SHELL"
mise install
mise run setup
```

主なコマンド:

```bash
mise run mkdocs
mise run mkdocs:build
mise run mkdocs:build:svg
mise run mkdocs:pdf
mise run lint:text
mise run infra:test
mise run infra:deploy-handson-env -- -UserCount 20
```

## リポジトリ構成

- サンプル本体: `docs/`, `mkdocs.yml`, `pyproject.toml`, `package.json`, `mise.toml`
- ローカル開発環境: `.devcontainer/`, `infra/docker/`
- ハンズオン運用: `infra/azure/`, `infra/scripts/`, `settings.template.json`

## 詳細ドキュメント

- [ドキュメントサイトのホーム](docs/index.md)
- [利用方法](docs/usage-guide.md)
- [ユーザー環境構築](docs/user-environment-setup.md)
- [実行環境の概要](docs/実行環境/index.md)
- [ハンズオン環境設計](docs/実行環境/handson.md)
- [ハンズオン環境情報](docs/実行環境/environment.md)

## 補足

### ハンズオン用イメージをブラウザーで利用する

ハンズオン配布用のコンテナーイメージは、VS Code UI をブラウザーから操作できる [code-server](https://github.com/coder/code-server) を同梱している。手元で動作確認する手順は次の通り。

**前提**

- Docker が稼働していること
- PowerShell（`pwsh`）が利用できること（`mise install` で導入される）
- リポジトリで `pnpm install` 済みであること

**手順**

1. イメージをビルドする。既定タグは現在の Git コミットハッシュ（短縮形）を使用する。

    ```bash
    pnpm infra:build-image
    ```

2. コンテナーを起動する。`-Detach` を付けるとバックグラウンド起動になる。

    ```bash
    pnpm infra:run-image
    pnpm infra:run-image -- -Detach
    ```

3. ブラウザーで `http://localhost:8080` を開き、パスワード `changeme` で `code-server` にログインする。`/home/vscode/workspace` にリポジトリが展開された状態で VS Code UI が利用できる。内蔵ターミナルから `pnpm mkdocs` なども実行可能である。

4. 停止する。フォアグラウンド起動時は Ctrl+C、`-Detach` 起動時は `docker stop handson-env-local` を使う。

**オプション**

`Run-Image.ps1` は以下のパラメーターを受け付ける。`pnpm` から渡す際は `--` の後に続ける。

| パラメーター | 既定値 | 説明 |
| --- | --- | --- |
| `-ImageTag` | Git 短縮ハッシュ | 起動するイメージタグ |
| `-Port` | `8080` | ホスト側に公開するポート |
| `-Password` | `changeme` | code-server ログインパスワード |
| `-ContainerName` | `handson-env-local` | コンテナー名 |
| `-Detach` | 無効 | バックグラウンド起動 |

```bash
pnpm infra:run-image -- -Port 18080 -Password s3cret -Detach
```

### ハンズオンイメージを CI からビルド・公開する

GitHub Actions でハンズオンイメージをビルドし、リリースタグを契機に GitHub Container Registry (`ghcr.io`) へ公開する構成を用意している。

**ワークフロー**

| ファイル | トリガー | 動作 |
| --- | --- | --- |
| `.github/workflows/build-handson-image.yml` | `main` への push / PR（`infra/docker/**`, `pyproject.toml`, `uv.lock`, `package.json`, `pnpm-lock.yaml`, 当ワークフロー変更時） | イメージをビルドのみ実施（公開なし） |
| `.github/workflows/publish-handson-image.yml` | `Release-v*` タグの push、または `workflow_dispatch` でバージョンを指定 | ビルド＋ `ghcr.io/<owner>/handson-env:<version>` と `:latest` で公開 |

**GHCR 公開に必要な設定**

1. リポジトリの **Settings → Actions → General → Workflow permissions** を **"Read and write permissions"** に設定する。`publish-handson-image.yml` は `GITHUB_TOKEN` に `packages: write` を要求するため、Personal Access Token (PAT) などの追加シークレットは不要である。
2. 初回公開後、`https://github.com/users/<owner>/packages/container/handson-env/settings` で以下を設定する。
    - **Manage Actions access**: 当リポジトリに `Write` を付与（同一オーナー配下の別リポジトリから publish する場合のみ必要）
    - **Danger Zone → Change visibility**: 匿名 pull を許可する場合は `public` へ変更
3. `settings.local.json` の `ghcrImage` がリリース先と一致していることを確認する（例: `ghcr.io/genai-docs/handson-env`）。

**リリースタグを発行する**

`Release-v<semver>` 形式のタグを発行する補助スクリプトを用意している。既定動作は最新の `Release-v*` タグのパッチバージョンを +1 する。

```bash
# 例: 最新が Release-v1.1.3 → Release-v1.1.4 を作成して push
pnpm infra:release-tag

# 明示的にバージョンを指定する
pnpm infra:release-tag -- -Version 1.2.0

# タグ作成のみでリモートへ push しない（検証用）
pnpm infra:release-tag -- -SkipPush
```

前提:

- `main` ブランチ上で実行すること（スクリプト内でチェックされる）
- 作業ツリーがクリーンであること
- `origin` への push 権限があること

タグが push されると `publish-handson-image.yml` が起動し、`ghcr.io/<owner>/handson-env:<version>` と `:latest` が発行される。
