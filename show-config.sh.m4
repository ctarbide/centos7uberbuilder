changequote(`', `')dnl
dnl
#!/bin/sh

# ./show-config.sh docker.run.root-dir

set -eu #x

thispath=`perl -MCwd=realpath -le'print realpath(\$ARGV[0])' "${0}"`
thisdir=${thispath%/*}

docker_config=DOCKER_RUN_CONFIG

if [ $# -eq 0 ]; then
    exec git config -f "${docker_config}" --get-regexp '.*'
fi

exec git config -f "${docker_config}" "$@"
