#!/bin/bash
# Environment exports for Coder workspaces

export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"

export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups

export CLICOLOR=1
export TERM=xterm-256color
