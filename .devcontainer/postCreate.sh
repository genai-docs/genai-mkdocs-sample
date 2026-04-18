#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi

if ! grep -Fq 'eval "$(~/.local/bin/mise activate bash)"' "$HOME/.bashrc"; then
  printf '\n%s\n' 'eval "$($HOME/.local/bin/mise activate bash)"' >> "$HOME/.bashrc"
fi

eval "$($HOME/.local/bin/mise activate bash)"

echo "=== [1/2] Installing tools and project dependencies (mise run setup) ==="
mise run setup

echo "=== [2/2] Listing available mise tasks ==="
mise tasks ls

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Available commands:"
echo "  pnpm mkdocs                             - Start MkDocs live preview (http://localhost:8000)"
echo "  pnpm mkdocs:build                       - Build MkDocs PDF (Mermaid→SVG→PNG included)"
echo "  pnpm marp                               - Start Marp slide preview server with watch"
echo "  pnpm marp:build                         - Build Marp slides to PDF"
echo "  pnpm lint:text                          - Run textlint"
echo "  pnpm lint:text:fix                      - Fix textlint issues"
echo "  mise run build-image -- [args]          - Run Build-Image.ps1"
echo "  mise run deploy-handson-env -- [args]   - Run Deploy-HandsonEnv.ps1"
echo "  mise run update-handson-image -- [args] - Run Update-HandsonImage.ps1"
echo "  mise run get-handson-env -- [args]      - Run Get-HandsonEnv.ps1"
echo "  mise run remove-handson-env -- [args]   - Run Remove-HandsonEnv.ps1"
echo "  mise run test                           - Run Pester tests"
