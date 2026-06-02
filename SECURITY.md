# Security Policy

## Supported Versions

We only provide security updates for the current stable release of the `sensu-python-runtime` asset.

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| < 0.2.0 | :x:                |

## Reporting a Vulnerability

We take the security of this project seriously. If you believe you have found a security vulnerability, please report it to us responsibly.

**Do not open a public GitHub Issue for a security vulnerability.**

Instead, please report vulnerabilities via one of the following methods:

1. **GitHub Security Advisory:** Use the "Report a vulnerability" button on the [Security tab](https://github.com/sensu/sensu-python-runtime/security/advisories) of this repository. This is the preferred method as it allows for private discussion and coordinated disclosure.
2. **Email:** If you cannot use the GitHub Security Advisory feature, please email [100726636+jhenderson-pro@users.noreply.github.com](mailto:100726636+jhenderson-pro@users.noreply.github.com).

### What to include

Please include as much information as possible to help us reproduce and understand the issue:
- A description of the vulnerability.
- Steps to reproduce the issue.
- Potential impact.
- Any suggested mitigations.

### Response Window

You can expect an initial acknowledgment of your report within **48 hours**. We aim to provide a full assessment and a plan for resolution within **7 business days**.

## Scope

### In Scope
- The build pipeline and scripts in this repository.
- The repackaging logic and directory structure of the assets.
- The generation of checksums, SBOMs, and provenance attestations.

### Out of Scope
- **CPython itself:** This project repackages upstream CPython binaries from `python-build-standalone`. Vulnerabilities in the CPython interpreter, standard library, or the base binaries provided by Astral's `python-build-standalone` should be reported to the respective upstream projects.
- **Third-party Python modules:** If you are using a plugin asset that vendors its own dependencies, those dependencies are the responsibility of the plugin author.
