# 生成AI時代のドキュメント基盤

生成AI時代におけるドキュメント基盤テンプレート。

- デモサイト
    - [GitHub Pages](https://genai-docs.github.io/genai-mkdocs-sample/)
    - [Azure Static Web Apps](https://white-stone-0b8d2c100.4.azurestaticapps.net/)

特徴：

1. ヒューマン & AIフレンドリー
2. ポータブル

人が書きやすく読みやすいドキュメントで、AIによる生成・レビュー・活用が容易で、かつPDF形式での配布も可能なドキュメント基盤を提供する。

具体的には以下の要素を備えている：

- Markdownによる文書記述
- Mermaidによる図表作成
- Draw.ioによるSVG図表作成
- textlintによる品質チェック・フィックス
- ハイブリッド公開戦略：
    - **GitHub Pages**： 正式文書の公開用。GitHub Enterprise のリポジトリ権限により、社内の非開発者を含む広範なユーザー（人数制限なし）への認証付き公開を実現（非Enterpriseの場合はSWAの無料プランで代替可能）
    - **Azure Static Web Apps (SWA)**： 開発・プレビュー用。Pull Request 時にプレビュー環境を自動生成。GitHub ActionsによるGitHubとSWAの権限の自動同期を提供（オプション）
- 静的サイト全体を1つのPDFにまとめて配布可能

## 開発環境

DevContainerかAzure Container Appsを利用した、参加者のローカル環境に依存しない統一されたハンズオン実行環境を提供する。

ビルド済みイメージをローカルで実行する場合は、以下のように `docker run` を利用する。

```bash
docker run --rm -it \
  -p 8080:8080 \
  -e PASSWORD=changeme \
  spec-driven-docs-infra:latest
```

起動後は `http://localhost:8080` にアクセスし、指定したパスワードで `code-server` にログインする。

- [Azure Container Appsを利用したハンズオン環境構築ガイド](Hands-on.md)
- [環境情報](Environment.md)
