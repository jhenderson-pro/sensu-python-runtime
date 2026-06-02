#!/usr/bin/env python3
"""
Check for newer python-build-standalone releases and update build/upstream.json.

Writes GitHub Actions step outputs via $GITHUB_OUTPUT:
  bumped=true|false
  tag=<new-tag>
  py_version=<x.y.z>
  release_url=<url>
"""

import json
import os
import re
import sys
import urllib.request
from pathlib import Path

UPSTREAM_JSON = Path("build/upstream.json")
PYTHON_MINOR = "3.13"
TARGETS = [
    "x86_64-unknown-linux-gnu",
    "x86_64-unknown-linux-musl",
]
RELEASES_API = "https://api.github.com/repos/astral-sh/python-build-standalone/releases"


def api_get(url, token=None):
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())


def raw_get(url, token=None):
    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req) as resp:
        return resp.read().decode()


def set_outputs(**kwargs):
    gho = os.environ.get("GITHUB_OUTPUT")
    if gho:
        with open(gho, "a") as f:
            for k, v in kwargs.items():
                f.write(f"{k}={v}\n")
    else:
        for k, v in kwargs.items():
            print(f"  [output] {k}={v}")


def main():
    token = os.environ.get("GITHUB_TOKEN")
    current = json.loads(UPSTREAM_JSON.read_text())
    current_tag = current["tag"]

    print(f"Current tag: {current_tag}")
    print("Fetching releases from python-build-standalone...")

    releases = api_get(f"{RELEASES_API}?per_page=30", token)

    for release in releases:
        tag = release["tag_name"]

        if release.get("prerelease") or release.get("draft"):
            continue

        if tag <= current_tag:
            print(f"Release {tag} is not newer than {current_tag}. Nothing to do.")
            break

        print(f"Checking {tag}...")
        assets = {a["name"]: a for a in release["assets"]}

        artifact_names = {}
        found_all = True
        for target in TARGETS:
            pat = re.compile(
                rf"cpython-({re.escape(PYTHON_MINOR)}\.\d+)\+{re.escape(tag)}"
                rf"-{re.escape(target)}-install_only\.tar\.gz"
            )
            matched = next((n for n in assets if pat.match(n)), None)
            if matched is None:
                print(f"  Missing artifact for {target}, skipping release.")
                found_all = False
                break
            artifact_names[target] = matched

        if not found_all:
            continue

        first = next(iter(artifact_names.values()))
        py_version = re.match(r"cpython-(\d+\.\d+\.\d+)", first).group(1)
        print(f"  Python {py_version} — both targets present.")

        sha256_asset = assets.get("SHA256SUMS")
        if sha256_asset is None:
            print("  No SHA256SUMS file found, skipping release.")
            continue

        sha256_text = raw_get(sha256_asset["browser_download_url"], token)
        sha256_map = {}
        for line in sha256_text.splitlines():
            parts = line.strip().split()
            if len(parts) == 2:
                sha256_map[parts[1].lstrip("*")] = parts[0]

        new_artifacts = {}
        ok = True
        for target, name in artifact_names.items():
            sha = sha256_map.get(name)
            if sha is None:
                print(f"  No SHA256 for {name}, skipping release.")
                ok = False
                break
            new_artifacts[target] = {"filename": name, "sha256": sha}

        if not ok:
            continue

        updated = {
            "tag": tag,
            "python_version": py_version,
            "artifacts": new_artifacts,
        }
        UPSTREAM_JSON.write_text(json.dumps(updated, indent=2) + "\n")
        print(f"Updated build/upstream.json -> tag={tag}, python_version={py_version}")

        set_outputs(
            bumped="true",
            tag=tag,
            py_version=py_version,
            release_url=release["html_url"],
        )
        return 0

    set_outputs(bumped="false")
    return 0


if __name__ == "__main__":
    sys.exit(main())
