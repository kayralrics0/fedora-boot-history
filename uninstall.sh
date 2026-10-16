#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Please run this uninstaller as root (sudo is not installed)." >&2
        exit 1
    fi
    exec sudo bash "$SCRIPT_DIR/uninstall.sh" "$@"
fi

systemctl disable --now boot-history.service 2>/dev/null || true
rm -f /etc/systemd/system/boot-history.service
rm -f /usr/local/bin/boot-history
rm -f /usr/local/libexec/boot-history/record-boot.sh
rmdir /usr/local/libexec/boot-history 2>/dev/null || true
systemctl daemon-reload
systemctl reset-failed boot-history.service 2>/dev/null || true

echo "The boot-history service has been removed."
echo "Existing records were preserved in /var/lib/boot-history/boots.tsv."
echo "To delete the records too, run: sudo rm -rf /var/lib/boot-history"
