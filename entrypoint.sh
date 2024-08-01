#!/bin/bash

set -x  # Enable debugging mode

# Default database driver
: "${DB_DRIVER:=derby}"

# Skip schema initialization if IS_RESUME is set
SKIP_SCHEMA_INIT="${IS_RESUME:-false}"

function initialize_hive {
  echo "Initializing Hive schema with DB_DRIVER: $DB_DRIVER"
  $HIVE_HOME/bin/schematool -dbType "$DB_DRIVER" -initOrUpgradeSchema
  if [[ $? -eq 0 ]]; then
    echo "Initialized schema successfully."
  else
    echo "Schema initialization failed!"
    exit 1
  fi
}

# Set Hive configuration directory
export HIVE_CONF_DIR="$HIVE_HOME/conf"
if [[ -d "${HIVE_CUSTOM_CONF_DIR:-}" ]]; then
  find "$HIVE_CUSTOM_CONF_DIR" -type f -exec ln -sfn {} "$HIVE_CONF_DIR"/ \;
  export HADOOP_CONF_DIR="$HIVE_CONF_DIR"
  export TEZ_CONF_DIR="$HIVE_CONF_DIR"
fi

# Set Hadoop client options including JVM heap size and logging configuration
export HADOOP_CLIENT_OPTS="${HADOOP_CLIENT_OPTS:-} -Xmx1G -Dhive.root.logger=DEBUG,console"


# Configure service-specific settings
case "$SERVICE_NAME" in
  hiveserver2)
    export HADOOP_CLASSPATH="$TEZ_HOME/*:$TEZ_HOME/lib/*:$HADOOP_CLASSPATH"
    ;;
  metastore)
    export METASTORE_PORT="${METASTORE_PORT:-9083}"
    ;;
  *)
    echo "Unknown SERVICE_NAME: $SERVICE_NAME"
    exit 1
    ;;
esac

# Initialize Hive schema if not skipped
if [[ "$SKIP_SCHEMA_INIT" == "false" ]]; then
  initialize_hive
fi


# Execute Hive command with required configurations
exec $HIVE_HOME/bin/hive \
  --skiphadoopversion \
  --skiphbasecp \
  --service "$SERVICE_NAME" \
  --hiveconf fs.s3a.access.key="$AWS_ACCESS_KEY_ID" \
  --hiveconf fs.s3a.secret.key="$AWS_SECRET_ACCESS_KEY" \
  --hiveconf hive.metastore.warehouse.dir="$WAREHOUSE_LOCATION" \
  --hiveconf hive.metastore.uris="$METASTORE_URIS" \
  --hiveconf fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider \
  --hiveconf fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
