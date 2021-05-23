#!/bin/sh

set -eux

groupadd --gid "${GROUP_ID}" "${GROUPNAME}"

# adding supplementary groups to properly test 'getgroups' while
# building daemontools-0.76
adduser --create-home --shell /bin/bash --uid "${USER_ID}" --gid "${GROUP_ID}" --groups users,wheel "${USERNAME}"
