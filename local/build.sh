#!/bin/bash

docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t europe-west1-docker.pkg.dev/owa-gemini/docker-registry/hive_metastore:v11 \
    . --push