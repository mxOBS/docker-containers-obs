#!/bin/bash

# runtime configuration
: ${OBS_REPO_SERVER:=repositoryserver:5252}
: ${OBS_SRC_SERVER:=sourceserver:5352}
: ${OBS_WORKER_HOSTLABELS:=}
: ${OBS_WORKER_ID:=$HOSTNAME:0}
: ${OBS_WORKER_JOBS:=1}
: ${OBS_WORKER_PORT:=1600}
: ${OBS_CACHE_SIZE:=0}

# build-time configuration
workerdir=/var/obsworker/run
cachedir=/var/obsworker/cache

# create runtime directories
mkdir -p $workerdir/{boot,root} $cachedir

# fetch current worker code
fetch_code() {
	echo "Fetching initial worker code from $OBS_REPO_SERVER"
	pushd $workerdir/boot > /dev/null
	curl -s "http://$OBS_REPO_SERVER/getworkercode" | cpio --quiet --extract
	if [ $? -ne 0 ]; then
		echo "Failed to fetch worker code!"
		popd > /dev/null
		return 1
	fi
	ln -s . XML
	chmod 755 bs_worker
	popd > /dev/null
}

# execute the worker
run_worker() {
	# generate argument list
	i=0
	unset ARGS
	declare -a ARGS
	ARGS[$((i++))]="--hardstatus"
	ARGS[$((i++))]="--root $workerdir/root"
	ARGS[$((i++))]="--statedir $workerdir/$I"
	ARGS[$((i++))]="--port $OBS_WORKER_PORT"
	if [ $OBS_CACHE_SIZE -gt 0 ]; then
		ARGS[$((i++))]="--cachedir $cachedir"
		ARGS[$((i++))]="--cachesize $OBS_CACHE_SIZE"
	fi
	ARGS[$((i++))]="--reposerver http://$OBS_REPO_SERVER"
	ARGS[$((i++))]="--srcserver http://$OBS_SRC_SERVER"
	ARGS[$((i++))]="--id $OBS_WORKER_ID"
	for label in $OBS_WORKER_HOSTLABELS; do
		ARGS[$((i++))]="--hostlabel $label"
	done
	ARGS[$((i++))]="--jobs $OBS_WORKER_JOBS"

	pushd $workerdir/boot > /dev/null
	echo "Running ./bs_worker ${ARGS[*]}"
	./bs_worker ${ARGS[*]}
	s=$?
	popd

	return $?
}

i=0
while ! fetch_code; do
	if [ $((i++)) -lt 10 ]; then
		echo "Retrying in 10 seconds"
		sleep 10
	else
		echo "Giving up"
		exit 1
	fi
done

run_worker
exit $?
