# Devbox Persistence

This repo is a public bootstrap layer for Coder workspaces, WSL devboxes, and Linux remote hosts.

It should make a fresh devbox feel familiar, but it must not become a credential backup.

## Sync Through Git

- shell exports and aliases
- Git identity and defaults
- VS Code/Codium/code-server extension list
- OpenCode config, plugins, and skills
- bootstrap scripts
- devbox health checks

## Recreate During Bootstrap

- Node, Bun, pnpm
- Python/uv
- Rust/Cargo
- GitHub CLI
- Infisical CLI
- Vercel CLI
- Hetzner hcloud CLI
- Coder CLI
- provider/deploy CLIs such as AWS, Neon, Convex, Dokploy, Wrangler, Apify, RunPod, Railway, Fly.io, kubectl, OpenTofu, and cloudflared
- Docker, when the host supports system packages/systemd

## Reauthenticate Per Devbox

These tools keep tokens, sessions, keyrings, or encrypted local vaults. Install the CLI from this repo, then log in on the target machine.

```bash
gh auth login
gh auth setup-git

infisical login
infisical user get

vercel login
coder login <deployment-url>
railway login --browserless
aws configure sso

codex login
claude
```

For Hetzner, prefer a scoped token from Infisical rather than committing local `hcloud` config:

```bash
hcloud context create <name>
```

## Never Commit

- SSH private keys or `~/.ssh`
- `~/.gnupg`
- `~/.infisical`, `infisical-keyring`, or secret backups
- `~/.docker/config.json`
- `.npmrc`, `.netrc`, `.pypirc`
- cloud credential stores such as `~/.config/gcloud`
- Codex/Claude/opencode account/session databases
- shell histories and caches

Private GitHub repos are still not a secrets manager. Use Infisical for secrets, and use this repo to install Infisical plus document the login flow.
