#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Please run this installer as root (sudo is not installed)." >&2
        exit 1
    fi
    exec sudo bash "$SCRIPT_DIR/install.sh" "$@"
fi

if ! command -v systemctl >/dev/null 2>&1 || [[ ! -d /run/systemd/system ]]; then
    echo "This tool requires a systemd-based Linux installation." >&2
    exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python 3 is required for the boot-history command." >&2
    exit 1
fi
if ! command -v flock >/dev/null 2>&1; then
    echo "The flock command is required (normally provided by util-linux)." >&2
    exit 1
fi

install -D -o root -g root -m 0755 \
    "$SCRIPT_DIR/libexec/record-boot.sh" \
    /usr/local/libexec/boot-history/record-boot.sh
install -D -o root -g root -m 0755 \
    "$SCRIPT_DIR/bin/boot-history" \
    /usr/local/bin/boot-history
install -D -o root -g root -m 0644 \
    "$SCRIPT_DIR/systemd/boot-history.service" \
    /etc/systemd/system/boot-history.service
install -d -o root -g root -m 0750 /var/lib/boot-history

systemctl daemon-reload
systemctl enable --now boot-history.service

echo
echo "Installation complete."
echo "View recent boots: boot-history"
echo "View all boots:    boot-history --all"
echo "Export as JSON:    boot-history --json"
echo "Log file:          /var/lib/boot-history/boots.tsv"
echo
echo "The current boot is recorded now; older boots are not reconstructed retroactively."
