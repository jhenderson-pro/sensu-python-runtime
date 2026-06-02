# Simple Disk Check

This example is a minimal Sensu check asset that uses only the Python standard library. It proves that the runtime asset places `python` on `PATH` and that normal Sensu plugin exit codes propagate correctly.

## Layout

```text
bin/simple-disk-check      # executable wrapper Sensu runs
libexec/check_disk.py      # Python implementation
```

The wrapper deliberately does not set `PYTHONPATH` because this check has no vendored dependencies.

## Package

```bash
make package
```

The packaged asset is written to `dist/`.

## Sensu Check

Register the runtime asset first, then register this check asset. A check config can reference both assets:

```yaml
---
type: CheckConfig
api_version: core/v2
metadata:
  name: simple-disk-check
spec:
  command: simple-disk-check --path / --warning 80 --critical 90
  interval: 60
  publish: true
  runtime_assets:
    - sensu-python-runtime
    - simple-disk-check
  subscriptions:
    - linux
```

Exit codes:

- `0`: usage is below warning threshold
- `1`: usage is at or above warning threshold
- `2`: usage is at or above critical threshold
- `3`: invalid arguments or runtime error
