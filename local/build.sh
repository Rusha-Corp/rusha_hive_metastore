docker buildx build \
    --platform linux/amd64 \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t registry.bitkubeops.com/hive_metastore:latest \
    . --push

docker buildx build \
    --platform linux/arm64 \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t registry.bitkubeops.com/hive_metastore:latest \
    . --push