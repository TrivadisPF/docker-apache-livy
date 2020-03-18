#!/bin/sh

. $(dirname "${0}")/set-pax-flag-of-java.sh

# the functions require GNU sed (the usage of busybox sed may result into incorrect outputs)

addLivyProperty() {
	local path="${1}"
	local name="${2}"
	local value="${3}"
	local entry="${name}=${value}"
	local escapedEntry=$(echo "${entry}" | sed -e 's/\//\\\//g' -e 's/\./\\./g')
	if grep -q "^${escapedEntry%%=*}="; then
		sed -i "s/^${escapedEntry%%=*}=.*\$/${escapedEntry}/g" "${path}"
	else
		echo "${entry}" >> "${path}"
	fi
}

reconfLivyByEnvVars() {
	local path="${1}"
	local envPrefix="${2}"
	echo "* reconfiguring ${path}"
	echo >> "${path}" # fix missing LF at the end of the file
	for I in `printenv | grep "^${envPrefix}_[^=]*="`; do
		local name=`echo "${I}" | sed -e "s/^${envPrefix}_\\([^=]*\\)=.*\$/\\1/" -e 's/___/-/g' -e 's/__/_/g' -e 's/_/./g'`
		local value="${I#*=}"
		echo "** setting ${name}=${value}"
		addLivyProperty "${path}" "${name}" "${value}"
	done
}

reconfLivyByEnvVars "${LIVY_DEF_CONF}" PROP_LIVY
