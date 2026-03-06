#!/usr/bin/env bash

set -u

usage() {
  echo "Usage: $0 <repo_url> <target_dir> [max_retries] [retry_delay_seconds]"
}

is_safe_target() {
  local target_dir="$1"
  [[ -n "$target_dir" ]] || return 1

  case "$target_dir" in
    "/"|"/bin"|"/boot"|"/dev"|"/etc"|"/home"|"/lib"|"/lib64"|"/opt"|"/proc"|"/root"|"/run"|"/sbin"|"/srv"|"/sys"|"/tmp"|"/usr"|"/var"|"."|"..")
      return 1
      ;;
  esac

  return 0
}

verify_clone() {
  local target_dir="$1"

  [[ -d "$target_dir" ]] || return 1
  git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  git -C "$target_dir" rev-parse HEAD >/dev/null 2>&1 || return 1
  git -C "$target_dir" status --porcelain >/dev/null 2>&1 || return 1
}

if [[ $# -lt 2 || $# -gt 4 ]]; then
  usage
  exit 1
fi

repo_url="$1"
target_dir="$2"
max_retries="${3:-3}"
retry_delay_seconds="${4:-2}"

if ! [[ "$max_retries" =~ ^[0-9]+$ && "$max_retries" -gt 0 ]]; then
  echo "max_retries must be a positive integer"
  exit 1
fi

if ! [[ "$retry_delay_seconds" =~ ^[0-9]+$ ]]; then
  echo "retry_delay_seconds must be a non-negative integer"
  exit 1
fi

for ((attempt = 1; attempt <= max_retries; attempt++)); do
  echo "Clone attempt ${attempt}/${max_retries}"

  if [[ -d "$target_dir" ]]; then
    if verify_clone "$target_dir"; then
      echo "Repository already present and valid at: $target_dir"
      exit 0
    fi

    if is_safe_target "$target_dir"; then
      rm -rf "$target_dir"
    else
      echo "Refusing to remove unsafe target directory: $target_dir"
      exit 1
    fi
  fi

  if git clone -- "$repo_url" "$target_dir"; then
    if verify_clone "$target_dir"; then
      echo "Clone verified successfully at: $target_dir"
      exit 0
    fi

    echo "Clone command succeeded but verification failed"
  else
    echo "Clone command failed"
  fi

  if [[ "$attempt" -lt "$max_retries" ]]; then
    echo "Retrying in ${retry_delay_seconds}s..."
    sleep "$retry_delay_seconds"
  fi
done

echo "Failed to clone and verify repository after ${max_retries} attempts"
exit 1
