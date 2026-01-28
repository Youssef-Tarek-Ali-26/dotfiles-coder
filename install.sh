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
    
    PROFILE_FILE="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        PROFILE_FILE="$HOME/.zshrc"
    fi
    
    DOTFILES_MARKER="# dotfiles-coder"
    if ! grep -q "$DOTFILES_MARKER" "$PROFILE_FILE" 2>/dev/null; then
        cat >> "$PROFILE_FILE" << EOF

$DOTFILES_MARKER
[ -f ~/.dotfiles/shell/exports.sh ] && source ~/.dotfiles/shell/exports.sh
[ -f ~/.dotfiles/shell/aliases.sh ] && source ~/.dotfiles/shell/aliases.sh
EOF
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
    if command -v node &>/dev/null && command -v gh &>/dev/null && command -v bun &>/dev/null; then
        echo "==> CLI tools already installed (using custom image)"
        return
    fi
    
    echo "==> Installing CLI tools..."
    
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
    
    # GitHub CLI
    if ! command -v gh &>/dev/null; then
        echo "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update && sudo apt-get install -y gh
    fi
    
    # Supabase CLI - npm global install is blocked by Supabase
    # Use `npx supabase` instead - no installation needed
    echo "Note: Use 'npx supabase' for Supabase CLI (global install blocked)"
    
    # Neon CLI
    if ! command -v neonctl &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Neon CLI..."
        sudo npm install -g neonctl || echo "Neon CLI install failed (non-critical)"
    fi
    
    # Convex CLI
    if ! command -v convex &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Convex CLI..."
        sudo npm install -g convex || echo "Convex install failed (non-critical)"
    fi
    
    # Dokploy CLI
    if ! command -v dokploy &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Dokploy CLI..."
        sudo npm install -g @dokploy/cli || echo "Dokploy install failed (non-critical)"
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
            && sudo mv /tmp/runpodctl /usr/local/bin/runpodctl \
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
    
    # Cloudflare Wrangler CLI
    if ! command -v wrangler &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Cloudflare Wrangler CLI..."
        sudo npm install -g wrangler || echo "Wrangler install failed (non-critical)"
    fi
    
    # Apify CLI (web scraping)
    if ! command -v apify &>/dev/null && command -v npm &>/dev/null; then
        echo "Installing Apify CLI..."
        sudo npm install -g apify-cli || echo "Apify install failed (non-critical)"
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
    
    # Install code-server via official script
    curl -fsSL https://code-server.dev/install.sh | sh
    
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
    
    if $IS_LINUX; then
        install_cli_tools_linux
        install_code_server
    fi
    
    setup_opencode_plugins
    setup_opencode_config
    install_extensions
    
    echo ""
    echo "========================================"
    echo "Installation complete!"
    echo "========================================"
}

main "$@"
