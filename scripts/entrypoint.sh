#!/bin/sh

DIR=$(dirname "${0}")

# For Livy properties, see
# https://livy.incubator.apache.org/get-started/

. "${DIR}/spark-entrypoint-helpers.sh"

# WebUI

if [ -n "${PROP_LIVY_livy_server_port}" ]; then
	export LIVY_PORT="${PROP_LIVY_livy_server_port}"
elif [ -z "${LIVY_PORT}" ]; then
	export LIVY_PORT="8998"
	echo "Variable 'LIVY_PORT' should be set (otherwise, the default '${LIVY_PORT}' will be utilized)!" >&2
fi

export PROP_LIVY_livy_server_port="${LIVY_PORT}"

# Spark

if [ -n "${PROP_LIVY_livy_spark_master}" ]; then
	export MASTER="${PROP_LIVY_livy_spark_master}"
elif [ -z "${MASTER}" ]; then
	export MASTER="local[*]"
	echo "Variable 'MASTER' should be set correctly to a Spark master URL (otherwise, the default '${MASTER}' will be utilised)!" >&2
fi

export PROP_LIVY_livy_spark_master="${MASTER}"

if [ -n "${DEPLOY_MODE}" -a -z "${PROP_LIVY_livy_spark_deployMode}" ]; then
	export PROP_LIVY_livy_spark_deployMode="${DEPLOY_MODE}"
fi

set_histui_port
set_log_dir

# Recovery (session persistence)
# Note: Session recovery requires YARN.

if [ "${PROP_LIVY_livy_server_recovery_mode}" = "recovery" -a "${PROP_LIVY_livy_server_recovery_state___store}" = "filesystem" -a -n "${PROP_LIVY_livy_server_recovery_state___store_url}" ]; then
	export RECOVERY_DIR="${PROP_LIVY_livy_server_recovery_state___store_url#file://}"
fi
if [ -n "${RECOVERY_DIR}" ]; then
	mkdir -vp "${RECOVERY_DIR}"
	chmod -v 700 "${RECOVERY_DIR}"
	chown -R livy:livy "${RECOVERY_DIR}"
	export PROP_LIVY_livy_server_recovery_mode="recovery"
	export PROP_LIVY_livy_server_recovery_state___store="filesystem"
	export PROP_LIVY_livy_server_recovery_state___store_url="file://${RECOVERY_DIR}"
fi

if [ -z "${PROP_YARN_yarn_resourcemanager_hostname}" -a -n "${RESOURCE_MANAGER}" ]; then
	export PROP_YARN_yarn_resourcemanager_hostname="${RESOURCE_MANAGER}"
fi
if [ -z "${PROP_YARN_yarn_resourcemanager_hostname}" -a -n "${RECOVERY_DIR}" ]; then
	echo "Variable 'RECOVERY_DIR' set and variable 'RESOURCE_MANAGER' unset! Session recovery requires YARN." >&2
	exit 1
fi

. "${DIR}/hadoop-set-props.sh"
. "${DIR}/spark-set-props.sh"
. "${DIR}/livy-set-props.sh"

exec su livy -c "exec ${LIVY_HOME}/bin/livy-server ${@}"
