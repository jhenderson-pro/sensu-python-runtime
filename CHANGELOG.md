# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial v0.2.0 modernization plan.
- New `README.md` landing page.
- `SUPPORT.md` defining platform support tiers.
- `SECURITY.md` for vulnerability reporting.
- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1).
- GitHub Actions workflows for build, release, upstream bumps, security scans, and Dependabot updates.
- `examples/simple-check/` stdlib-only disk usage check asset example.
- `examples/dependency-check/` vendored `requests` HTTP check asset example.
- `examples/plugin-template/` scaffold for packaging Python plugin assets.
- `docs/quickstart.md` for registering the runtime and running the simple check.
- `docs/packaging-python-checks.md` canonical guide for vendored Python plugin assets.
- `docs/troubleshooting-tls.md` guide for CA bundle configuration.
- `docs/migration-from-0.1.md` for users moving from the Python 3.6.11 asset.
- This `CHANGELOG.md`.

### Changed
- Moved legacy build materials to `docs/legacy/`.
- Generated release asset URLs now use the active GitHub repository path.
- Converted the README check configuration example from JSON to YAML.

## [0.1.0] — historical

This version represents the state of the original [jspaleta/sensu-python-runtime](https://github.com/jspaleta/sensu-python-runtime) repository before the v0.2.0 modernization effort. It supported Python 3.6.11 and used a Docker-based build system.
