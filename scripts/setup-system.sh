#!/bin/bash
# ローカル Linux 環境向けシステム依存パッケージ導入スクリプト
# Debian/Ubuntu 系で sudo apt-get install を実行する
# WeasyPrint (PDF 生成)、Marp (Puppeteer)、Playwright の Chromium 依存を一括導入する
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get が見つかりません。Debian/Ubuntu 系以外は未対応です。" >&2
    exit 1
fi

# libasound2 は Debian 12 系、libasound2t64 は Debian 13 / Ubuntu 24.04 系で命名が変わる
if apt-cache show libasound2t64 >/dev/null 2>&1; then
    LIBASOUND_PKG=libasound2t64
else
    LIBASOUND_PKG=libasound2
fi

PACKAGES=(
    # Marp / Puppeteer 用システム Chromium
    chromium
    # WeasyPrint 依存 (Pango / Cairo / HarfBuzz / フォント)
    libpango-1.0-0
    libpangoft2-1.0-0
    libpangocairo-1.0-0
    libcairo2
    libgdk-pixbuf2.0-0
    libharfbuzz0b
    libfontconfig1
    libffi8
    shared-mime-info
    fonts-noto-cjk
    fonts-liberation
    # Playwright Chromium 追加依存
    "$LIBASOUND_PKG"
    libatk-bridge2.0-0
    libatk1.0-0
    libatspi2.0-0
    libcups2
    libdbus-1-3
    libdrm2
    libgbm1
    libnspr4
    libnss3
    libx11-6
    libxcb1
    libxcomposite1
    libxdamage1
    libxext6
    libxfixes3
    libxkbcommon0
    libxrandr2
)

echo ">>> sudo apt-get update"
sudo apt-get update -qq

echo ">>> sudo apt-get install (${#PACKAGES[@]} packages)"
sudo apt-get install -y --no-install-recommends "${PACKAGES[@]}"

echo ">>> Done. 次に: mise run setup"
