# -*- mode:org; coding:utf-8-unix -*-

#+TITLE: centos7uberbuilder
#+STARTUP: indent

* About


A docker image and some associated scripts intended to build basically
anything recent that targets CentOS 7, thanks to
https://www.softwarecollections.org/en/.

The generated image is huge, around 4.56GB, and take about 2 hours to
complete, but the Dockerfile has various checkpoints.

Too bad CentOS is dying, I am finally, slowly and gradually migrating
my systems to Debian, but this may still be useful for someone, for
some time.


* Build Docker Image


#+begin_src sh
  docker build --tag centos7uberbuilder .
#+end_src


* Test Docker Image


#+begin_src sh
  docker run --rm -it --entrypoint /bin/bash centos7uberbuilder -l

  docker run --rm -it --init centos7uberbuilder /bin/sh -e -c '. /opt/rh/devtoolset-8/enable; exec gcc --version'
  # gcc (GCC) 8.3.1 20190311 (Red Hat 8.3.1-3)

  docker run --rm -it --init centos7uberbuilder /bin/sh -e -c '. /opt/rh/devtoolset-9/enable; . /opt/rh/rh-git218/enable; gcc --version; git --version'
  # gcc (GCC) 9.3.1 20200408 (Red Hat 9.3.1-2)
  # git version 2.18.4

  docker run --rm -it --init centos7uberbuilder /bin/sh -e -c '. /opt/rh/llvm-toolset-7.0/enable; . /opt/rh/rh-git218/enable; clang --version; git --version'
  # clang version 7.0.1 (tags/RELEASE_701/final)
  # git version 2.18.4

  docker run --rm -it --init centos7uberbuilder cmake --version
  # cmake3 version 3.17.5

  docker run --rm -it --init centos7uberbuilder /bin/sh -e -c '. /opt/rh/devtoolset-9/enable; . /opt/rh/rh-git218/enable; exec /bin/bash -l'
#+end_src

