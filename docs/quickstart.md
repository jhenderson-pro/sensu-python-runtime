# Quickstart

This guide registers `sensu-python-runtime`, packages the stdlib-only example check, and runs it through Sensu.

## Prerequisites

- Sensu Go with `sensuctl` configured.
- A Linux amd64 Sensu agent subscription, such as `linux`.
- A place to publish the example check tarball over HTTPS.

## Register the Runtime Asset

Download the generated runtime asset resource from the GitHub Release and create it:

```bash
curl -LO https://github.com/sensu/sensu-python-runtime/releases/download/v0.2.0-beta.1/asset.yml
sensuctl create -f asset.yml
```

The release asset YAML includes both supported builds:

- linux amd64 glibc for non-Alpine systems
- linux amd64 musl for Alpine

## Package the Simple Check

```bash
cd examples/simple-check
make package
```

This creates:

```text
dist/simple-disk-check_0.1.0_linux_amd64.tar.gz
dist/simple-disk-check_0.1.0_linux_amd64.tar.gz.sha512
```

Publish the tarball somewhere your Sensu agents can download it. Set these variables to the published URL and SHA-512:

```bash
export CHECK_ASSET_URL="https://example.com/assets/simple-disk-check_0.1.0_linux_amd64.tar.gz"
export CHECK_ASSET_SHA512="$(cut -d' ' -f1 dist/simple-disk-check_0.1.0_linux_amd64.tar.gz.sha512)"
```

## Register the Simple Check Asset

```bash
sensuctl asset create simple-disk-check \
  --url "$CHECK_ASSET_URL" \
  --sha512 "$CHECK_ASSET_SHA512" \
  --filter "entity.system.os == 'linux'" \
  --filter "entity.system.arch == 'amd64'"
```

## Create the Check

```bash
cat <<'EOF' | sensuctl create -f -
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
EOF
```

The runtime asset must appear before the plugin asset so the Sensu agent resolves `python` from `sensu-python-runtime`.

## Run It Once

```bash
sensuctl check execute simple-disk-check
sensuctl event list
```

The event output should include a status line similar to:

```text
OK disk_usage path=/ used=35.6% free_bytes=318623809536 total_bytes=494384795648
```

## Build the Runtime Locally

To audit the runtime packaging without publishing a release:

```bash
./build/fetch-upstream.sh
./build/repackage.sh glibc
./build/smoke-test.sh dist/*_glibc.tar.gz
```

For Alpine/musl smoke testing, run the test inside Alpine:

```bash
./build/repackage.sh musl
docker run --rm -v "$PWD:/work" alpine:3.20 \
  sh -c "apk add --no-cache bash && /work/build/smoke-test.sh /work/dist/*_musl.tar.gz"
```
