#!/usr/bin/env bash
set -euo pipefail

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd lsusb

echo "Unplug the controller, then press Enter." >&2
read -r
before=$(lsusb | awk '{print $6}')

echo "Now plug the controller in, then press Enter." >&2
read -r
after=$(lsusb | awk '{print $6}')

id=$(comm -13 <(printf "%s\n" "$before" | sort) <(printf "%s\n" "$after" | sort) | head -n 1)

if [ -z "$id" ]; then
  echo "No new USB device detected." >&2
  exit 1
fi

vendor=${id%%:*}
product=${id##*:}

printf "%s\n" "$vendor"
printf "%s\n" "$product"
