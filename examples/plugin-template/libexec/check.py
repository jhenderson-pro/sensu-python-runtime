#!/usr/bin/env python

"""Template Sensu Python plugin entrypoint."""

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
    parser = SensuArgumentParser(description="Template Sensu Python check.")
    parser.add_argument("--message", default="hello", help="Message to print.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    print(f"OK message={args.message}")
    return OK


if __name__ == "__main__":
    sys.exit(main())
