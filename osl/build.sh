#!/usr/bin/env bash
# Build ghcr.io/opensystemslab/minio from this checkout (see osl/README.md).
#   osl/build.sh            build linux/arm64; load it locally to test
#   osl/build.sh --push     build and push
#   OSL_ARCHES="amd64 arm64" also build amd64 (default: arm64 only)
# ARM64 is the org's image standard (2026-10-13). Production (open-webui-gitops box 2) is
# amd64 until the Graviton cutover and pins v1.0.0 (amd64); build amd64 too only if an
# amd64 box needs a new version before then.
set -euo pipefail
cd "$(dirname "$0")/.."
# The upstream release this branch is built from. Read from osl/UPSTREAM, NOT `git describe`:
# the fork does not carry upstream's final tag, so in a fresh clone `git describe --match
# 'RELEASE.*'` returns an OLDER release (RELEASE.2025-09-07T16-13-09Z) and the binary would
# report the wrong version.
TAG=$(cat osl/UPSTREAM)
VERSION=$(echo "$TAG" | sed -E 's/^RELEASE\.([0-9-]+)T([0-9]+)-([0-9]+)-([0-9]+)Z$/\1T\2:\3:\4Z/')
GOIMG=golang:1.24.8-alpine                               # go.mod: toolchain go1.24.8
# Org convention: vX.Y.Z (every Flux ImagePolicy filters ^v(\d+\.\d+\.\d+)$).
# osl/VERSION is OUR version; bump it per rebuild. The upstream release is in
# the image labels, not the tag.
IMAGE=ghcr.io/opensystemslab/minio:v$(cat osl/VERSION)
ARCHES="${OSL_ARCHES:-arm64}"

# Cross-compile natively for every architecture (no emulation: Go cross-compiles with
# CGO off). Same tags/flags as upstream's Makefile. One binary per architecture,
# osl/minio-<arch>, which osl/Dockerfile picks by TARGETARCH.
for arch in $ARCHES; do
  docker run --rm -v "$PWD":/src -w /src -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH="$arch" \
    -e GOFLAGS=-buildvcs=false -e MINIO_RELEASE=RELEASE "$GOIMG" sh -c "
      apk add -q --no-cache git >/dev/null &&
      git config --global --add safe.directory /src &&
      go build -tags kqueue -trimpath -ldflags \"\$(go run buildscripts/gen-ldflags.go $VERSION)\" -o osl/minio-$arch ."
  file "osl/minio-$arch" 2>/dev/null || true
done

PLATFORMS=$(for a in $ARCHES; do printf 'linux/%s,' "$a"; done)
PLATFORMS=${PLATFORMS%,}
ARGS=(--build-arg OSL_VERSION="$(cat osl/VERSION)" --build-arg UPSTREAM="$TAG" -t "$IMAGE")

# A multi-platform image needs a docker-container builder; use a throwaway one.
BUILDER=osl-minio-build
docker buildx create --name "$BUILDER" --driver docker-container >/dev/null
trap 'docker buildx rm "$BUILDER" >/dev/null 2>&1 || true' EXIT

if [ "${1:-}" = "--push" ]; then
  docker buildx build --builder "$BUILDER" --platform "$PLATFORMS" "${ARGS[@]}" --push osl
  docker buildx imagetools inspect "$IMAGE" | grep -E 'Platform:' || true
  echo "pushed $IMAGE ($PLATFORMS)"
else
  docker buildx build --builder "$BUILDER" --platform "$PLATFORMS" "${ARGS[@]}" -o type=cacheonly osl
  native="linux/$(docker version --format '{{.Server.Arch}}')"
  docker buildx build --builder "$BUILDER" --platform "$native" "${ARGS[@]}" --load osl
  echo "built $IMAGE ($PLATFORMS); loaded $native locally"
fi
