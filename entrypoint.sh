#!/bin/bash

set -x

: ${DB_DRIVER:=derby}

SKIP_SCHEMA_INIT="${IS_RESUME:-false}"

function check_db_driver {
  if [ "$DB_DRIVER" == "derby" ]; then
    echo "Using Derby as the Metastore database"
  elif [ "$DB_DRIVER" == "postgres" ]; then
    echo "Using PostgreSQL as the Metastore database"
  else
    echo "Invalid DB_DRIVER: $DB_DRIVER"
    exit 1
  fi
}

function initialize_hive {
  echo "Initializing Hive schema with DB_DRIVER: $DB_DRIVER"
  $HIVE_HOME/bin/schematool -dbType $DB_DRIVER -initOrUpgradeSchema
  if [ $? -eq 0 ]; then
    echo "Initialized schema successfully.."
  else
    echo "Schema initialization failed!"
    exit 1
  fi
}

# Validate the DB_DRIVER
check_db_driver

export HIVE_CONF_DIR=$HIVE_HOME/conf
if [ -d "${HIVE_CUSTOM_CONF_DIR:-}" ]; then
  find "${HIVE_CUSTOM_CONF_DIR}" -type f -exec \
    ln -sfn {} "${HIVE_CONF_DIR}"/ \;
  export HADOOP_CONF_DIR=$HIVE_CONF_DIR
  export TEZ_CONF_DIR=$HIVE_CONF_DIR
fi

export HADOOP_CLIENT_OPTS="$HADOOP_CLIENT_OPTS -Xmx1G $SERVICE_OPTS"
if [[ "${SKIP_SCHEMA_INIT}" == "false" ]]; then
  # handles schema initialization
  initialize_hive
fi

export HADOOP_CLASSPATH=$TEZ_HOME/*:$TEZ_HOME/lib/*:$HADOOP_CLASSPATH
export METASTORE_PORT=${METASTORE_PORT:-9083}

# trigger update

exec $HIVE_HOME/bin/hive \
        --skiphadoopversion \
        --skiphbasecp \
        --service $SERVICE_NAME\
        --hiveconf fs.s3a.access.key=$AWS_ACCESS_KEY_ID \
        --hiveconf fs.s3a.secret.key=$AWS_SECRET_ACCESS_KEY \
        --hiveconf hive.metastore.warehouse.dir=$WAREHOUSE_LOCATION \
        --hiveconf fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider\
        --hiveconf hive.root.logger=DEBUG,console \
        --hiveconf fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
