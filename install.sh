#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
UID_NUM=$(id -u)

usage() {
  cat <<'EOF'
Usage: ./install.sh [--vendor VVVV] [--product PPPP] [--auto]

Examples:
  ./install.sh --vendor 2dc8 --product 310b
  ./install.sh --auto
EOF
}

DEFAULT_VENDOR="2dc8"
DEFAULT_PRODUCT="310b"

VENDOR_ID=""
PRODUCT_ID=""
AUTO_DETECT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --vendor)
      VENDOR_ID=${2:-""}
      shift 2
      ;;
    --product)
      PRODUCT_ID=${2:-""}
      shift 2
      ;;
    --auto)
      AUTO_DETECT=1
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [ "$AUTO_DETECT" -eq 1 ]; then
  if [ ! -x "$ROOT_DIR/scripts/detect-controller.sh" ]; then
    echo "Missing autodetect script: $ROOT_DIR/scripts/detect-controller.sh"
    exit 1
  fi
  mapfile -t ids < <("$ROOT_DIR/scripts/detect-controller.sh")
  if [ "${#ids[@]}" -lt 2 ]; then
    echo "Autodetect failed. Try running without --auto."
    exit 1
  fi
  VENDOR_ID=${ids[0]}
  PRODUCT_ID=${ids[1]}
fi

if [ -z "$VENDOR_ID" ]; then
  read -r -p "Controller vendor ID (hex, default ${DEFAULT_VENDOR}): " VENDOR_ID
fi

if [ -z "$PRODUCT_ID" ]; then
  read -r -p "Controller product ID (hex, default ${DEFAULT_PRODUCT}): " PRODUCT_ID
fi

if [ -z "$VENDOR_ID" ]; then
  VENDOR_ID="$DEFAULT_VENDOR"
fi

if [ -z "$PRODUCT_ID" ]; then
  PRODUCT_ID="$DEFAULT_PRODUCT"
fi

if ! [[ "$VENDOR_ID" =~ ^[0-9a-fA-F]{4}$ ]]; then
  echo "Vendor ID must be 4 hex characters"
  exit 1
fi

if ! [[ "$PRODUCT_ID" =~ ^[0-9a-fA-F]{4}$ ]]; then
  echo "Product ID must be 4 hex characters"
  exit 1
fi

echo "Installing scripts to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
install -m 755 "$ROOT_DIR/bin/steam-tv-switch" "$HOME/.local/bin/steam-tv-switch"

echo "Installing systemd user units"
mkdir -p "$HOME/.config/systemd/user"
install -m 644 "$ROOT_DIR/systemd/steam-tv-switch.service" "$HOME/.config/systemd/user/steam-tv-switch.service"
install -m 644 "$ROOT_DIR/systemd/steam-tv-switch.path" "$HOME/.config/systemd/user/steam-tv-switch.path"

echo "Installing udev rule (requires sudo)"
sudo tee /etc/udev/rules.d/99-steam-tv-switch.rules >/dev/null <<EOF
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${VENDOR_ID,,}", ATTR{idProduct}=="${PRODUCT_ID,,}", RUN+="/usr/bin/touch /run/user/${UID_NUM}/steam-tv-switch.trigger"
EOF

echo "Reloading udev rules"
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "Reloading systemd user units"
systemctl --user daemon-reload
systemctl --user reset-failed steam-tv-switch.path steam-tv-switch.service || true
systemctl --user enable --now steam-tv-switch.path
systemctl --user restart steam-tv-switch.path

echo "Install complete"
echo "Tip: connect the controller to trigger Steam Gamepad UI."
