# Packaging Python Checks

This guide shows how to package a Python Sensu plugin asset that runs with `sensu-python-runtime`.

The core rule is simple: vendor dependencies at package time, never at check runtime.

## Asset Structure

Use this layout:

```text
my-python-check/
├── bin/
│   └── my-python-check
├── libexec/
│   └── check.py
├── lib/
│   └── ...
├── requirements.txt
└── Makefile
```

- `bin/` contains executable wrappers. Sensu runs commands from here.
- `libexec/` contains your Python implementation.
- `lib/` contains vendored dependencies installed with `--target`.
- `requirements.txt` records package-time dependencies.

Start from [examples/plugin-template/](../examples/plugin-template/) when creating a new plugin asset.

## Wrapper Script

The wrapper should locate its own asset directory, prepend the asset's `lib/` directory to `PYTHONPATH`, and execute Python:

```bash
#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ASSET_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
PYTHON_BIN=${PYTHON_BIN:-python}

export PYTHONPATH="$ASSET_DIR/lib${PYTHONPATH:+:$PYTHONPATH}"

exec "$PYTHON_BIN" "$ASSET_DIR/libexec/check.py" "$@"
```

When the Sensu check lists `sensu-python-runtime` before the plugin asset, the runtime asset's `bin/` directory is on `PATH`, so `python` resolves to the packaged CPython interpreter.

For local testing on systems without a `python` command, run the wrapper with `PYTHON_BIN=python3`.

## Vendoring Dependencies

Prefer `uv`:

```bash
uv pip install --target lib -r requirements.txt
```

Plain `pip` is a fine fallback:

```bash
python3 -m pip install --target lib -r requirements.txt
```

Package the asset after dependencies are installed:

```bash
tar -czf my-python-check_0.1.0_linux_amd64.tar.gz bin lib libexec requirements.txt README.md
shasum -a 512 my-python-check_0.1.0_linux_amd64.tar.gz
```

Do not run `pip install` from a Sensu check command. Agents should not need network access to execute a check.

## Sensu Check Configuration

List the runtime asset first, then the plugin asset:

```yaml
---
type: CheckConfig
api_version: core/v2
metadata:
  name: my-python-check
spec:
  command: my-python-check --flag value
  interval: 60
  publish: true
  runtime_assets:
    - sensu-python-runtime
    - my-python-check
  subscriptions:
    - linux
```

The order matters because Sensu applies runtime asset paths before executing the command.

## Exit Codes

Use standard Sensu plugin exit codes:

- `0`: OK
- `1`: WARNING
- `2`: CRITICAL
- `3`: UNKNOWN

Argument validation failures, import failures, and unexpected runtime errors should normally exit `3`.

## Native Wheels

Pure-Python dependencies are the safest fit for this runtime pattern. Native wheels can work, but they must be compatible with the target platform and libc.

For the v0.2.0 beta scope:

- glibc amd64 plugin assets should run on supported non-Alpine Linux agents.
- musl amd64 plugin assets should run on Alpine agents.

If a dependency links against system libraries not present on the agent, the import can still fail even when Python itself works correctly.

## Common Pitfalls

`python: command not found`

The check probably did not include `sensu-python-runtime` in `runtime_assets`, or the plugin asset was configured without the runtime asset.

`ModuleNotFoundError`

The dependency was not vendored into `lib/`, or the wrapper did not set `PYTHONPATH`.

Works locally but not in Sensu

Local tests may accidentally use your workstation's Python and site-packages. Test with a clean packaged asset and make sure imports come from the asset's own `lib/`.

Native dependency import failure

The wheel may not match the target libc or may require system libraries outside the runtime asset. Rebuild or vendor a compatible wheel, switch to a pure-Python dependency, or use a separate plugin asset tailored to that platform.

TLS certificate errors

The runtime does not replace the agent host's trust store. See [troubleshooting-tls.md](troubleshooting-tls.md).
