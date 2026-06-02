# Dependency HTTP Check

This example is a Sensu check asset with a vendored third-party dependency. It uses `requests` to make an HTTP request and returns Sensu plugin exit codes based on the response.

## Layout

```text
bin/dependency-http-check  # executable wrapper Sensu runs
libexec/check_http.py      # Python implementation
lib/                       # vendored dependencies, created by make vendor
requirements.txt           # package-time dependencies
```

The wrapper sets `PYTHONPATH` to the asset's own `lib/` directory. Sensu loads `sensu-python-runtime` first, so `#!/usr/bin/env python` resolves to the runtime asset while imports resolve to vendored packages in this asset.

## Package

```bash
make package
```

`make vendor` uses `uv pip install --target lib` when `uv` is available and falls back to `python3 -m pip install --target lib`.

## Sensu Check

```yaml
---
type: CheckConfig
api_version: core/v2
metadata:
  name: dependency-http-check
spec:
  command: dependency-http-check --url https://example.com --timeout 5
  interval: 60
  publish: true
  runtime_assets:
    - sensu-python-runtime
    - dependency-http-check
  subscriptions:
    - linux
```

Exit codes:

- `0`: response status is below the warning threshold
- `1`: response status is at or above the warning threshold
- `2`: response status is at or above the critical threshold
- `3`: invalid arguments, missing dependency, or request failure
