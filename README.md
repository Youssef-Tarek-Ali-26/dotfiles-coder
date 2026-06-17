# Dotfiles for Coder Workspaces and Devboxes

Syncs the portable parts of a development environment between local Mac, Coder workspaces, WSL devboxes, and Linux remote hosts.

This repo is public, so it deliberately stores bootstrap/config only. Secrets and auth state stay in each machine's secure local stores or in Infisical.

## Quick Start

```bash
git clone https://github.com/Youssef-Tarek-Ali-26/dotfiles-coder.git ~/.dotfiles
~/.dotfiles/install.sh
```

For the Windows WSL devbox over Tailscale:

```bash
SSH_CMD='ssh -i ~/.ssh/id_ed25519_win' ./scripts/sync-wsl.sh youssef@100.86.28.11
ssh -i ~/.ssh/id_ed25519_win youssef@100.86.28.11 '~/.dotfiles/scripts/devbox-check.sh'
```

## What's Included

- **CLI Tools** (Linux): node, bun, pnpm, uv, Rust, gh, infisical, vercel, hcloud, coder, AWS, Neon, Convex, Dokploy, Wrangler, Apify, RunPod, Railway, Fly.io, kubectl, OpenTofu, cloudflared, Supabase via npx
- **VS Code Extensions**: AI assistants, remote dev, Docker, diagrams
- **OpenCode Plugins**: agent-memory, handoff
- **OpenCode Config**: oh-my-opencode.json (agent model settings)
- **Devbox Checks**: verify installed commands, versions, and login state

## Structure

```
.
├── install.sh              # Main bootstrap script
├── docs/                   # Persistence and secret-sync notes
├── extensions.txt          # VS Code/VSCodium extensions list
├── opencode/               # OpenCode configuration
│   └── oh-my-opencode.json
└── opencode-plugins/       # Custom OpenCode plugins
    ├── agent-memory/
    └── handoff/
```

## OAuth Tokens

Tokens are NOT synced. They persist in the target workspace/devbox home volume or provider keychain.

Run login once per workspace/devbox; it survives restarts if the home volume persists:

```bash
gh auth login
gh auth setup-git
infisical login
vercel login
codex login
claude
```

See [docs/devbox-persistence.md](docs/devbox-persistence.md) for the full sync policy.
