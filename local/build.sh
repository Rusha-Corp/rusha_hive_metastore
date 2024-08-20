#!/bin/bash

docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t registry.bitkubeops.com/hive_metastore:v10 \
    . --push