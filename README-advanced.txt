# -*- mode:org; coding:utf-8-unix -*-

#+TITLE: centos7uberbuilder advanced usage
#+STARTUP: indent

* create docker-custom-run.pl configuration file


#+begin_src sh
  ./create-config.sh
#+end_src


* show =docker-custom-run.pl= configuration file


#+begin_src sh
  git config -f "`./show-config.sh docker.run.configname`" --get-regexp '.*'
#+end_src


* docker home directory setup


#+begin_src sh
  ./docker-custom-setup.sh
#+end_src


* querying customized environment information


#+begin_src sh
  docker_config=`./show-config.sh docker.run.configname`
  echo root_dir=`git config -f "${docker_config}" docker.run.root-dir`
  echo home_dir=`git config -f "${docker_config}" docker.run.home-dir`
#+end_src


* run examples

#+begin_src sh
  DOCKER_RUN_CONFIG=docker-run_centos7uberbuilder.cfg ./docker-custom-run.pl --rm -it -- /bin/bash -l

  ./run.pl -t -- bash -l

  ./run.pl sh -c '. /opt/rh/devtoolset-8/enable; gcc --version'

  ./run.pl sh -c '. /opt/rh/devtoolset-9/enable; gcc --version'

  ./run.pl sh -c '. /opt/rh/rh-git218/enable; git --version'

  ./run-devtoolset-8.sh gcc --version

  ./run-devtoolset-9.sh gcc --version

  ./run-devtoolset-9.sh git --version

  ./run-llvm-toolset-7.sh clang --version
#+end_src


* using init?


#+begin_src sh
  ./run.pl sh -c 'exec echo $$'
  ./run.pl sh -c 'ps axf'
#+end_src

