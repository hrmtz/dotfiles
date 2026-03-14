# docker-svc.zsh — Docker コンテナ内での systemctl 代替ラッパー
# systemctl が使えない Docker 環境で svc コマンドを提供

# Docker 環境の検出
_is_docker() {
  [ -f /.dockerenv ] || grep -q 'docker\|containerd' /proc/1/cgroup 2>/dev/null
}

# サービスバイナリの検索
_find_svc_bin() {
  local name="$1"
  local -a candidates=(
    "/usr/sbin/${name}"
    "/usr/sbin/${name}d"
    "/usr/bin/${name}"
    "/usr/bin/${name}d"
    "/usr/libexec/${name}"
  )
  for bin in "${candidates[@]}"; do
    if [ -x "$bin" ]; then
      echo "$bin"
      return 0
    fi
  done
  return 1
}

svc() {
  local action="${1:-}" name="${2:-}"

  if [ -z "$action" ]; then
    cat <<'USAGE'
Usage: svc <action> <service>
Actions: start, stop, restart, status, list
Examples:
  svc start ssh
  svc stop ssh
  svc status ssh
  svc list
USAGE
    return 0
  fi

  case "$action" in
    list)
      echo "=== Running services ==="
      ps -eo pid,comm --no-headers | awk '$2 !~ /^(ps|awk|zsh|bash|sleep|claude)$/' | sort -k2
      return 0
      ;;
  esac

  if [ -z "$name" ]; then
    echo "Error: service name required" >&2
    return 1
  fi

  # sshd の場合 "ssh" でも受け付ける
  local daemon_name="$name"
  [ "$name" = "ssh" ] && daemon_name="sshd"

  case "$action" in
    start)
      if pgrep -x "$daemon_name" >/dev/null 2>&1; then
        echo "$daemon_name is already running (pid: $(pgrep -x "$daemon_name" | head -1))"
        return 0
      fi
      local bin
      bin="$(_find_svc_bin "$daemon_name")" || { echo "Error: $daemon_name binary not found" >&2; return 1; }
      echo "Starting $daemon_name..."
      # sshd は /run/sshd が必要
      [ "$daemon_name" = "sshd" ] && sudo mkdir -p /run/sshd
      sudo "$bin"
      sleep 0.5
      if pgrep -x "$daemon_name" >/dev/null 2>&1; then
        echo "$daemon_name started (pid: $(pgrep -x "$daemon_name" | head -1))"
      else
        echo "Error: $daemon_name failed to start" >&2
        return 1
      fi
      ;;
    stop)
      if ! pgrep -x "$daemon_name" >/dev/null 2>&1; then
        echo "$daemon_name is not running"
        return 0
      fi
      echo "Stopping $daemon_name..."
      sudo pkill -x "$daemon_name"
      echo "$daemon_name stopped"
      ;;
    restart)
      svc stop "$name"
      sleep 0.5
      svc start "$name"
      ;;
    status)
      if pgrep -x "$daemon_name" >/dev/null 2>&1; then
        echo "$daemon_name is running (pid: $(pgrep -x "$daemon_name" | head -1))"
      else
        echo "$daemon_name is not running"
      fi
      ;;
    *)
      echo "Unknown action: $action (use start|stop|restart|status|list)" >&2
      return 1
      ;;
  esac
}
