#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Installing dotfiles from: $DOTFILES_DIR"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MAC=true
    IS_LINUX=false
else
    IS_MAC=false
    IS_LINUX=true
fi

# ============================================
# Shell Configuration (run FIRST to set up PATH)
# ============================================
setup_shell() {
    echo "==> Setting up shell configuration..."

    if [ -f "$HOME/.zshrc" ]; then
        PROFILE_FILE="$HOME/.zshrc"
    else
        PROFILE_FILE="$HOME/.bashrc"
    fi

    touch "$PROFILE_FILE"

    DOTFILES_MARKER="# dotfiles-coder"
    if ! grep -q "$DOTFILES_MARKER" "$PROFILE_FILE" 2>/dev/null; then
        block_file="$(mktemp)"
        cat > "$block_file" << EOF

$DOTFILES_MARKER
export DOTFILES_CODER_DIR="$DOTFILES_DIR"
[ -f "\$DOTFILES_CODER_DIR/shell/exports.sh" ] && . "\$DOTFILES_CODER_DIR/shell/exports.sh"
case "\$-" in
  *i*) [ -f "\$DOTFILES_CODER_DIR/shell/aliases.sh" ] && . "\$DOTFILES_CODER_DIR/shell/aliases.sh" ;;
esac
EOF

        # Bash returns early for non-interactive shells in many default .bashrc
        # files. Insert before that guard so SSH remote commands get PATH too.
        if [ "$(basename "$PROFILE_FILE")" = ".bashrc" ] && grep -q 'case \$- in' "$PROFILE_FILE"; then
            tmp_profile="$(mktemp)"
            awk -v block_file="$block_file" '
                BEGIN {
                    while ((getline line < block_file) > 0) {
                        block = block line "\n"
                    }
                    close(block_file)
                }
                !inserted && $0 ~ /case \$- in/ {
                    printf "%s", block
                    inserted = 1
                }
                { print }
                END {
                    if (!inserted) {
                        printf "%s", block
                    }
                }
            ' "$PROFILE_FILE" > "$tmp_profile"
            cp "$PROFILE_FILE" "$PROFILE_FILE.backup.$(date +%Y%m%d%H%M%S)"
            mv "$tmp_profile" "$PROFILE_FILE"
        else
            cat "$block_file" >> "$PROFILE_FILE"
        fi

        rm -f "$block_file"
        echo "Added dotfiles sourcing to $PROFILE_FILE"
    fi

    export PATH="$HOME/.local/bin:$PATH"
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
}

setup_git() {
    echo "==> Setting up git configuration..."
    
    if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
        if [ -f "$HOME/.gitconfig" ] && ! [ -L "$HOME/.gitconfig" ]; then
            mv "$HOME/.gitconfig" "$HOME/.gitconfig.backup"
            echo "Backed up existing .gitconfig"
        fi
        ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
        echo "Linked .gitconfig"
    fi
}

