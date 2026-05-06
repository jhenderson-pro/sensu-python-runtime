# CLAUDE.md — Project Context for sensu-python-runtime

This file is the canonical context for Claude Code (and any other AI collaborator) working in this repository. Read it first. Re-read it when in doubt.

## What this project is

`sensu-python-runtime` produces **Sensu Go dynamic runtime assets containing portable CPython interpreters**. A Sensu agent loads the runtime asset, then loads a separate plugin asset that contains a Python check/handler/mutator/filter and any vendored dependencies. The runtime asset places `python`, `python3`, and `pip` on the agent's `$PATH` for the duration of the check, so the plugin's `#!/usr/bin/env python` shebang resolves correctly.

This is a **distribution and packaging project**, not a CPython project. We do not compile Python. We repackage upstream binaries.

## Vision (one sentence)

A maintained, signed, checksum-verified, Bonsai-published CPython runtime asset for Sensu Go on Linux glibc/musl × amd64/arm64, with a documented plugin packaging pattern and working examples.

## What this project is *not* (non-goals)

These are non-goals. Decline scope-creep requests politely and point back to this list:

- A replacement for system Python.
- A guarantee that every native Python wheel will work on every target. Wheels with C extensions that link against system libraries (e.g., heavy ML stacks) are out of scope.
- Support for end-of-life Python versions (3.11 and earlier).
- Support for end-of-life or niche operating systems (CentOS 6/7, Debian 8/9, Alpine 3.x, AIX, Solaris).
- A bundler for individual checks. PyInstaller solves a different problem; we mention it in docs as an alternative but do not adopt it.
- A monorepo for arbitrary Python tooling. We ship the runtime, a plugin template, and example checks. That's it.

## The technical engine

We consume **`python-build-standalone`** (maintained by Astral) as the source of truth for CPython binaries. CI downloads the upstream tarball, verifies its published SHA-256, repackages it into Sensu's expected layout, generates SHA-512 checksums, attaches an SBOM and build provenance attestation, and publishes a GitHub Release.

We do **not** write Dockerfiles to compile CPython. The legacy repo did this and it killed the project. If you find yourself reaching for `gcc` or `./configure`, stop and re-read this section.

Why this choice:
- **Zero compilation in our pipeline.** Astral has already solved the hard problems (OpenSSL pathing, libffi, sqlite, etc.).
- **True portability.** `install_only` builds are statically linked where possible and designed to run hermetically.
- **Trusted upstream maintenance.** Astral (uv, ruff) actively maintains these builds with a real release cadence.
- **Multi-target coverage.** glibc, musl, macOS, Windows, amd64, arm64 — all already published.

## Support matrix (v0.2.0-beta.1 scope only)

| Asset | libc | Arch | Upstream `python-build-standalone` triple |
|---|---|---|---|
| sensu-python-runtime-3.13 (linux-glibc) | glibc | amd64 | `x86_64-unknown-linux-gnu` |
| sensu-python-runtime-3.13 (linux-musl) | musl  | amd64 | `x86_64-unknown-linux-musl` |

That is the entire initial scope. arm64, Python 3.12, Windows, and macOS are explicit Phase 5 work — do not add them earlier without an issue, design discussion, and a real user request.

**Python version policy:** Primary tier is Python 3.13 (the modern stable default). Python 3.12 is a secondary tier we'll add only if a real user demonstrates need. Anything 3.11 or earlier is out of scope — those versions are EOL or close to it and a revived community project should anchor to the present.

## The three deliverables

This repository ships **three distinct things**. Keeping the boundaries clean is essential — blurring them is what made the original repo hard to follow.

### Deliverable A — The Python runtime asset (the core product)

The repackaged `python-build-standalone` tarball, formatted as a Sensu dynamic runtime asset:

```
sensu-python-runtime_<version>_python-<py-version>_linux_<arch>_<libc>.tar.gz
├── bin/
│   ├── python          # symlink or wrapper -> python3.13
│   ├── python3         # symlink or wrapper -> python3.13
│   ├── python3.13      # the actual interpreter
│   └── pip             # the actual pip
├── lib/
│   └── python3.13/     # stdlib and dynload
├── include/
└── share/
```

When a Sensu agent loads this asset, `bin/` is prepended to `$PATH`. That's the entire mechanism — anything with `#!/usr/bin/env python` in a plugin asset will resolve to *our* `python`.

This is the only deliverable produced by `release.yml`. It is what gets published to Bonsai.

### Deliverable B — The plugin asset template (`examples/plugin-template/`)

A documented scaffold that teaches plugin authors **the right way to package a Python check that depends on the runtime asset**. It demonstrates:

- The expected directory structure: `bin/` (executable wrapper), `libexec/` (the actual Python script), `lib/` (vendored dependencies installed via `uv pip install --target lib`).
- A wrapper script that sets `PYTHONPATH=$ASSET_PATH/lib` so vendored deps import correctly.
- A `Makefile` (or `justfile`) with `vendor`, `package`, `clean` recipes.
- A `README.md` explaining each piece.

**Critical pattern: vendor, don't `pip install` at runtime.** Plugin authors must `uv pip install --target lib` at *package time* and ship the resulting `lib/` directory inside the asset. Sensu agents must not do network installs during a check.

This is **not published to Bonsai**. It's a reference for plugin authors to copy.

### Deliverable C — Example Sensu checks (`examples/simple-check/`, `examples/dependency-check/`)

