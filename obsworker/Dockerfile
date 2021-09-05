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
RUN zypper -n install obs-worker xz

# mount persistent storage
VOLUME ["/var/obsworker/cache"]
VOLUME ["/var/obsworker/run"]

# create runtime directories
RUN mkdir -p /var/obsworker/{cache,run}

# entrypoint
COPY entry.sh /entry.sh
ENTRYPOINT ["/bin/bash", "/entry.sh"]
CMD ["x86_64"]
