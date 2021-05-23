#!/bin/sh

set -eux

die(){ ev=$1; shift; for msg in "$@"; do echo "${msg}"; done; exit "${ev}"; }

strip_r_slash(){ echo "${1}" | perl -pe's,/*$,,'; }

docker_config=${1:-`./show-config.sh docker.run.configname`}

test -f "${docker_config}" || die 1 "error: ${docker_config} does not exist"

set +e

root_dir=`git config -f "${docker_config}" docker.run.root-dir`
home_dir=`git config -f "${docker_config}" docker.run.home-dir`
imagename=`git config -f "${docker_config}" docker.run.imagename`
customize_script=`git config -f "${docker_config}" docker.run.setup-script`

username=`git config -f "${docker_config}" docker.run.username`
groupname=`git config -f "${docker_config}" docker.run.groupname`
uid=`git config -f "${docker_config}" docker.run.uid`
gid=`git config -f "${docker_config}" docker.run.gid`

set -e

if [ "x${customize_script}" != 'x' ]; then
    customize_script=`perl -MCwd=realpath -le'print(realpath(\$ARGV[0]))' -- "${customize_script}"`
    customize_target=/customize-before-export.sh
else
    customize_script=`which true`
    customize_target=/customize-before-export_noop.sh
fi

test "x${root_dir}" != x || die 1 "error: docker.run.root-dir configuration is required"
test "x${home_dir}" != x || die 1 "error: docker.run.home-dir configuration is required"
test "x${imagename}" != x || die 1 "error: docker.run.imagename configuration is required"
test "x${username}" != x || die 1 "error: docker.run.username configuration is required"
test "x${groupname}" != x || die 1 "error: docker.run.groupname configuration is required"

perl -le'exit($ARGV[0] !~ m{^/})' -- "${home_dir}" || die 1 "error: docker.run.home-dir configuration must be an absolute path"
perl -le'exit($ARGV[0] !~ m{^\d+$})' -- "${uid}" || die 1 "error: docker.run.uid must be numeric"
perl -le'exit($ARGV[0] !~ m{^\d+$})' -- "${gid}" || die 1 "error: docker.run.gid must be numeric"
perl -le'exit($ARGV[0] !~ m{^[a-z]\w+$}i)' -- "${username}" || die 1 "error: invalid docker.run.username: [${username}]"
perl -le'exit($ARGV[0] !~ m{^[a-z]\w+$}i)' -- "${groupname}" || die 1 "error: invalid docker.run.groupname: [${groupname}]"

root_dir=`strip_r_slash "${root_dir}"`
home_dir=`strip_r_slash "${home_dir}"`

mkdir -p "${root_dir}"

docker run --rm -a stdout -a stderr -i \
    -e USERNAME="${username}" -e GROUPNAME="${groupname}" \
    -e USER_ID="${uid}" -e GROUP_ID="${gid}" \
    -v "${customize_script}:${customize_target}:ro" \
    "${imagename}" /bin/sh -eu -c '
test -x /customize-before-export.sh && /customize-before-export.sh 1>&2
tar -C / -cf - etc' | tar -C "${root_dir}" -xf -

set -x

ls -alhF --color "${root_dir}"

du -shc "${root_dir}"/*

echo all done
