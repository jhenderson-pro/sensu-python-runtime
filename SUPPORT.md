# Support Policy

This document outlines the supported platforms, versions, and maintenance cadence for the `sensu-python-runtime` assets.

## Support Matrix

We categorize support into tiers to clarify what you can expect for different environments.

### Tier 1: Fully Supported

These combinations are actively maintained, tested in CI, and recommended for production use.

| Asset | libc | Architecture | Upstream Triple |
|:---|:---|:---|:---|
| sensu-python-runtime-3.13 (linux-glibc) | glibc | amd64 | `x86_64-unknown-linux-gnu` |
| sensu-python-runtime-3.13 (linux-musl) | musl | amd64 | `x86_64-unknown-linux-musl` |

### Tier 2: Best Effort / Deferred

The following are planned for Phase 5 of our modernization but are not currently the primary focus. We may accept community contributions for these, but they are not yet part of our official release gates.

- **Architectures:** arm64 (aarch64)
- **Python Versions:** 3.12 (on request)
- **Platforms:** Windows (MSVC), macOS

## Unsupported

The following are explicitly **not supported** by this project:

- **End-of-life Python versions:** Python 3.11 and earlier.
- **Legacy or niche Operating Systems:** CentOS 6/7, Debian 8/9, Alpine 3.x, AIX, Solaris.
- **Complex C-extensions:** Python wheels that require linking against heavy system libraries (e.g., complex ML/scientific stacks) are out of scope. We recommend using a container-based approach for these use cases.

## Release Cadence

Our release cycle is tied to the upstream [python-build-standalone](https://github.com/astral-sh/python-build-standalone) project.

- **Patch Releases:** Whenever upstream ships a new CPython patch release (e.g., 3.13.1 -> 3.13.2) for a supported minor version, our automated pipeline will trigger a new build.
- **Security Fixes:** Critical security vulnerabilities in our packaging or the upstream binaries will be addressed as a priority release.
- **Minor/Major Updates:** New Python minor versions (e.g., 3.14) will be added to the support matrix following evaluation and testing.

## Reporting Issues

If you encounter a bug on a Tier 1 platform, please open a GitHub Issue. For Tier 2 or unsupported platforms, please start a GitHub Discussion or reach out on the Sensu Community Slack.

For security-related reports, please refer to [SECURITY.md](SECURITY.md).
