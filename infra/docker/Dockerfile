FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

# システムパッケージ（フォント・ブラウザ・レンダリング）
RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends \
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
        fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# code-server（ブラウザ版 VS Code）
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable

# Marp / Puppeteer 用: システム Chromium を使用し、バンドル版のダウンロードを抑止
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    CHROME_PATH=/usr/bin/chromium \
    CHROME_NO_SANDBOX=true

USER vscode

# uv（Python パッケージマネージャー）
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/vscode/workspace/node_modules/.bin:/home/vscode/.local/bin:${PATH}"

# CLI: Claude Code / Cursor（vscode ユーザーの ~/.local/bin に導入）
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && curl -fsSL https://cursor.com/install | bash

# プロジェクトファイルのコピー（WORKDIR はディレクトリを root 所有で作成するため、先に mkdir する）
RUN mkdir -p /home/vscode/workspace
WORKDIR /home/vscode/workspace
COPY --chown=vscode:vscode . .

# Python 依存関係
RUN uv sync --frozen

# Node.js 依存関係
RUN corepack prepare pnpm@10.27.0 --activate \
    && pnpm install --frozen-lockfile

# VS Code 拡張機能（code-server 用、Open VSX から取得）
RUN code-server --install-extension ms-python.python \
    && code-server --install-extension yzhang.markdown-all-in-one \
    && code-server --install-extension davidanson.vscode-markdownlint \
    && code-server --install-extension bierner.markdown-mermaid \
    && code-server --install-extension hediet.vscode-drawio \
    && code-server --install-extension marp-team.marp-vscode \
    && code-server --install-extension tomoki1207.pdf

# Open VSX 未公開の拡張は Visual Studio Marketplace から .vsix を直接取得して導入
ARG TEXTLINT_VSIX_VERSION=0.12.1
ARG GITHUB_COPILOT_CHAT_VSIX_VERSION=0.44.1
RUN set -e; \
    for spec in \
        "3w36zj6/textlint/${TEXTLINT_VSIX_VERSION}" \
        "github/copilot-chat/${GITHUB_COPILOT_CHAT_VSIX_VERSION}" \
    ; do \
        publisher=$(echo "$spec" | cut -d/ -f1); \
        name=$(echo "$spec" | cut -d/ -f2); \
        version=$(echo "$spec" | cut -d/ -f3); \
        vsix="/tmp/${publisher}.${name}.vsix"; \
        echo ">>> Fetching ${publisher}.${name} v${version}"; \
        curl -fsSL --compressed -o "$vsix" \
            "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${publisher}/vsextensions/${name}/${version}/vspackage"; \
        code-server --install-extension "$vsix"; \
        rm "$vsix"; \
    done

# code-server 用 Marp 拡張のデフォルト設定（システム Chromium を利用）
RUN mkdir -p /home/vscode/.local/share/code-server/User \
    && printf '%s\n' '{' \
        '  "markdown.marp.chromePath": "/usr/bin/chromium"' \
        '}' > /home/vscode/.local/share/code-server/User/settings.json

# login shell でも node_modules/.bin / ~/.local/bin が参照できるようにする
# （/etc/profile が PATH を上書きするため）
RUN printf '\n# Augment PATH for project-local bins\nexport PATH="/home/vscode/workspace/node_modules/.bin:/home/vscode/.local/bin:$PATH"\n' \
        >> /home/vscode/.bashrc \
    && printf '\n# Augment PATH for project-local bins\nexport PATH="/home/vscode/workspace/node_modules/.bin:/home/vscode/.local/bin:$PATH"\n' \
        >> /home/vscode/.profile

EXPOSE 8080
ENTRYPOINT ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password", "/home/vscode/workspace"]
