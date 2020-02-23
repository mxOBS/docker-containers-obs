#
# Open Build Service Configuration
#

package BSConfig;

# allow access to backend services from anywhere
# TODO: list hosts ex[licitly
our $ipaccess = {
	'.*' => 'rw,worker',
};

# declare hosts of individual backend services
our $srcserver = "http://sourceserver:5352";
our $reposerver = "http://repositoryserver:5252";
our $serviceserver = "http://service:5152";
#our $clouduploadserver = "http://$hostname:5452"; 
our $container_registries = {};
our $publish_containers = [];

# general settings
our $bsdir = '/srv/obs';
our $bsuser = 'obsrun';
our $bsgroup = 'obsrun';
our $rundir = "$bsdir/run";
our $logdir = "$bsdir/log";
our $packtrack = [];
our $nosharedtrees = 2;

# sign settings
our $sign = '/usr/bin/sign';
our $sign_project = 0;
our $gpg_standard_key = "/etc/obs-default-gpg.asc";
our $keyfile = "/srv/obs/obs-default-gpg.asc";
our $forceprojectkeys = 1;

# settings for source service service
our $servicedir = "/usr/lib/obs/service/";
our $bsserviceuser = 'obsservicerun';
our $bsservicegroup = 'obsrun';
our $servicedispatch = 1;

1;
