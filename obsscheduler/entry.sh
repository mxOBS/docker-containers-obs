#!/bin/bash

arch=$1

/usr/lib/obs/server/bs_sched $arch 2>&1 | tee /srv/obs/log/scheduler_$arch.log
exit $?
