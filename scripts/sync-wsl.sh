#!/usr/bin/env bash
set -euo pipefail

target="${1:-youssef@100.86.28.11}"
remote_dir="${2:-/home/youssef/.dotfiles}"
ssh_cmd="${SSH_CMD:-ssh}"

rsync -az --delete \
  -e "$ssh_cmd" \
  --exclude '.git/' \
  --exclude '.ssh/' \
  --exclude '.gnupg/' \
  --exclude '.infisical/' \
  --exclude 'infisical-keyring/' \
  --exclude '.env' \
  --exclude '.env.*' \
  ./ "$target:$remote_dir/"

$ssh_cmd "$target" "chmod +x '$remote_dir/install.sh' '$remote_dir/scripts/'*.sh && DOTFILES_SKIP_INSTALLS=1 '$remote_dir/install.sh'"
