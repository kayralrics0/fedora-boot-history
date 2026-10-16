# Fedora Boot History

A small, local-only systemd service that records when Linux boots. It is designed for Fedora and other systemd-based distributions.

## Features

- Records the kernel-reported boot date and time to one-second resolution.
- Stores timestamps in both the system's local time zone and UTC.
- Records when the service captured the entry, uptime at capture, hostname, kernel release, and boot ID.
- Prevents duplicate records for the same boot, even if the service is restarted manually.
- Provides a terminal viewer and JSON output.
- Uses no network connection, telemetry, or third-party Python packages.
- Keeps the history after the service is uninstalled.

## Install

Extract the archive, open a terminal in the extracted `fedora-boot-history` directory, and run:

```bash
chmod +x install.sh uninstall.sh
./install.sh
```

The installer requests administrator privileges through `sudo`, installs the systemd unit, enables it at boot, and immediately records the current boot.

## Usage

```bash
boot-history          # Show the latest 20 boots
boot-history --all    # Show all recorded boots
boot-history --limit 5
boot-history --json   # JSON output, suitable for scripting
```

The data is stored in:

```text
/var/lib/boot-history/boots.tsv
```

You can inspect the service status and logs with:

```bash
systemctl status boot-history.service
journalctl -u boot-history.service
```

## Uninstall

From this project directory, run:

```bash
./uninstall.sh
```

The service and commands are removed, but the history file is intentionally preserved. To remove the records as well:

```bash
sudo rm -rf /var/lib/boot-history
```

## Timestamp accuracy and limitations

The boot timestamp comes from the Linux kernel's `btime` field in `/proc/stat`, which reports seconds since the Unix Epoch. Therefore, the boot timestamp is recorded to whole-second resolution—not milliseconds or nanoseconds. The separate "recorded at" value shows when this service ran, and "uptime" shows how long the system had already been running at that point.

The recorded wall-clock time depends on the system clock being correct. If the hardware clock is wrong during startup and the clock is corrected later, the original log entry is not automatically rewritten. Existing boots from before installation cannot be recovered by this tool.

## Security and privacy

The service runs as root because it is a system-wide startup service, but it only reads kernel boot metadata and appends to its own state file. The systemd unit uses filesystem restrictions, and records are stored locally under `/var/lib/boot-history` with root-only write access. No information is sent over the network.
