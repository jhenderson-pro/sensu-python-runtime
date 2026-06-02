# Python Plugin Asset Template

Copy this directory when building a Sensu Python check, handler, mutator, or filter that should run with `sensu-python-runtime`.

## Layout

```text
bin/my-python-check       # executable wrapper Sensu runs
libexec/check.py          # your Python entrypoint
lib/                      # vendored dependencies, created by make vendor
requirements.txt          # package-time dependencies
Makefile                  # vendor/package/clean recipes
```

## How It Works

Sensu loads runtime assets before executing the command. When `sensu-python-runtime` is listed before this plugin asset, the runtime's `bin/` directory is added to `PATH`, so this template's `#!/usr/bin/env python` usage resolves to the packaged CPython runtime.

The wrapper in `bin/` sets:

```bash
PYTHONPATH="$ASSET_DIR/lib${PYTHONPATH:+:$PYTHONPATH}"
```

That lets imports resolve from dependencies vendored into this asset at package time.

For local testing on systems without a `python` command, run the wrapper with `PYTHON_BIN=python3`.

## Build

```bash
make vendor
make package
```

`make vendor` prefers `uv pip install --target lib -r requirements.txt` and falls back to `python3 -m pip install --target lib -r requirements.txt`.

## Customize

1. Rename `bin/my-python-check` to the command name Sensu should run.
2. Update `NAME` in the `Makefile`.
3. Replace `libexec/check.py` with your plugin logic.
4. Add dependencies to `requirements.txt`.
5. Package with `make package`.

Do not install dependencies at check runtime. Sensu agents should execute already-packaged assets without requiring network access.

## Sensu Check

```yaml
---
type: CheckConfig
api_version: core/v2
metadata:
  name: my-python-check
spec:
  command: my-python-check --message hello
  interval: 60
  publish: true
  runtime_assets:
    - sensu-python-runtime
    - my-python-check
  subscriptions:
    - linux
```
