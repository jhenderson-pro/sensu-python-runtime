#!/usr/bin/env python

"""HTTP check example that imports a vendored dependency."""

from __future__ import annotations

import argparse
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
    parser = SensuArgumentParser(description="Check an HTTP endpoint.")
    parser.add_argument("--url", required=True, help="URL to request.")
    parser.add_argument(
        "--timeout",
        type=float,
        default=5.0,
        help="Request timeout in seconds.",
    )
    parser.add_argument(
        "--warning-status",
        type=int,
        default=400,
        help="Status code threshold for warning.",
    )
    parser.add_argument(
        "--critical-status",
        type=int,
        default=500,
        help="Status code threshold for critical.",
    )
    args = parser.parse_args()

    if args.timeout <= 0:
        parser.error("--timeout must be greater than zero")
    if args.warning_status < 100 or args.critical_status < 100:
        parser.error("status thresholds must be valid HTTP status codes")
    if args.warning_status >= args.critical_status:
        parser.error("--warning-status must be lower than --critical-status")

    return args


def main() -> int:
    args = parse_args()

    try:
        import requests
    except ImportError as exc:
        print(f"UNKNOWN requests is not available: {exc}")
        return UNKNOWN

    try:
        response = requests.get(args.url, timeout=args.timeout)
    except requests.RequestException as exc:
        print(f"UNKNOWN url={args.url} request failed: {exc}")
        return UNKNOWN

    message = (
        f"url={args.url} status={response.status_code} "
        f"elapsed_ms={response.elapsed.total_seconds() * 1000:.0f}"
    )

    if response.status_code >= args.critical_status:
        print(f"CRITICAL {message}")
        return CRITICAL
    if response.status_code >= args.warning_status:
        print(f"WARNING {message}")
        return WARNING

    print(f"OK {message}")
    return OK


if __name__ == "__main__":
    sys.exit(main())
