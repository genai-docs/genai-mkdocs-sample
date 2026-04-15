# ハンズオン環境 現状整理

> 確認日時: 2026-04-16

## 1. サブスクリプション情報

| 項目 | 値 |
|---|---|
| サブスクリプション名 | Visual Studio Enterprise サブスクリプション |
| サブスクリプションID | `fc7753ed-2e69-4202-bb66-86ff5798b8d5` |
| テナントID | `fe689afa-3572-4db9-8e8a-0f81d5a9d253` |
| 状態 | Enabled |

## 2. リソースグループ

| 項目 | 値 |
|---|---|
| 名前 | `rg-genai-mkdocs-sample-handson` |
| リージョン | Japan East |
| プロビジョニング状態 | Succeeded |

## 3. リソース一覧

| # | リソース名 | 種別 | 作成日時 |
|---|---|---|---|
| 1 | `acrgenaimkdocssamplefc7753ed` | Container Registry | 2026-04-15 00:21 |
| 2 | `id-genai-mkdocs-sample-handson` | User Assigned Managed Identity | 2026-04-15 00:39 |
| 3 | `workspace-rggenaimkdocssamplehandsonIi9M` | Log Analytics Workspace | 2026-04-15 00:40 |
| 4 | `cae-genai-mkdocs-sample-handson` | Container Apps Environment | 2026-04-15 00:41 |
| 5 | `handson-user-01` | Container App | 2026-04-15 00:45 |

## 4. 各リソースの詳細

### 4.1 Azure Container Registry

| 項目 | 値 |
|---|---|
| 名前 | `acrgenaimkdocssamplefc7753ed` |
| ログインサーバー | `acrgenaimkdocssamplefc7753ed.azurecr.io` |
| SKU | Basic |
| 管理者ユーザー | 無効 |
| パブリックアクセス | 有効 |

**リポジトリ:**

| リポジトリ | タグ |
|---|---|
| `handson-env` | `c277e74` |

### 4.2 User Assigned Managed Identity

| 項目 | 値 |
|---|---|
| 名前 | `id-genai-mkdocs-sample-handson` |
| Client ID | `25633b0b-60cd-44f0-9bb1-2885cdf1b326` |
| Principal ID | `070bb510-40b7-47c4-ab80-d0d2f0ca6723` |

**ロール割り当て:**

| ロール | スコープ |
|---|---|
| AcrPull | `acrgenaimkdocssamplefc7753ed` (Container Registry) |

### 4.3 Log Analytics Workspace

| 項目 | 値 |
|---|---|
| 名前 | `workspace-rggenaimkdocssamplehandsonIi9M` |
| SKU | PerGB2018 |
| 保持期間 | 30日 |

### 4.4 Container Apps Environment

| 項目 | 値 |
|---|---|
| 名前 | `cae-genai-mkdocs-sample-handson` |
| リージョン | Japan East |
| デフォルトドメイン | `yellowplant-141d0d8a.japaneast.azurecontainerapps.io` |
| 静的IP | `48.218.105.180` |
| プロビジョニング状態 | Succeeded |

### 4.5 Container App: handson-user-01

| 項目 | 値 |
|---|---|
| 名前 | `handson-user-01` |
| FQDN | `handson-user-01.yellowplant-141d0d8a.japaneast.azurecontainerapps.io` |
| 実行状態 | Running |
| ワークロードプロファイル | Consumption |
| 最終更新 | 2026-04-15 11:52 |

**コンテナ設定:**

| 項目 | 値 |
|---|---|
| イメージ | `acrgenaimkdocssamplefc7753ed.azurecr.io/handson-env:c277e74` |
| CPU | 1.0 vCPU |
| メモリ | 2 GiB |
| エフェメラルストレージ | 4 GiB |

**Ingress設定:**

| 項目 | 値 |
|---|---|
| 外部公開 | 有効 |
| ターゲットポート | 8080 (code-server) |
| トランスポート | Auto |
| HTTP非暗号化通信 | 不許可 |

**スケール設定:**

| 項目 | 値 |
|---|---|
| 最小レプリカ数 | 1 |
| 最大レプリカ数 | 1 |
| クールダウン期間 | 300秒 |

**環境変数:**

| 変数名 | 値のソース |
|---|---|
| `PASSWORD` | シークレット `code-server-password` |

**認証・レジストリ:**

- マネージドID (`id-genai-mkdocs-sample-handson`) を使用してACRからイメージをプル

## 5. 設計書との対応状況

| 設計書の項目 | 状態 | 備考 |
|---|---|---|
| Azure Container Registry | 構築済み | Basic SKU、イメージ `handson-env:c277e74` がプッシュ済み |
| Container Apps Environment | 構築済み | japaneast、Log Analytics連携済み |
| Container App (参加者ごと) | 1台構築済み | `handson-user-01` がRunning状態 |
| code-server (port 8080) | 構成済み | Ingressで外部公開、HTTPS |
| パスワード認証 | 構成済み | シークレット `code-server-password` で設定 |
| min-replicas=1 | 設定済み | スケールイン防止 |
| マネージドIDによるACRプル | 構成済み | AcrPullロール割り当て済み |
