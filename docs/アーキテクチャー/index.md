---
title: アーキテクチャ
---

# アーキテクチャ

このセクションでは、ドキュメント基盤の技術的な仕組みと設定について説明する。

## ドキュメント

- [ワークフロー アーキテクチャ](workflow-architecture.md) - GitHub Actionsワークフローの実行条件と内部構造
- [テキスト校正](text-validation.md) - textlintによる日本語文書の品質管理

## デプロイ構成

サイトのデプロイには[`nuitsjp/azure-blob-storage-site-deploy`](https://github.com/nuitsjp/azure-blob-storage-site-deploy)を利用している。プレフィックス方式によるマルチ環境配置、OIDC認証、PRステージングの自動作成・削除などの設計意図は、該当Actionの[README（日本語版）](https://github.com/nuitsjp/azure-blob-storage-site-deploy/blob/main/README.ja.md)を参照する。
