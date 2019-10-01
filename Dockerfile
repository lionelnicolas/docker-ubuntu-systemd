FROM ubuntu:bionic-20190912.1 as final

ENV \
	DEBIAN_FRONTEND=noninteractive \
	LANG=C.UTF-8 \
	container=docker \
	init=/lib/systemd/systemd

# install systemd packages
RUN \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse"           >/etc/apt/sources.list && \
	echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" >>/etc/apt/sources.list && \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse"  >>/etc/apt/sources.list && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		systemd \
		&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists

# configure systemd
RUN \
# remove systemd 'wants' triggers
	find \
		/etc/systemd/system/*.wants/* \
		/lib/systemd/system/multi-user.target.wants/* \
		/lib/systemd/system/local-fs.target.wants/* \
		/lib/systemd/system/sockets.target.wants/*initctl* \
		! -type d \
		-delete && \
# remove everything except tmpfiles setup in sysinit target
	find \
		/lib/systemd/system/sysinit.target.wants \
		! -type d \
		! -name '*systemd-tmpfiles-setup*' \
		-delete && \
# remove UTMP updater service
	find \
		/lib/systemd \
		-name systemd-update-utmp-runlevel.service \
		-delete && \
# disable /tmp mount
	rm -vf /usr/share/systemd/tmp.mount && \
# fix missing BPF firewall support warning
	sed -ri '/^IPAddressDeny/d' /lib/systemd/system/systemd-journald.service && \
# just for cosmetics, fix "not-found" entries while using "systemctl --all"
	for MATCH in \
		plymouth-start.service \
		plymouth-quit-wait.service \
		syslog.socket \
		syslog.service \
		display-manager.service \
		systemd-sysusers.service \
		tmp.mount \
		systemd-udevd.service \
		; do \
			grep -rn --binary-files=without-match  ${MATCH} /lib/systemd/ | cut -d: -f1 | xargs sed -ri 's/(.*=.*)'${MATCH}'(.*)/\1\2/'; \
	done && \
	systemctl disable ondemand.service && \
	systemctl set-default multi-user.target

ENTRYPOINT ["/lib/systemd/systemd"]
