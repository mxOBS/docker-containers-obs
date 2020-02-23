#!/bin/bash

# create run-time directories
mkdir -p $OBS_BASE_DIR/sources

# setup linked containers
# mysql
# (expected to be linked with alias MYSQL)
mycnf=/etc/my.cnf.d/mysql-container.cnf
rm -f $mycnf
nslookup database
if [ $? -ne 0 ]; then
	echo "ERROR: mysql not in network!"
	exit 1
fi

if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
	echo "ERROR: MySQL root password not set!"
	exit 1
fi

# update my.cnf from environment
printf "[client]\n" >> $mycnf
printf "host = %s\n" database >> $mycnf
printf "port = %s\n" 3306 >> $mycnf
printf "user = root\n" >> $mycnf
printf "password = %s\n" $MYSQL_ROOT_PASSWORD >> $mycnf

# generate database.yml from environment
dbyml=/srv/www/obs/api/config/database.yml
rm -f $dbyml
printf "production:\n" >> $dbyml
printf "  adapter:\t%s\n" "mysql2" >> $dbyml
printf "  host:\t\t%s\n" database >> $dbyml
printf "  port:\t\t%s\n" 3306 >> $dbyml
printf "  username:\t%s\n" "root" >> $dbyml
printf "  password:\t%s\n" "$MYSQL_ROOT_PASSWORD" >> $dbyml
printf "  database:\t%s\n" "api_production" >> $dbyml
printf "  encoding:\t%s\n" "utf8" >> $dbyml

# find source-server in network
srcsrv=$(dig +short srcsrv | tail -1)
if [ $? -ne 0 ]; then
	echo "ERROR: Source-server not in network!"
	exit 1
fi
OBS_SRC_SERVER="$srcsrv:5352"

# find repository-server in network
repsrv=$(dig +short repsrv | tail -1)
if [ $? -ne 0 ]; then
	echo "ERROR: Repository-server not in network!"
	exit 1
fi
OBS_REPO_SERVERS="$repsrv:5252"
# TODO: how to accept multiple repo servers?

# generate options.yml from environment
optyml=/srv/www/obs/api/config/options.yml
rm -f $optyml
printf "source_host: %s\n" srcsrv >> $optyml
printf "source_port: %s\n" 5352 >> $optyml

# update /etc/sysconfig/obs-server from environment
sysconfig=/etc/sysconfig/obs-server
vars="$(grep -E "^[^#].+=" $sysconfig | cut -d= -f1)"
for var in OBS_SRC_SERVER OBS_REPO_SERVERS; do
	if [ -n "$var" ]; then
		val=${!var}
		orig="^$var=.*\$"
		new="$var=\"$val\""
		regex="s;$orig;$new;g"
		sed -i $regex $sysconfig
	fi
done

# source setup-appliance script provided by obs
# make sure to only fetch the functions (stop after # MAIN)
setupappliance=/usr/lib/obs/server/setup-appliance.sh
grep -e "^# MAIN$" $setupappliance >/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to find marker in $setupappliance!"
	exit 1
fi
n=0
while read -r line; do
	[ "$line" = "# MAIN" ] && break
	((n=n+1))
done < $setupappliance
t=$(mktemp)
head -$n $setupappliance > $t
source $t
rm -f $t

# set variables required by script
apidir=$OBS_API_ROOT
backenddir=$OBS_BASE_DIR
NON_INTERACTIVE=1

# copypaste from setup-appliance.sh those parts that apply here

# wait for MySQL to come up (max. 25s)
./wait-for-it.sh database:3306 -t 25
if [ $? -ne 0 ]; then
	echo "ERROR: SQL Server isn't up!"
	exit 1
fi

# test mysql connection
mysqladmin version >/dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: Can't connect to sql server"
	exit 1
fi

# initialize or migrate database
pushd $OBS_API_ROOT
RAILS_ENV=production bundle exec rake.ruby2.5 db:migrate:status 2>/dev/null
if [ $? -ne 0 ]; then
	# create and initialize
	RAKE_COMMANDS="db:create db:setup writeconfiguration"
else
	# migrate db
	RAKE_COMMANDS="db:migrate"
fi

# execute rake queue
for cmd in $RAKE_COMMANDS; do
	RAILS_ENV=production bundle exec rake.ruby2.5 $cmd 2>&1 >> log/db_migrate.log
	if [ $? -ne 0 ];then
		echo "ERROR: $cmd failed"
		exit 1
	fi
done
popd

# configure apache
MODULES="passenger rewrite proxy proxy_http xforward headers socache_shmcb"
for mod in $MODULES; do
	a2enmod -q $mod || a2enmod $mod
done

FLAGS=SSL
for flag in $FLAGS;do
	a2enflag $flag
done

get_hostname

### In case of the appliance, we never know where we boot up !
OLDFQHOSTNAME="NOTHING"
if [ -e $backenddir/.oldfqhostname ]; then
	OLDFQHOSTNAME=`cat $backenddir/.oldfqhostname`
fi

DETECTED_HOSTNAME_CHANGE=0

if [ "$FQHOSTNAME" != "$OLDFQHOSTNAME" ]; then
	echo "Appliance hostname changed from $OLDFQHOSTNAME to $FQHOSTNAME !"
	DETECTED_HOSTNAME_CHANGE=1
fi

if [[ $DETECTED_HOSTNAME_CHANGE == 1 ]];then
	# TODO make it use actual source and repo server variables
	#adapt_worker_jobs
	adjust_api_config
fi

check_server_key
generate_proposed_dnsnames
check_server_cert
import_ca_cert
relink_server_cert
