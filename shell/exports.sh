#!/bin/bash
# Environment exports for Coder workspaces

export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.fly/bin:$PATH"
export PATH="$HOME/.railway/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"

export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups

export CLICOLOR=1
export TERM=xterm-256color

if [ -d /opt/homebrew/bin ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

if [ -d /opt/homebrew/share/android-commandlinetools ]; then
    export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
    export PATH="$ANDROID_HOME/platform-tools:$PATH"
fi

if [ -x "$HOME/.local/bin/mise" ]; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$("$HOME/.local/bin/mise" activate bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$("$HOME/.local/bin/mise" activate zsh)"
    fi
elif command -v mise >/dev/null 2>&1; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(mise activate bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(mise activate zsh)"
    fi
fi
