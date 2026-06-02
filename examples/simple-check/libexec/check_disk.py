#!/usr/bin/env python

"""Stdlib-only Sensu disk usage check."""

from __future__ import annotations

import argparse
import shutil
import sys


OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3


class SensuArgumentParser(argparse.ArgumentParser):
    def error(self, message: str) -> None:
        self.print_usage(sys.stderr)
        self.exit(UNKNOWN, f"{self.prog}: error: {message}\n")


def parse_args() -> argparse.Namespace:
    parser = SensuArgumentParser(description="Check disk usage for a path.")
    parser.add_argument("--path", default="/", help="Path to inspect.")
    parser.add_argument(
        "--warning",
        type=float,
        default=80.0,
        help="Warning threshold as a percentage.",
    )
    parser.add_argument(
        "--critical",
        type=float,
        default=90.0,
        help="Critical threshold as a percentage.",
    )
    args = parser.parse_args()

    if args.warning < 0 or args.critical < 0:
        parser.error("thresholds must be non-negative")
    if args.warning > 100 or args.critical > 100:
        parser.error("thresholds must be less than or equal to 100")
    if args.warning >= args.critical:
        parser.error("--warning must be lower than --critical")

    return args


def main() -> int:
    args = parse_args()

    try:
        usage = shutil.disk_usage(args.path)
    except OSError as exc:
        print(f"UNKNOWN disk_usage path={args.path!r}: {exc}")
        return UNKNOWN

    used_percent = (usage.used / usage.total) * 100
    message = (
        f"disk_usage path={args.path} used={used_percent:.1f}% "
        f"free_bytes={usage.free} total_bytes={usage.total}"
    )

    if used_percent >= args.critical:
        print(f"CRITICAL {message}")
        return CRITICAL
    if used_percent >= args.warning:
        print(f"WARNING {message}")
        return WARNING

    print(f"OK {message}")
    return OK


if __name__ == "__main__":
    sys.exit(main())
