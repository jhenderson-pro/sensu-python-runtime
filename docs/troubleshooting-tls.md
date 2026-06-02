# Troubleshooting TLS

`sensu-python-runtime` ships a portable Python interpreter. It does not ship or replace the host's CA trust store.

If a Python check fails with certificate verification errors, point the check at the agent host's CA bundle or CA directory.

Common errors:

```text
ssl.SSLCertVerificationError: [SSL: CERTIFICATE_VERIFY_FAILED]
requests.exceptions.SSLError
unable to get local issuer certificate
```

## Environment Variables

For Python's standard library TLS clients, use:

- `SSL_CERT_FILE`: path to a CA bundle file
- `SSL_CERT_DIR`: path to a directory of hashed CA certificates

For `requests`, also set:

- `REQUESTS_CA_BUNDLE`: path to a CA bundle file

Setting both `SSL_CERT_FILE` and `REQUESTS_CA_BUNDLE` is a good default for plugin assets that may use either stdlib clients or `requests`.

## Debian and Ubuntu

Typical CA bundle:

```text
/etc/ssl/certs/ca-certificates.crt
```

Sensu command example:

```yaml
spec:
  command: >-
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
    dependency-http-check --url https://example.com --timeout 5
  runtime_assets:
    - sensu-python-runtime
    - dependency-http-check
```

## RHEL, CentOS Stream, Fedora, Rocky, Alma

Typical CA bundle:

```text
/etc/pki/tls/certs/ca-bundle.crt
```

Sensu command example:

```yaml
spec:
  command: >-
    SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
    REQUESTS_CA_BUNDLE=/etc/pki/tls/certs/ca-bundle.crt
    dependency-http-check --url https://example.com --timeout 5
  runtime_assets:
    - sensu-python-runtime
    - dependency-http-check
```

## Alpine

Typical CA bundle:

```text
/etc/ssl/certs/ca-certificates.crt
```

Sensu command example:

```yaml
spec:
  command: >-
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
    dependency-http-check --url https://example.com --timeout 5
  runtime_assets:
    - sensu-python-runtime
    - dependency-http-check
```

## CA Directory Example

If your environment uses a hashed CA directory instead of a single bundle file:

```yaml
spec:
  command: >-
    SSL_CERT_DIR=/etc/ssl/certs
    dependency-http-check --url https://example.com --timeout 5
  runtime_assets:
    - sensu-python-runtime
    - dependency-http-check
```

## Custom Internal CA

Install your internal CA certificate into the agent host's trust store through your normal OS configuration management. Then use the same bundle path in the check command.

Avoid disabling certificate verification in plugin code. If TLS fails, fix the trust path.
