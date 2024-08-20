#!/bin/bash

docker buildx build \
    --platform linux/amd64 \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t registry.bitkubeops.com/hive_metastore:v2 \
    . --push

docker buildx build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t registry.bitkubeops.com/hive_metastore:v2 \
    . --push

docker run -d -p 5432:5432 --env POSTGRES_USER hive \
--env POSTGRES_PASSWORD=password --env POSTGRES_DB=metastore_db --name postgres postgres:15

# hive server2
docker run -d -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 \
--env SERVICE_OPTS="-Dhive.metastore.uris=thrift://metastore:9083" \
--env IS_RESUME="true" \
--name hiveserver2 registry.bitkubeops.com/hive_metastore:v2

# metastore standalone
export HIVE_VERSION=4.0.0
docker run -d -p 9083:9083 --env SERVICE_NAME=metastore --env DB_DRIVER=postgres \
--env SERVICE_OPTS="-Djavax.jdo.option.ConnectionDriverName=org.postgresql.Driver -Djavax.jdo.option.ConnectionURL=jdbc:postgresql://postgres:5432/metastore_db -Djavax.jdo.option.ConnectionUserName=hive -Djavax.jdo.option.ConnectionPassword=password" \
--mount source=warehouse,target=/opt/hive/data/warehouse \
--name metastore  registry.bitkubeops.com/hive_metastore:v2
