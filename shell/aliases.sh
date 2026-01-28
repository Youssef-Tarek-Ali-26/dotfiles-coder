#!/bin/bash
# Portable shell aliases for Coder workspaces

# ===== Git shortcuts =====
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias glog="git log --oneline --graph --decorate -10"

# ===== Directory navigation =====
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# ===== Safe operations =====
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# ===== Modern CLI alternatives (if installed) =====
if command -v eza &>/dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -l --icons --group-directories-first --git"
    alias la="eza -la --icons --group-directories-first --git"
    alias lt="eza --tree --icons --level=2"
else
    alias ll="ls -lh"
    alias la="ls -lah"
fi

if command -v bat &>/dev/null; then
    alias cat="bat --paging=never"
    alias catp="bat"
fi

if command -v fd &>/dev/null; then
    alias find="fd"
fi

# ===== Dev shortcuts =====
alias nr="npm run"
alias ni="npm install"
alias br="bun run"
alias bi="bun install"

# ===== Supabase via npx =====
alias supabase="npx supabase"

# ===== Quick edits =====
alias zshrc='${EDITOR:-vim} ~/.zshrc'
alias bashrc='${EDITOR:-vim} ~/.bashrc'
