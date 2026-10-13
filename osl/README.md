# OpenSystemsLab build of MinIO

Branch `osl/RELEASE.2025-10-15T17-29-55Z` = upstream's **final** release tag plus this
`osl/` folder. No source changes.

## Why
- `minio/minio` is **archived**; its last release has no binaries, `dl.min.io` returns
  **410**, and the images are no longer anonymously pullable (quay.io 401, Docker Hub
  `insufficient_scope`).
- GemIntellect's S3 proxy data (`s3://opensystemslab-s3-storage`) is stored in **MinIO's
  on-disk format** (`xl.meta` / `part.N`), which only a MinIO server can read
  (open-webui-gitops#306).

## Build
```bash
osl/build.sh           # cross-compiles linux/arm64 (the org standard) in golang:1.24.8-alpine, packages osl/Dockerfile
osl/build.sh --push    # pushes ghcr.io/opensystemslab/minio:v<osl/VERSION>
OSL_ARCHES="amd64 arm64" osl/build.sh --push   # also amd64, only while an amd64 box needs it
```
The upstream release comes from `osl/UPSTREAM` (not `git describe`, which in a fresh clone
finds an older `RELEASE.*` tag). Same flags as upstream's Makefile (`CGO_ENABLED=0 -tags kqueue -trimpath`, ldflags from
`buildscripts/gen-ldflags.go`, `MINIO_RELEASE=RELEASE`).

## Versioning
Image tags follow the org convention **`vX.Y.Z`** (every Flux `ImagePolicy` filters
`^v(\d+\.\d+\.\d+)$`), from `osl/VERSION`. Bump the patch for a rebuild, the minor if
the source ever changes. The upstream release is recorded in the image labels.

| Tag | Upstream | Notes |
|---|---|---|
| `v1.0.0` | `RELEASE.2025-10-15T17-29-55Z` | first build, **amd64 only**. Same digest as the interim tag `RELEASE.2025-10-15T17-29-55Z-osl1` (`sha256:52813653…`), which is superseded |
| `v1.0.1` | `RELEASE.2025-10-15T17-29-55Z` | same source, rebuilt for **amd64 and arm64** (moving production to ARM, open-webui-gitops#458). Go cross-compiles both natively; no emulation |

## Verified 2026-09-26
- `minio --version` → `RELEASE.2025-10-15T17-29-55Z (commit-id=9e49d5e7a648…)`, go1.24.8 linux/amd64
- Pointed at a real subset of `opensystemslab-s3-storage` **without `.minio.sys`** (the old
  sync never copied it): the bucket was discovered, objects listed with their original
  timestamps, and a lab-report PDF downloaded intact.

## License
AGPL-3.0 (upstream). This is a straight rebuild; if source is ever modified, publish it here.