Two minimal, working Sensu checks that prove the full pipeline works:

- **`simple-check/`** — uses only the Python stdlib (e.g., `shutil.disk_usage`). Proves the runtime asset loads, the shebang resolves, exit codes propagate correctly.
- **`dependency-check/`** — uses a vendored third-party dependency (`requests` or `httpx`). Proves the plugin-template pattern works end-to-end: vendored `lib/` imports correctly via `PYTHONPATH`.

These ship as part of the repo (and the docs reference them) but they are **not published to Bonsai as standalone assets**. They're documentation-by-example.

### What this means for scope

If a request would add a fourth deliverable (a Sensu handler library, a Python-based metric processor, a generic CLI tool), it doesn't belong in this repo. Push back, point here, suggest a separate repo.

## Asset naming convention

```
sensu-python-runtime_<asset-version>_python-<py-version>_linux_<arch>_<libc>.tar.gz
```

Example: `sensu-python-runtime_0.2.0-beta.1_python-3.13.1_linux_amd64_glibc.tar.gz`

The asset version is *our* semver — it tracks our packaging changes. The Python version is the upstream CPython patch level. They evolve independently.

## Repository structure (target)

```
.github/workflows/
  build.yml          # PR-triggered: fetch upstream, repackage, smoke-test
  release.yml        # tag-triggered: build + sign + SBOM + GitHub Release
  upstream-bump.yml  # scheduled: opens PR when python-build-standalone releases
  security.yml       # scheduled: trivy/grype on artifacts, shellcheck, hadolint
build/
  upstream.json      # pinned upstream version + SHA-256 hashes
  fetch-upstream.sh  # download + verify python-build-standalone tarball
  repackage.sh       # flatten layout, smoke-test interpreter
  smoke-test.sh      # exercises bin/python after repackaging
  generate-asset.sh  # produce core/v2 Asset YAML for a release
examples/
  simple-check/      # stdlib only — Deliverable C
  dependency-check/  # vendored dep via `uv pip install --target lib` — Deliverable C
  plugin-template/   # canonical pattern for plugin authors — Deliverable B
docs/
  quickstart.md
  packaging-python-checks.md
  migration-from-0.1.md
  troubleshooting-tls.md
  support-policy.md
  legacy/            # old README and Dockerfiles, preserved for history
SECURITY.md
SUPPORT.md
CHANGELOG.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
README.md            # landing page only — what / why / quick start / links
.bonsai.yml          # multi-build, current Bonsai schema
```

## Two YAML files — keep them straight

- `.bonsai.yml` is the **Bonsai registry manifest**. Uses `#{version}` interpolation. Lives at the repo root. Read by Bonsai when registering and updating asset versions.
- The `core/v2` Asset YAML is the **Sensu resource** users `sensuctl create`. We generate this per-release and attach it to the GitHub Release. It is *not* the same file as `.bonsai.yml`.

Both Gemini and ChatGPT blurred this in our planning. Do not.

## Plugin packaging pattern (summary)

Plugin authors put their script in `libexec/`, a wrapper in `bin/`, and vendored dependencies in `lib/` (populated by `uv pip install --target lib -r requirements.txt`, with plain `pip install --target lib` as fallback). The wrapper sets `PYTHONPATH` to the asset's own `lib/`. Sensu's runtime-asset PATH ordering ensures the runtime asset's `python` is found first.

The `examples/plugin-template/` directory is the authoritative example. When in doubt, copy it. Full documentation lives in `docs/packaging-python-checks.md`.

## Security baseline (day one, non-negotiable)

- SHA-512 checksums file per release, generated in CI.
- GitHub Actions `attest-build-provenance` attestation for every artifact (SLSA build provenance).
- SBOM in CycloneDX or SPDX format, attached to each release (use `anchore/sbom-action` or `syft`).
- Trivy/grype scan on artifacts in `security.yml`.
- **Verify upstream `python-build-standalone` SHA-256 before repackaging.** Trust-but-verify Astral; if their pipeline is ever compromised we don't want to be a downstream amplifier.
- Dependabot for GitHub Actions dependencies.
- Scheduled `upstream-bump.yml` that opens a PR when a new `python-build-standalone` release lands.

We do **not** do custom cosign/sigstore signing for v0.2.0. Provenance attestations + SHA-512 are the right baseline. Revisit later.

## Coding and contribution conventions

- Shell scripts use `bash` with `set -euo pipefail` at the top. They are linted by `shellcheck` in CI.
- Dockerfiles (only used for repackaging environments, never for compiling Python) are linted by `hadolint`.
- All scripts must work on both macOS and Linux for local development. If a script needs GNU-only features, document it and gate behind an OS check.
- Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`) for commit messages. This drives the changelog.
- One logical change per PR. Long PRs get split.
- Every user-facing change updates `CHANGELOG.md` under `## [Unreleased]`.

## When you're unsure

If a request would expand scope beyond this document, push back and ask. The single biggest risk to this project is the same risk that killed the original: trying to support too much. "Smaller and more professional" beats "broader."

## Useful upstream references

- python-build-standalone releases: <https://github.com/astral-sh/python-build-standalone/releases>
- Sensu asset reference: <https://docs.sensu.io/sensu-go/latest/plugins/assets/>
- Bonsai asset index: <https://bonsai.sensu.io/>
- Sensu query expressions (asset filters): <https://docs.sensu.io/sensu-go/latest/observability-pipeline/observe-filter/sensu-query-expressions/>
