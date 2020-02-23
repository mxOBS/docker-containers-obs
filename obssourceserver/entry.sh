#!/bin/bash

/usr/lib/obs/server/bs_srcserver 2>&1 | tee /srv/obs/log/src_server.log
exit $?
