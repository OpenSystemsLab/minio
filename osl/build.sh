#!/usr/bin/env bash
# Build ghcr.io/opensystemslab/minio from this checkout (see osl/README.md).
#   osl/build.sh            build only
#   osl/build.sh --push     build and push
set -euo pipefail
cd "$(dirname "$0")/.."
TAG=$(git describe --tags --abbrev=0 --match 'RELEASE.*')  # upstream tag, not our vX.Y.Z
VERSION=$(echo "$TAG" | sed -E 's/^RELEASE\.([0-9-]+)T([0-9]+)-([0-9]+)-([0-9]+)Z$/\1T\2:\3:\4Z/')
GOIMG=golang:1.24.8-alpine                               # go.mod: toolchain go1.24.8
# Org convention: vX.Y.Z (every Flux ImagePolicy filters ^v(\d+\.\d+\.\d+)$).
# osl/VERSION is OUR version; bump it per rebuild. The upstream release is in
# the image labels, not the tag.
IMAGE=ghcr.io/opensystemslab/minio:v$(cat osl/VERSION)

# Cross-compile natively (no emulation): CGO off, same tags/flags as upstream's Makefile.
docker run --rm -v "$PWD":/src -w /src -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH=amd64 \
  -e GOFLAGS=-buildvcs=false -e MINIO_RELEASE=RELEASE "$GOIMG" sh -c "
    apk add -q --no-cache git >/dev/null &&
    git config --global --add safe.directory /src &&
    go build -tags kqueue -trimpath -ldflags \"\$(go run buildscripts/gen-ldflags.go $VERSION)\" -o osl/minio ."
file osl/minio 2>/dev/null || true
docker buildx build --platform linux/amd64 -t "$IMAGE" --build-arg OSL_VERSION="$(cat osl/VERSION)" --build-arg UPSTREAM="$TAG" --load osl
[ "${1:-}" = "--push" ] && docker push "$IMAGE"
echo "built $IMAGE"
