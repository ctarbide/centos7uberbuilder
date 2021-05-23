#!/bin/sh

set -eu #x

die(){ ev=$1; shift; for msg in "$@"; do echo "${msg}"; done; exit "${ev}"; }

thispath=`perl -MCwd=realpath -le'print(realpath(\$ARGV[0]))' -- "${0}"`
thisdir=${thispath%/*}

DOCKER_NETWORK_ARG=host
export DOCKER_NETWORK_ARG

setup_script='. /opt/rh/rh-git218/enable; . /opt/rh/devtoolset-9/enable; exec "$@"'

sep_char=`printf '\035'` # \035 is GS, quasi-arbitrarily chosen, see
                         # 'man ascii'

args0=
while [ "$#" -gt 0 -a x"${1:-}" != x-- ]; do
    args0=${args0}${sep_char}${1}
    shift
done
args0=${args0#${sep_char}}

if [ x"${1:-}" = x-- ]; then
    shift # shift '--'
    if [ "$#" -gt 0 ]; then
        # has docker and container args
        oldIFS=${IFS}; IFS=${sep_char}
        set -- ${args0} '--' /bin/sh -c "${setup_script}" inline-script "$@"
        IFS=${oldIFS}
    else
        # has only docker args
        oldIFS=${IFS}; IFS=${sep_char}
        set -- ${args0} '--'
        IFS=${oldIFS}
    fi
elif [ x"${args0}" != x ]; then
    # has only container args
    oldIFS=${IFS}; IFS=${sep_char}
    set -- /bin/sh -c "${setup_script}" inline-script ${args0}
    IFS=${oldIFS}
else
    # has no args
    die 1 "usage example: ${0} -t -- /bin/sh"
fi

exec "${thisdir}/run.pl" "$@"
