#!/bin/bash
set -euo pipefail

echo "=== [1/5] Installing system dependencies ==="
# The Node feature may leave a legacy Yarn apt source behind. This workspace
# uses Corepack for package managers, so the external Yarn repository is not
# required and can break apt-get update if its signing key is missing.
if [ -f /etc/apt/sources.list.d/yarn.list ]; then
  sudo rm -f /etc/apt/sources.list.d/yarn.list
fi

sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  chromium \
  libpango-1.0-0 \
  libpangoft2-1.0-0 \
  libpangocairo-1.0-0 \
  libcairo2 \
  libgdk-pixbuf2.0-0 \
  libharfbuzz0b \
  libfontconfig1 \
  libffi8 \
  shared-mime-info \
  fonts-noto-cjk \
  fonts-liberation

echo "=== [2/5] Installing uv ==="
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

echo "=== [3/5] Installing Python dependencies ==="
uv sync

echo "=== [4/5] Installing Playwright browser ==="
uv run playwright install chromium

echo "=== [5/5] Setting up pnpm and Node.js dependencies ==="
corepack enable
corepack prepare pnpm@10.27.0 --activate
pnpm install

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Available commands:"
echo "  pnpm mkdocs           - Start MkDocs live preview (http://localhost:8000)"
echo "  pnpm mkdocs:build     - Build MkDocs static site"
echo "  pnpm mkdocs:build:svg - Render Mermaid diagrams to SVG"
echo "  pnpm mkdocs:pdf       - Generate PDF"
echo "  pnpm lint:text        - Run textlint"
echo "  pnpm lint:text:fix    - Fix textlint issues"
