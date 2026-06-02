# Sensu Python Runtime

This project produces [Sensu Go dynamic runtime assets](https://docs.sensu.io/sensu-go/latest/plugins/assets/) containing portable CPython interpreters. A Sensu agent loads the runtime asset, then loads a separate plugin asset that contains a Python check, handler, mutator, or filter. The runtime asset places `python`, `python3`, and `pip` on the agent's `$PATH` for the duration of the execution, ensuring that the plugin's `#!/usr/bin/env python` shebang resolves correctly to a consistent, known version of Python.

## What this is

- **A distribution and packaging project.** We repackage upstream CPython binaries into a format Sensu Go agents can consume.
- **Portable and hermetic.** We use `python-build-standalone` (maintained by Astral) to provide binaries that are designed to run without being installed into system locations.
- **Maintained and secure.** Every release includes SHA-512 checksums, Software Bill of Materials (SBOM), and build provenance attestations.

## What this is not

- **Not a replacement for system Python.** This is intended strictly for executing Sensu plugins.
- **Not a CPython build system.** We do not compile Python from source; we repackage trusted upstream binaries.
- **Not for heavy ML/scientific stacks.** We don't guarantee that every native Python wheel (especially those linking against complex system libraries) will work.
- **Not for EOL versions.** We only support modern, maintained versions of Python (3.13+).

## Supported Versions and Platforms

- **Python Version:** 3.13 (Primary stable default)
- **Architectures:** amd64 (arm64 deferred to Phase 5)
- **Platforms:** linux-glibc, linux-musl

## Quick Start

1. **Register the runtime asset:**
   ```bash
   curl -LO https://github.com/jhenderson-pro/sensu-python-runtime/releases/download/v0.2.0-beta.2/asset.yml
   sensuctl create -f asset.yml
   ```

2. **Use it in a check:**
   Reference the runtime asset and your plugin asset in your check configuration:
   ```json
   {
     "type": "CheckConfig",
     "spec": {
       "command": "my-check.py",
       "runtime_assets": ["sensu-python-runtime", "my-python-plugin"]
     }
   }
   ```

*(See [examples/simple-check/](examples/simple-check/) for a complete working example.)*

## Use with a Python Plugin Asset

To use this runtime with your own Python scripts, you should package your plugin in a specific directory structure (`bin/`, `lib/`, `libexec/`) and use a wrapper script to set `PYTHONPATH`.

For a detailed guide on the recommended pattern, see [Packaging Python Checks](docs/packaging-python-checks.md).

## Build from Source

While we repackage upstream binaries, you can run the repackaging process locally to audit or customize the result. Our pipeline uses simple shell scripts to download, verify, and flatten the upstream layout.

See the [Quickstart Guide](docs/quickstart.md) for build instructions.

## Release Artifacts

Every release on GitHub includes:
- **Runtime Tarballs:** For both glibc and musl targets.
- **SHA-512 Checksums:** Verified manifest of all artifacts.
- **SBOM:** Software Bill of Materials in CycloneDX/SPDX format.
- **Build Provenance:** SLSA attestations.
- **Asset YAML:** A ready-to-use `core/v2` Asset resource definition.

## Security and Support

- **Security Policy:** See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.
- **Support Policy:** See [SUPPORT.md](SUPPORT.md) for the supported platform matrix and maintenance cadence.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for local development setup and our contribution guidelines.
