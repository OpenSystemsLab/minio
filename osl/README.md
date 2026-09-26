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
osl/build.sh           # cross-compiles linux/amd64 in golang:1.24.8-alpine, packages osl/Dockerfile
osl/build.sh --push    # also pushes ghcr.io/opensystemslab/minio:<tag>-osl<rev>
```
Same flags as upstream's Makefile (`CGO_ENABLED=0 -tags kqueue -trimpath`, ldflags from
`buildscripts/gen-ldflags.go`, `MINIO_RELEASE=RELEASE`). `OSL_REV` bumps the image suffix.

## Verified 2026-09-26
- `minio --version` → `RELEASE.2025-10-15T17-29-55Z (commit-id=9e49d5e7a648…)`, go1.24.8 linux/amd64
- Pointed at a real subset of `opensystemslab-s3-storage` **without `.minio.sys`** (the old
  sync never copied it): the bucket was discovered, objects listed with their original
  timestamps, and a lab-report PDF downloaded intact.

## License
AGPL-3.0 (upstream). This is a straight rebuild; if source is ever modified, publish it here.
