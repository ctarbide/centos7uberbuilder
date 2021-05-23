
# docker build --tag centos7uberbuilder .
# docker build --tag centos7uberbuilder --no-cache .

FROM docker.io/centos:7

RUN set -eux; \
    yum install -y ca-certificates epel-release; \
    rpm --query --queryformat "" ca-certificates epel-release

RUN set -eux; \
    INSTALL_PKGS=" \
        GConf2-devel \
        ImageMagick-devel \
        OCE-devel \
        SDL-devel \
        SDL2-devel \
        Xaw3d-devel \
        alsa-lib-devel \
        alsa-plugins-pulseaudio \
        autoconf \
        automake \
        bison \
        bison-devel \
        bison-runtime \
        boost169-devel \
        boost169-static \
        byacc \
        bzip2 \
        bzip2-devel \
        centos-release-scl-rh \
        cppunit-devel \
        curl \
        cvs \
        doxygen \
        ed \
        file \
        fop \
        fuse-devel \
        fuse3-devel \
        gamin-devel \
        giflib-devel \
        git \
        glew-devel \
        glib2-devel \
        glm-devel \
        global \
        gmp-devel \
        gmp-static \
        gnutls-devel \
        gperf \
        gpm-devel \
        graphviz-devel \
        gstreamer-devel \
        gstreamer1-devel \
        gstreamer1-plugins-base-devel \
        gstreamer1-plugins-base-tools \
        gtk2 \
        gtk2-devel \
        gtk2-engines \
        gtk2-engines-devel \
        gtk2-immodule-xim \
        gtk2-immodules \
        gtk3-devel \
        gtkmm24 \
        guile-devel \
        hunspell-devel \
        imlib2-devel \
        intltool \
        jansson-devel \
        java-11-openjdk-devel \
        java-11-openjdk-src \
        kernel-devel \
        lcms2-devel \
        lcms2-utils \
        libXScrnSaver-devel \
        libXft-devel \
        libXinerama-devel \
        libXpm-devel \
        libcurl-devel \
        libev-devel \
        libevent-devel \
        libexif-devel \
        libffi-devel \
        libgeotiff-devel \
        libjpeg-turbo-devel \
        libjpeg-turbo-utils \
        libmspack-devel \
        libnotify-devel \
        libotf-devel \
        libpng-devel \
        libpng12-devel \
        librsvg2-devel \
        libsecret-devel \
        libsqlite3x-devel \
        libtiff-devel \
        libtool \
        libtool-ltdl \
        libtool-ltdl-devel \
        libunistring-devel \
        libvncserver-devel \
        libxkbfile-devel \
        libxml2-devel \
        libxslt-devel \
        libyaml-devel \
        lzip \
        m17n-lib-devel \
        make \
        man-db \
        man-pages \
        mercurial \
        mesa-libEGL-devel \
        mesa-libGLES-devel \
        mesa-libGLU-devel \
        mesa-libGLw-devel \
        mesa-libOSMesa-devel \
        mpg123-devel \
        nasm \
        ncurses-devel \
        nss-devel \
        openjpeg-devel \
        openjpeg2-devel \
        openssh-clients \
        openssl-devel \
        otf2-devel \
        p7zip \
        parted-devel \
        patch \
        perl-core \
        postgresql-devel \
        pulseaudio-libs \
        pulseaudio-libs-devel \
        pulseaudio-libs-glib2 \
        python-devel \
        python-virtualenv \
        python3-devel \
        python36-scons \
        python36-sip \
        python36-virtualenv \
        qt5-qtbase-devel \
        qt5-qttools-devel \
        qt5-qtx11extras-devel \
        readline-devel \
        sbcl \
        sqlite-devel \
        subversion \
        swig3 \
        systemd-devel \
        texinfo \
        turbojpeg-devel \
        unzip \
        vim-common \
        wget \
        which \
        wxGTK-devel \
        wxGTK3-devel \
        xml-common \
        xmlsec1-devel \
        xmlsec1-gcrypt-devel \
        xmlsec1-gnutls-devel \
        xmlsec1-nss-devel \
        xmlsec1-openssl-devel \
        xmlto \
        xmltoman \
        xz \
        yasm \
        zlib-devel \
    "; \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS; \
    rpm --query --queryformat "" $INSTALL_PKGS

RUN set -eux; \
    INSTALL_PKGS=" \
        rh-git218-git-all \
        devtoolset-8 \
        devtoolset-9 \
        llvm-toolset-7.0-clang \
        llvm-toolset-7.0-clang-devel \
        llvm-toolset-7.0-clang-tools-extra \
        llvm-toolset-7.0-clang-analyzer \
    "; \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS; \
    rpm --query --queryformat "" $INSTALL_PKGS

RUN set -eux; \
    INSTALL_PKGS=" \
        cmake3 \
    "; \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS; \
    rpm --query --queryformat "" $INSTALL_PKGS; \
    alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 20 \
        --slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
        --slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
        --slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
        --family cmake

RUN set -eux; \
    INSTALL_PKGS=" \
        texinfo texinfo-tex texlive-collection-fontsrecommended texlive-collection-latexrecommended \
        texlive-txfonts texlive-pxfonts texlive-latex-fonts texlive-amsfonts texlive-ae \
        texlive-charter texlive-lm texlive-lm-math texlive-metafont \
    "; \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS; \
    rpm --query --queryformat "" $INSTALL_PKGS

# yum check-update || true
# yum makecache

# RUN set -eux; \
#     JAVA_11="$(alternatives --display java | grep 'family java-11-openjdk' | cut -d' ' -f1)"; \
#     alternatives --set java "${JAVA_11}"

RUN set -eux; \
    yum clean all -y || true
