# Contributing to Sensu Python Runtime

Thank you for your interest in contributing to the `sensu-python-runtime` project! We welcome contributions that help us maintain a high-quality, portable CPython runtime for the Sensu community.

## Non-Goals

This project has a narrow focus on repackaging upstream CPython binaries into Sensu runtime assets. We intentionally avoid scope creep, including support for end-of-life Python versions, niche operating systems, or arbitrary Python tooling.

## Local Development Setup

### Prerequisites

To work on this project locally, you will need:
- **Bash** (v4+)
- **curl** and **tar** (for fetching and extracting upstream binaries)
- **Docker** (used for running `hadolint` and performing smoke tests on `musl`/Alpine environments)
- **shellcheck** (for linting shell scripts)

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/sensu/sensu-python-runtime.git
   cd sensu-python-runtime
   ```

2. Most build tasks are handled by shell scripts in the `build/` directory.

## Coding Standards

### Shell Scripts
- Use `bash` for all scripts.
- Start every script with `set -euo pipefail`.
- All scripts must pass `shellcheck`.

### Dockerfiles
- Use Dockerfiles only for build/test environments, not for compiling CPython.
- All Dockerfiles must pass `hadolint`.

### Conventional Commits
We use the [Conventional Commits](https://www.conventionalcommits.org/) specification for all commit messages. This helps us automate our changelog and release process.

Common types:
- `feat:` A new feature (e.g., adding a new Python version support)
- `fix:` A bug fix
- `docs:` Documentation-only changes
- `style:` Changes that do not affect the meaning of the code (white-space, formatting, etc.)
- `refactor:` A code change that neither fixes a bug nor adds a feature
- `ci:` Changes to our CI configuration files and scripts
- `chore:` Other changes that don't modify src or test files

Example:
```text
feat: add support for Python 3.14
fix: resolve pathing issue in repackage.sh
docs: update quickstart instructions
```

## Linting Locally

Before submitting a PR, please run linting tools locally:

- **Shell scripts:**
  ```bash
  shellcheck build/*.sh scripts/*
  ```
- **Dockerfiles:**
  ```bash
  docker run --rm -i hadolint/hadolint < Dockerfile.example
  ```

## Pull Request Process

1. **Create a Branch:** Use a descriptive branch name (e.g., `feat/add-3.14` or `fix/checksum-validation`).
2. **One Logical Change:** Keep PRs focused. If you have multiple unrelated changes, please split them into separate PRs.
3. **Update Changelog:** Add a summary of your changes to the `## [Unreleased]` section of [CHANGELOG.md](CHANGELOG.md).
4. **Submit for Review:** Once your changes are ready and linting passes, open a Pull Request against the `master` branch.