# ============================================
# CLI Tools Installation (Linux only - Mac uses Homebrew)
# ============================================
install_cli_tools_linux() {
    echo "==> Installing/checking CLI tools..."
    mkdir -p "$HOME/.local/bin"
    
    # Node.js via NodeSource
    if ! command -v node &>/dev/null; then
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Bun
    if ! command -v bun &>/dev/null; then
        echo "Installing Bun..."
        curl -fsSL https://bun.sh/install | bash
        # Source bun immediately
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
    fi

    # Corepack/pnpm
    if command -v npm &>/dev/null; then
        npm config set prefix "$HOME/.local" >/dev/null 2>&1 || true
        export npm_config_prefix="$HOME/.local"
        corepack enable --install-directory "$HOME/.local/bin" || true
        corepack prepare pnpm@latest --activate || true
    fi

    # uv
    if ! command -v uv &>/dev/null; then
        echo "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh || echo "uv install failed (non-critical)"
    fi

    # Rust
    if ! command -v rustup &>/dev/null; then
        echo "Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path || echo "rustup install failed (non-critical)"
    fi
    
    # GitHub CLI
    if ! command -v gh &>/dev/null; then
        echo "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update && sudo apt-get install -y gh
    fi
    
    # Supabase CLI - npm global install is blocked by Supabase
    # Supabase's current docs recommend project-local install and `npx supabase`.
    echo "Note: Use 'npx supabase' or a project-local supabase dev dependency"

    # Vercel CLI
    if ! command -v vercel &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Vercel CLI..."
        npm install -g vercel || echo "Vercel CLI install failed (non-critical)"
    fi
    
    # Neon CLI
    if ! command -v neonctl &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Neon CLI..."
        npm install -g neonctl || echo "Neon CLI install failed (non-critical)"
    fi
    
    # Convex CLI
    if ! command -v convex &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Convex CLI..."
        npm install -g convex || echo "Convex install failed (non-critical)"
    fi
    
    # Dokploy CLI
    if ! command -v dokploy &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Dokploy CLI..."
        npm install -g @dokploy/cli || echo "Dokploy install failed (non-critical)"
    fi
    
    # Hetzner CLI (hcloud)
    if ! command -v hcloud &>/dev/null; then
        echo "Installing Hetzner CLI..."
        sudo apt-get install -y hcloud-cli || echo "hcloud install failed (non-critical)"
    fi
    
    # RunPod CLI (distributed as tarball)
    if ! command -v runpodctl &>/dev/null; then
        echo "Installing RunPod CLI..."
        curl -sSL -o /tmp/runpodctl.tar.gz https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-linux-amd64.tar.gz \
            && tar -xzf /tmp/runpodctl.tar.gz -C /tmp \
            && mv /tmp/runpodctl "$HOME/.local/bin/runpodctl" \
            && chmod +x "$HOME/.local/bin/runpodctl" \
            && rm /tmp/runpodctl.tar.gz \
            || echo "RunPod CLI install failed (non-critical)"
    fi
    
    # Infisical CLI (secrets management)
    if ! command -v infisical &>/dev/null; then
        echo "Installing Infisical CLI..."
        curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash - \
            && sudo apt-get update && sudo apt-get install -y infisical \
            || echo "Infisical install failed (non-critical)"
    fi

    # Coder CLI
    if ! command -v coder &>/dev/null; then
        echo "Installing Coder CLI..."
        curl -fsSL https://coder.com/install.sh | sh -s -- --prefix "$HOME/.local" || echo "Coder CLI install failed (non-critical)"
    fi
    
    # Cloudflare Wrangler CLI
    if ! command -v wrangler &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Cloudflare Wrangler CLI..."
        npm install -g wrangler || echo "Wrangler install failed (non-critical)"
    fi
    
    # Apify CLI (web scraping)
    if ! command -v apify &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Apify CLI..."
        npm install -g apify-cli || echo "Apify install failed (non-critical)"
    fi

    # Railway CLI
    if ! command -v railway &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Railway CLI..."
        npm install -g @railway/cli || echo "Railway CLI install failed (non-critical)"
    fi

    # SST CLI
    if ! command -v sst &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing SST CLI..."
        npm install -g sst || echo "SST CLI install failed (non-critical)"
    fi

    # AWS CLI v2
    if ! command -v aws &>/dev/null; then
        echo "Installing AWS CLI v2..."
        tmp_dir="$(mktemp -d)"
        aws_arch="x86_64"
        if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
            aws_arch="aarch64"
        fi
        if command -v unzip &>/dev/null; then
            curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o "$tmp_dir/awscliv2.zip" \
                && unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir" \
                && "$tmp_dir/aws/install" -i "$HOME/.local/aws-cli" -b "$HOME/.local/bin" --update \
                || echo "AWS CLI install failed (non-critical)"
        else
            echo "AWS CLI install skipped: unzip is missing"
        fi
        rm -rf "$tmp_dir"
    fi

    # Fly.io CLI
    if ! command -v fly &>/dev/null && ! command -v flyctl &>/dev/null; then
        echo "Installing Fly.io CLI..."
        curl -L https://fly.io/install.sh | sh || echo "Fly CLI install failed (non-critical)"
        if [ -x "$HOME/.fly/bin/flyctl" ]; then
            ln -sf "$HOME/.fly/bin/flyctl" "$HOME/.local/bin/flyctl"
            ln -sf "$HOME/.fly/bin/flyctl" "$HOME/.local/bin/fly"
        fi
    fi

    # kubectl
    if ! command -v kubectl &>/dev/null; then
        echo "Installing kubectl..."
        kubectl_arch="amd64"
        if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
            kubectl_arch="arm64"
        fi
        curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${kubectl_arch}/kubectl" \
            && install -m 0755 /tmp/kubectl "$HOME/.local/bin/kubectl" \
            && rm -f /tmp/kubectl \
            || echo "kubectl install failed (non-critical)"
    fi

    # OpenTofu
    if ! command -v tofu &>/dev/null; then
        echo "Installing OpenTofu..."
        curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh \
            && chmod +x /tmp/install-opentofu.sh \
            && /tmp/install-opentofu.sh --install-method standalone --install-path "$HOME/.local/bin" \
            && rm -f /tmp/install-opentofu.sh \
            || echo "OpenTofu install failed (non-critical)"
    fi

    # Cloudflare cloudflared
    if ! command -v cloudflared &>/dev/null; then
        echo "Installing cloudflared..."
        cf_arch="amd64"
        if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
            cf_arch="arm64"
        fi
        curl -fsSL -o "$HOME/.local/bin/cloudflared" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${cf_arch}" \
            && chmod +x "$HOME/.local/bin/cloudflared" \
            || echo "cloudflared install failed (non-critical)"
    fi
    
    echo "CLI tools installed!"
}

