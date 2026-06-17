#!/usr/bin/env bash
set -u

run_quiet_timeout() {
  seconds="$1"
  shift

  "$@" >/dev/null 2>&1 &
  pid=$!

  while kill -0 "$pid" >/dev/null 2>&1; do
    if [ "$seconds" -le 0 ]; then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi

    sleep 1
    seconds=$((seconds - 1))
  done

  wait "$pid"
}

commands=(
  git
  curl
  ssh
  gh
  node
  npm
  pnpm
  bun
  python3
  uv
  rustup
  cargo
  docker
  coder
  codex
  claude
  infisical
  vercel
  hcloud
  rg
  fd
  fzf
  direnv
  starship
)

printf 'devbox-check host=%s user=%s\n' "$(hostname 2>/dev/null || echo unknown)" "$(whoami 2>/dev/null || echo unknown)"
printf '\n[commands]\n'
for cmd in "${commands[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'ok      %-10s %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf 'missing %-10s\n' "$cmd"
  fi
done

printf '\n[versions]\n'
for cmd in node npm pnpm bun python3 uv rustup cargo docker coder codex claude infisical vercel hcloud; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '%-10s ' "$cmd"
    case "$cmd" in
      hcloud) hcloud version 2>/dev/null | head -n1 || true ;;
      docker) docker --version 2>/dev/null | head -n1 || true ;;
      *) "$cmd" --version 2>/dev/null | head -n1 || true ;;
    esac
  fi
done

printf '\n[auth]\n'
if command -v gh >/dev/null 2>&1; then
  if run_quiet_timeout 8 gh auth status; then
    echo 'ok      gh'
  else
    echo 'login   gh auth login && gh auth setup-git'
  fi
fi

if command -v infisical >/dev/null 2>&1; then
  if run_quiet_timeout 8 infisical user get; then
    echo 'ok      infisical'
  else
    echo 'login   infisical login'
  fi
fi

if command -v vercel >/dev/null 2>&1; then
  if run_quiet_timeout 8 vercel whoami; then
    echo 'ok      vercel'
  else
    echo 'login   vercel login'
  fi
fi

if command -v hcloud >/dev/null 2>&1; then
  if run_quiet_timeout 8 hcloud context active; then
    echo 'ok      hcloud'
  else
    echo 'login   hcloud context create <name>'
  fi
fi

if command -v docker >/dev/null 2>&1; then
  if run_quiet_timeout 8 docker info; then
    echo 'ok      docker'
  else
    echo 'fix     docker daemon/group access'
  fi
fi
