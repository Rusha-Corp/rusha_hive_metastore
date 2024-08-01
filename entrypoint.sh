#!/bin/bash

set -x  # Enable debugging mode

# Default database driver
: "${DB_DRIVER:=derby}"

# Skip schema initialization if IS_RESUME is set
SKIP_SCHEMA_INIT="${IS_RESUME:-false}"

# Function to check and validate the DB_DRIVER
check_db_driver() {
  case "$DB_DRIVER" in
    derby)
      echo "Using Derby as the Metastore database"
      ;;
    postgres)
      echo "Using PostgreSQL as the Metastore database"
      ;;
    *)
      echo "Invalid DB_DRIVER: $DB_DRIVER"
      exit 1
      ;;
  esac
}

# Function to initialize the Hive schema
initialize_hive() {
  echo "Initializing Hive schema with DB_DRIVER: $DB_DRIVER"
  $HIVE_HOME/bin/schematool -dbType "$DB_DRIVER" -initOrUpgradeSchema
  if [[ $? -eq 0 ]]; then
    echo "Initialized schema successfully.."
  else
    echo "Schema initialization failed!"
    exit 1
  fi
}

# Validate DB_DRIVER
check_db_driver

# Set Hive configuration directory
export HIVE_CONF_DIR="$HIVE_HOME/conf"
if [[ -d "${HIVE_CUSTOM_CONF_DIR:-}" ]]; then
  find "$HIVE_CUSTOM_CONF_DIR" -type f -exec ln -sfn {} "$HIVE_CONF_DIR"/ \;
  export HADOOP_CONF_DIR="$HIVE_CONF_DIR"
  export TEZ_CONF_DIR="$HIVE_CONF_DIR"
fi

# Configure Hadoop client options
export HADOOP_CLIENT_OPTS="${HADOOP_CLIENT_OPTS:-} -Xmx1G $SERVICE_OPTS"

# Configure service-specific settings
case "$SERVICE_NAME" in
  hiveserver2)
    export HADOOP_CLASSPATH="$TEZ_HOME/*:$TEZ_HOME/lib/*:$HADOOP_CLASSPATH"
    export SKIP_SCHEMA_INIT="true"
    ;;
  metastore)
    export METASTORE_PORT="${METASTORE_PORT:-9083}"
    ;;
esac

# Initialize Hive schema if not skipped
if [[ "$SKIP_SCHEMA_INIT" == "false" ]]; then
  initialize_hive
fi



# Start the Hive service with configuration
exec $HIVE_HOME/bin/hive \
  --service "$SERVICE_NAME" \
  --hiveconf fs.s3a.access.key="$AWS_ACCESS_KEY_ID" \
  --hiveconf fs.s3a.secret.key="$AWS_SECRET_ACCESS_KEY" \
  --hiveconf hive.metastore.warehouse.dir="$WAREHOUSE_LOCATION" \
  --hiveconf hive.metastore.uris="$METASTORE_URIS" \
  --hiveconf fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider \
  --hiveconf hive.root.logger=DEBUG,console \
  --hiveconf fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