# ============================================
# code-server Installation
# ============================================
install_code_server() {
    echo "==> Installing code-server..."
    
    if command -v code-server &>/dev/null; then
        echo "code-server already installed"
        return
    fi
    
    # Install code-server as a user-local standalone binary, no root required.
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix="$HOME/.local" || {
        echo "code-server install failed (non-critical)"
        return
    }
    
    # Disable password auth (Coder handles auth)
    mkdir -p ~/.config/code-server
    cat > ~/.config/code-server/config.yaml << 'EOF'
bind-addr: 127.0.0.1:8080
auth: none
cert: false
EOF
    
    echo "code-server installed!"
}

# ============================================
# VS Code/code-server Extensions
# ============================================
install_extensions() {
    echo "==> Installing VS Code extensions..."
    
    # Detect code binary
    if command -v code-server &>/dev/null; then
        CODE_BIN="code-server"
    elif command -v codium &>/dev/null; then
        CODE_BIN="codium"
    elif command -v code &>/dev/null; then
        CODE_BIN="code"
    else
        echo "No VS Code/Codium binary found, skipping extensions"
        return
    fi
    
    if [ -f "$DOTFILES_DIR/extensions.txt" ]; then
        while IFS= read -r ext || [ -n "$ext" ]; do
            # Skip comments and empty lines
            [[ "$ext" =~ ^#.*$ ]] && continue
            [[ -z "${ext// }" ]] && continue
            
            echo "Installing extension: $ext"
            $CODE_BIN --install-extension "$ext" 2>/dev/null || true
        done < "$DOTFILES_DIR/extensions.txt"
    fi
    
    echo "Extensions installed!"
}

# ============================================
# OpenCode Plugins Setup
# ============================================
setup_opencode_plugins() {
    echo "==> Setting up OpenCode plugins..."
    
    OPENCODE_PLUGIN_DIR="$HOME/.config/opencode/plugin"
    mkdir -p "$OPENCODE_PLUGIN_DIR"
    
    # Symlink plugins from dotfiles
    if [ -d "$DOTFILES_DIR/opencode-plugins" ]; then
        for plugin_dir in "$DOTFILES_DIR/opencode-plugins"/*; do
            if [ -d "$plugin_dir" ]; then
                plugin_name=$(basename "$plugin_dir")
                target="$OPENCODE_PLUGIN_DIR/$plugin_name"
                
                if [ -L "$target" ]; then
                    rm "$target"
                fi
                
                if [ ! -e "$target" ]; then
                    ln -s "$plugin_dir" "$target"
                    echo "Linked OpenCode plugin: $plugin_name"
                fi
            fi
        done
    fi
}

# ============================================
# OpenCode Config Sync
# ============================================
setup_opencode_config() {
    echo "==> Setting up OpenCode config..."
    
    OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
    mkdir -p "$OPENCODE_CONFIG_DIR"
    
    # Copy non-secret configs
    if [ -f "$DOTFILES_DIR/opencode/oh-my-opencode.json" ]; then
        cp "$DOTFILES_DIR/opencode/oh-my-opencode.json" "$OPENCODE_CONFIG_DIR/"
        echo "Copied oh-my-opencode.json"
    fi
    
    if [ -f "$DOTFILES_DIR/opencode/opencode.json" ]; then
        cp "$DOTFILES_DIR/opencode/opencode.json" "$OPENCODE_CONFIG_DIR/"
        echo "Copied opencode.json"
    fi
    
    # Copy skills
    if [ -d "$DOTFILES_DIR/opencode/skills" ]; then
        mkdir -p "$OPENCODE_CONFIG_DIR/skills"
        cp -r "$DOTFILES_DIR/opencode/skills"/* "$OPENCODE_CONFIG_DIR/skills/"
        echo "Copied OpenCode skills"
    fi
}

# ============================================
# Main
# ============================================
main() {
    echo "========================================"
    echo "Dotfiles Installation"
    echo "========================================"
    
    setup_shell
    setup_git
    
    if $IS_LINUX && [ "${DOTFILES_SKIP_INSTALLS:-0}" != "1" ]; then
        install_cli_tools_linux
        install_code_server
    elif $IS_LINUX; then
        echo "==> Skipping Linux package installs (DOTFILES_SKIP_INSTALLS=1)"
    fi
    
    setup_opencode_plugins
    setup_opencode_config
    install_extensions

    if [ -x "$DOTFILES_DIR/scripts/devbox-check.sh" ]; then
        "$DOTFILES_DIR/scripts/devbox-check.sh" || true
    fi
    
    echo ""
    echo "========================================"
    echo "Installation complete!"
    echo "========================================"
}

main "$@"
