# Migration from 0.1

The original `sensu-python-runtime` asset packaged Python 3.6.11 with a Docker-based build process. The v0.2.0 beta packages Python 3.13 from `python-build-standalone`.

This is a major runtime jump. Test every Python plugin in a non-production Sensu environment before replacing the old asset.

## What Changed

- Runtime Python changes from 3.6.11 to 3.13.x.
- Builds come from `python-build-standalone`; this project repackages rather than compiles CPython.
- Supported targets are linux amd64 glibc and linux amd64 musl.
- Legacy CentOS 6/7, Debian 8/9, and old Alpine build paths are not maintained.
- Python plugin dependencies should be vendored into each plugin asset, not installed at runtime.

## Update Check Configs

Old checks may reference the historical asset name or a single asset that bundled assumptions from the old repo. New checks should reference the runtime asset and the plugin asset separately:

```yaml
spec:
  command: my-python-check
  runtime_assets:
    - sensu-python-runtime
    - my-python-check
```

List `sensu-python-runtime` before the plugin asset so the plugin's `python` command resolves to the packaged runtime.

## Python Compatibility Breakages

Python 3.13 includes years of removals and behavior changes since 3.6. Common breakages include:

`imp` removed

Replace `imp` usage with `importlib`.

```python
import importlib.util
```

`distutils` removed

Replace `distutils` usage with `setuptools`, `packaging`, or standard library alternatives depending on the specific API.

Old dependency pins

Many packages that supported Python 3.6 do not support Python 3.13 without newer versions. Rebuild vendored dependencies using current pins that support Python 3.13.

Old syntax assumptions

Python 3.13 can run most valid Python 3.6 syntax, but code that dynamically parses or rejects newer syntax may fail if dependencies use modern features such as pattern matching, union type syntax, or newer typing constructs.

Deprecated APIs

Warnings that were easy to ignore on 3.6 may now be removals. Run plugins locally with Python 3.13 and fix deprecation-driven failures before packaging.

## Packaging Changes

Use the v0.2.0 plugin asset pattern:

```text
bin/
libexec/
lib/
requirements.txt
```

The wrapper in `bin/` should set `PYTHONPATH` to the asset's `lib/` directory:

```bash
export PYTHONPATH="$ASSET_DIR/lib${PYTHONPATH:+:$PYTHONPATH}"
PYTHON_BIN=${PYTHON_BIN:-python}
exec "$PYTHON_BIN" "$ASSET_DIR/libexec/check.py" "$@"
```

See [packaging-python-checks.md](packaging-python-checks.md) and [examples/plugin-template/](../examples/plugin-template/).

## TLS Checks

If HTTPS checks fail after migration, point the check at the host CA bundle:

```yaml
spec:
  command: >-
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
    my-python-check
```

See [troubleshooting-tls.md](troubleshooting-tls.md).

## Test Plan

1. Package the plugin asset with Python 3.13-compatible dependency pins.
2. Register `sensu-python-runtime` and the plugin asset in a test namespace.
3. Run `sensuctl check execute <check-name>`.
4. Verify exit codes and event output.
5. Roll out one subscription or environment at a time.

Do not assume that passing under Python 3.6 means the plugin is ready for Python 3.13.
