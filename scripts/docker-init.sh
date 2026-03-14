#!/usr/bin/env bash
# docker-init.sh — Docker コンテナ起動時の初期化スクリプト
# Usage: sudo bash ~/project/dotfiles/scripts/docker-init.sh
set -euo pipefail

info()  { printf "[docker-init] %s\n" "$*"; }
warn()  { printf "[docker-init][WARN] %s\n" "$*" >&2; }

# Root チェック
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: run with sudo" >&2
  exit 1
fi

##### 1. SSH ホストキー生成 & sshd 起動 #####
setup_sshd() {
  # ホストキー生成（存在しなければ）
  if [ ! -s /etc/ssh/ssh_host_ed25519_key ]; then
    info "generating SSH host keys"
    ssh-keygen -A
  fi

  # /run/sshd がないと sshd が起動できない
  mkdir -p /run/sshd

  # 既に起動中ならスキップ
  if pgrep -x sshd >/dev/null 2>&1; then
    info "sshd is already running"
  else
    info "starting sshd"
    /usr/sbin/sshd
    info "sshd started (pid: $(pgrep -x sshd || echo '?'))"
  fi
}

##### 2. ゾンビプロセスの掃除 #####
reap_zombies() {
  local count
  count=$(ps -eo stat | grep -c '^Z' || true)
  if [ "$count" -gt 0 ]; then
    info "found $count zombie processes, attempting to reap"
    # ゾンビの親プロセスに SIGCHLD を送る
    ps -eo pid,ppid,stat | awk '$3 ~ /^Z/ {print $2}' | sort -u | while read -r ppid; do
      kill -s SIGCHLD "$ppid" 2>/dev/null || true
    done
  fi
}

##### 3. sudo NOPASSWD 設定（Docker 内の利便性） #####
setup_sudoers() {
  local user="${SUDO_USER:-hrmtz}"
  local sudoers_file="/etc/sudoers.d/$user-nopasswd"
  if [ ! -f "$sudoers_file" ]; then
    info "configuring passwordless sudo for $user"
    echo "$user ALL=(ALL) NOPASSWD: ALL" > "$sudoers_file"
    chmod 440 "$sudoers_file"
  else
    info "passwordless sudo already configured"
  fi
}

##### 4. 必要なランタイムディレクトリの作成 #####
setup_runtime_dirs() {
  mkdir -p /run/sshd
  mkdir -p /var/log
}

##### Main #####
main() {
  info "initializing Docker environment"
  setup_runtime_dirs
  setup_sudoers
  setup_sshd
  reap_zombies
  info "done"
}

main "$@"
