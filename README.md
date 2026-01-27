# Dotfiles for Coder Workspaces

Syncs development environment between local Mac and remote Coder workspaces.

## Quick Start

```bash
git clone https://github.com/Youssef-Tarek-Ali-26/dotfiles-coder.git ~/.dotfiles
~/.dotfiles/install.sh
```

## What's Included

- **CLI Tools** (Linux): node, bun, gh, supabase, neonctl
- **VS Code Extensions**: AI assistants, remote dev, Docker, diagrams
- **OpenCode Plugins**: agent-memory, handoff
- **OpenCode Config**: oh-my-opencode.json (agent model settings)

## Structure

```
.
├── install.sh              # Main bootstrap script
├── extensions.txt          # VS Code/VSCodium extensions list
├── opencode/               # OpenCode configuration
│   └── oh-my-opencode.json
└── opencode-plugins/       # Custom OpenCode plugins
    ├── agent-memory/
    └── handoff/
```

## OAuth Tokens

Tokens are NOT synced. They persist in the Coder workspace's home volume.
Run OAuth once per workspace - it survives restarts.
