# ハンズオン実行環境

この文書は、ハンズオン実行環境の全体像と運用導線をまとめたものである。Azureリソース定義や各パラメーターの詳細は文書に重複記載せず、実装そのものを正としてBicep / スクリプトを参照する。

## リポジトリ分離

ハンズオン実行環境（Dockerイメージ、Azure Container Apps運用スクリプト、Bicep、GHCR公開CI）は別リポジトリ [genai-docs/genai-docs-env](https://github.com/genai-docs/genai-docs-env) で管理している。当リポジトリはサンプル本体に集中し、実行環境の更新はenvリポジトリ側で完結する。

## 構成概要

参加者がブラウザのみで作業できるよう、Azure Container Apps上に参加者ごとの `code-server` 環境をデプロイする。コンテナイメージは `ghcr.io` に格納し、Container Appsから取得する。

```text
参加者 (ブラウザ)
    │
    │ HTTPS + パスワード認証
    ▼
Container App (参加者ごと)
    │
    ├─ code-server : 8080
    └─ mkdocs serve : 8000
         ※ 参加者が必要に応じて起動
         ※ 外部公開はしない

        ↑
        │ 配置先
        │
Container Apps Environment
        │
        └─ ログ送信先: Log Analytics Workspace

        ↑
        │ イメージ取得
        │
GitHub Container Registry (ghcr.io)
```

## 実装との対応

環境構築に関わる主要ファイルはすべて [genai-docs-env](https://github.com/genai-docs/genai-docs-env) に存在する。

- インフラのエントリーポイント： `scripts/Deploy-GenaiDocsEnv.ps1`
- イメージビルド： `scripts/Build-Image.ps1`
- 環境削除： `scripts/Remove-GenaiDocsEnv.ps1`
- イメージ更新（RG温存）： `scripts/Update-GenaiDocsImage.ps1`
- 共有インフラ定義： `deploy/azure/main.bicep`
- 参加者用アプリ定義： `deploy/azure/container-app.bicep`
- 実行コンテナー定義： `Dockerfile`
- デプロイ設定： `settings.local.json`

詳細なAzureリソース定義、Container Appの構成、パラメーター、命名規則、出力値はBicepを参照すること。

## 運用フロー

### 構築

環境構築はenvリポジトリで `nr azure:deploy -- -UserCount <人数>` を実行する。スクリプトは `settings.local.json` を読み込み、Azure上へ共有インフラと参加者用Container App群をデプロイする。コンテナーイメージは事前にCIで `ghcr.io/genai-docs/genai-docs-env:latest` として公開されている前提である。

参加者情報の出力やログは、envリポジトリ直下の `genai-docs-out/` に保存される。

### 当日運用

参加者は配布されたURLとパスワードで `code-server` にログインする。空のworkspaceで起動するため、本リポジトリのサンプルを利用する場合は初回に `git clone` で展開する。`mkdocs serve` の起動は参加者の操作で行い、プレビューはコンテナー内部の `localhost:8000` を利用する前提である。

### 片付け

環境削除はenvリポジトリで `nr azure:remove -- -All` を利用する。削除対象の判定方法や一括削除の挙動はスクリプト実装を参照すること。

## 補足

- ハンズオン配布用の実行コンテナーはenvリポジトリの `Dockerfile` で定義し、CIで `ghcr.io/genai-docs/genai-docs-env:latest` として公開している。
- ローカル開発用Dev Containerは当リポジトリの `.devcontainer/Dockerfile` で同イメージの `:latest` をベースとして使う構成である。
- 実装詳細を文書へ転記しすぎると乖離しやすいため、構成や挙動の正確な確認はコードを優先する。
