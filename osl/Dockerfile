# OpenSystemsLab build of MinIO, from source.
#
# Why this exists: MinIO archived its repo; the official images are no longer
# anonymously pullable (quay.io 401, Docker Hub "insufficient_scope") and
# dl.min.io binaries return 410. Our S3 data (open-webui-gitops#306) is stored
# in MinIO's on-disk format, which only a MinIO server can read.
#
# The binary is cross-compiled by osl/build.sh (not in this Dockerfile) because
# the version stamp needs the git checkout. This file only packages it.
FROM alpine:3.21
RUN apk add --no-cache ca-certificates curl
COPY minio /usr/bin/minio
EXPOSE 9000 9001
ENTRYPOINT ["/usr/bin/minio"]
CMD ["server", "/data", "--console-address", ":9001"]
LABEL org.opencontainers.image.source="https://github.com/OpenSystemsLab/minio" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.description="MinIO RELEASE.2025-10-15T17-29-55Z built from source by OpenSystemsLab (upstream archived)"
