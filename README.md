# network-monitor

A small **live network monitor** for Linux. It shows active connections per process and
per-interface throughput in a clean terminal UI, and can alert when traffic crosses a threshold.

- `monitor.py` — Python monitor using [`psutil`](https://pypi.org/project/psutil/) +
  [`rich`](https://pypi.org/project/rich/): lists `ESTABLISHED` connections with the owning
  process (PID / name) and local/remote addresses, refreshed live.
- `monitor.sh` — a bash driver that auto-detects the default interface, watches per-interface
  throughput, and logs/alerts when it exceeds a configurable KB/s threshold.

## Usage

```bash
pip install psutil rich
python3 monitor.py            # live connection table
./monitor.sh [interface]      # throughput watch (defaults to the route's default iface)
```
