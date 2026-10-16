#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

STATE_DIR="/var/lib/boot-history"
LOG_FILE="$STATE_DIR/boots.tsv"
LOCK_FILE="$STATE_DIR/boots.lock"

# systemd's StateDirectory= creates this directory and makes it writable
# even when ProtectSystem=strict is enabled.
install -d -o root -g root -m 0750 "$STATE_DIR"

if [[ ! -r /proc/sys/kernel/random/boot_id ]]; then
    echo "boot-history: kernel boot ID is unavailable" >&2
    exit 1
fi
boot_id="$(< /proc/sys/kernel/random/boot_id)"
boot_epoch="$(awk '$1 == "btime" { print $2; found = 1; exit } END { if (!found) exit 1 }' /proc/stat)"

# Serialize writes and prevent duplicate records if the service is manually restarted.
exec 9>"$LOCK_FILE"
flock -x 9

if [[ -f "$LOG_FILE" ]] && awk -F '\t' -v id="$boot_id" 'NR > 1 && $1 == id { found = 1 } END { exit !found }' "$LOG_FILE"; then
    exit 0
fi

if [[ ! -s "$LOG_FILE" ]]; then
    printf 'boot_id\tboot_epoch\tboot_time_local\tboot_time_utc\trecorded_at_local\trecorded_at_utc\tseconds_after_boot\thostname\tkernel_release\n' > "$LOG_FILE"
fi

boot_time_local="$(date --date="@$boot_epoch" '+%Y-%m-%d %H:%M:%S %z')"
boot_time_utc="$(date -u --date="@$boot_epoch" '+%Y-%m-%dT%H:%M:%SZ')"
recorded_at_local="$(date '+%Y-%m-%d %H:%M:%S %z')"
recorded_at_utc="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
seconds_after_boot="$(awk '{ printf "%.3f", $1; exit }' /proc/uptime)"
hostname_value="$(hostname)"
kernel_release="$(uname -r)"

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$boot_id" "$boot_epoch" "$boot_time_local" "$boot_time_utc" \
    "$recorded_at_local" "$recorded_at_utc" "$seconds_after_boot" \
    "$hostname_value" "$kernel_release" >> "$LOG_FILE"
