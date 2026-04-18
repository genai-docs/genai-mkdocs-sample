FROM ghcr.io/genai-docs/handson-env:latest

# ベースのハンズオンイメージに含まれる主要構成（devcontainer でもそのまま流用）:
#   - Debian 12 + Python 3.13 (devcontainers/python ベース)
#   - Node.js 24 / pnpm / uv
#   - Playwright Chromium (--with-deps 導入済)
#   - WeasyPrint / Marp 用システム Chromium / フォント
#
# DevContainer では code-server は使わず VS Code が直接接続する。
# ベースの ENTRYPOINT（code-server 起動）は devcontainer が自動的に上書きする。
# DevContainer 固有の追加パッケージ・設定があればここに記述する。
