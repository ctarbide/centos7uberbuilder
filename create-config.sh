#!/bin/sh

set -eu #x

die(){ ev=$1; shift; for msg in "$@"; do echo "${msg}"; done; exit "${ev}"; }

which m4 >/dev/null || die 1 "error: program not found: m4"

configname=docker-run_centos7uberbuilder.cfg  # default name is docker-run.cfg

uid=`id -u`
gid=`id -g`

rm -fv "${configname}.tmp"

configure(){ git config -f "${configname}.tmp" "$@"; }

configure docker.run.configname "${configname}"

configure docker.run.username docker
configure docker.run.groupname docker
configure docker.run.home-dir /home/docker

configure docker.run.root-dir "${HOME}/Ephemeral/var/docker-centos7uberbuilder"
configure docker.run.imagename centos7uberbuilder:latest
configure docker.run.setup-script customize-addgroup-and-user-centos7.sh

configure docker.run.uid "`id -u`"
configure docker.run.gid "`id -g`"
configure --add docker.run.exports /etc
configure --add docker.run.exports /home

configure --add docker.run.volumes /tmp/.X11-unix:/tmp/.X11-unix
configure --add docker.run.volumes "/run/user/${uid}/pulse:/run/user/${uid}/pulse"

configure --add docker.run.env-vars "DISPLAY=${DISPLAY}"
configure --add docker.run.env-vars "PULSE_SERVER=/run/user/${uid}/pulse/native"

configure --add docker.run.devices "/dev/snd"

# configure --add docker.run.debug true

## use --init instead
# configure --add docker.run.volumes /usr/libexec/docker/docker-init-current:/bin/docker-init:ro
# configure docker.run.entrypoint /bin/docker-init

rm -f "${configname}"

mv "${configname}.tmp" "${configname}"

m4 -DDOCKER_RUN_CONFIG="${configname}" show-config.sh.m4 > show-config.sh
chmod a+x show-config.sh

echo all done
