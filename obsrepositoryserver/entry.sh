#!/bin/bash

/usr/lib/obs/server/bs_repserver 2>&1 | tee /srv/obs/log/rep_server.log
exit $?
