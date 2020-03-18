#!/bin/sh

if which wget; then
	wget -qO /dev/null "http://localhost:${LIVY_PORT:-8998}/" || exit 1
elif which curl; then
	curl -LfsSo /dev/null "http://localhost:${LIVY_PORT:-8998}/" || exit 1
else
	echo "Missing wget or curl, cannot perform the health-check." >&2
	exit 0
fi
