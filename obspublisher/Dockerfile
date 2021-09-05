FROM opensuse/leap:15.3

# rpm uses curl to import repository keys .........
RUN zypper -n install curl

# add repos
RUN \
	zypper -n ar -f http://download.opensuse.org/repositories/OBS:/Server:/2.10/15.3 obs-2.10 && \
	rpm --import http://download.opensuse.org/repositories/OBS:/Server:/2.10/15.3/repodata/repomd.xml.key && \
	zypper -n ar -f http://download.opensuse.org/repositories/home:/mayerjosua:/OBS/15.3/ obs-2.10-arm-addon && \ 
	rpm --import http://download.opensuse.org/repositories/home:/mayerjosua:/OBS/15.3/repodata/repomd.xml.key && \
	:

# create system users here *before* zypper to enforce static uid and gid
RUN set -e; \
	groupadd -r -g 482 obsrun; \
	useradd -r -g 482 -u 480 -d /usr/lib/obs -s /sbin/nologin -c 'User for the build service source service' obsservicerun; \
	useradd -r -g 482 -u 482 -d /usr/lib/obs -s /sbin/nologin -c 'User for build service backend' obsrun; \
	:

# install packages
RUN zypper -n install obs-server
RUN zypper -n install dpkg gzip obs-signd
COPY sign.conf /etc/

RUN zypper -n install patch
COPY debug-flock.patch /
RUN patch -p0 < debug-flock.patch

# mount persistent storage
VOLUME ["/srv/obs"]

# create runtime directories
RUN mkdir -p /srv/obs

# entrypoint
ENTRYPOINT ["/usr/lib/obs/server/bs_publish"]
CMD ["--logfile", "/srv/obs/log/publisher.log"]
