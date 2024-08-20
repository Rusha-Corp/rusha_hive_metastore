#!/bin/bash

docker build . -t 

# hive server2
docker run -d -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 \
--env SERVICE_OPTS="-Dhive.metastore.uris=thrift://metastore:9083" \
--env IS_RESUME="true" \
--name hiveserver2-standalone apache/hive:${HIVE_VERSION}

# metastore standalone
export HIVE_VERSION=4.0.0
docker run -d -p 9083:9083 --env SERVICE_NAME=metastore --env DB_DRIVER=postgres \
--env SERVICE_OPTS="-Djavax.jdo.option.ConnectionDriverName=org.postgresql.Driver -Djavax.jdo.option.ConnectionURL=jdbc:postgresql://postgres:5432/metastore_db -Djavax.jdo.option.ConnectionUserName=hive -Djavax.jdo.option.ConnectionPassword=password" \
--mount source=warehouse,target=/opt/hive/data/warehouse \
--name metastore-standalone apache/hive:${HIVE_VERSION}
