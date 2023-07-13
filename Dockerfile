FROM openjdk:17-jdk-alpine3.14
ENV NODE_VERSION=16.14.2
ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG=C.UTF-8
ARG GPG_KEY=E3FF2839C048B25C084DEBE9B26995E310250568
ARG PYTHON_VERSION=3.9.17
ARG PYTHON_PIP_VERSION=23.0.1
ARG PYTHON_SETUPTOOLS_VERSION=58.1.0
ARG PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/0d8570dc44796f4369b652222cf176b3db6ac70e/public/get-pip.py
ARG PYTHON_GET_PIP_SHA256=96461deced5c2a487ddc65207ec5a9cffeca0d34e7af7ea1afc470ff0d746207
ARG MAVEN_VERSION=3.8.8
ARG USER_HOME_DIR=/home/node
ARG SHA=ce50b1c91364cb77efe3776f756a6d92b76d9038b0a0782f7d53acf1e997a14d
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/3.8.8/binaries/
ENV MAVEN_HOME=/usr/share/maven
ENV MAVEN_CONFIG=/home/node/.m2
RUN echo "#====================Add Node===================#" && \
    addgroup -g 1000 node && adduser -u 1000 -G node -s /bin/sh -D node && apk update && \
    apk add --no-cache make libstdc++ git curl ca-certificates tzdata && apk add --upgrade --no-cache --virtual .build-deps bash procps && ARCH= && alpineArch="$(apk --print-arch)" && \
    case "${alpineArch##*-}" in x86_64) ARCH='x64' CHECKSUM="a6dc255e1ef1f20372306eec932b4a3648575c6d3024bcd685b8efc93dc95569" ;; *) ;; esac && \
    if [ -n "${CHECKSUM}" ]; then set -eu; \
    curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" && \
    #echo "$CHECKSUM node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" | sha256sum -c - && \
    tar -xJf "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" -C /usr/local --strip-components=1 --no-same-owner && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs; else echo "Building from source" && \
    apk add --no-cache --virtual .build-deps-full binutils-gold g++ gcc gnupg libgcc linux-headers make python3 && \
    for key in 4ED778F539E3634C779C87C6D7062848A1AB005C 141F07595B7B3FFE74309A937405533BE57C7D57 94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C DD8F2338BAE7501E3DD5AC78C273792F7D83545D A48C2BEE680E841632CD4E44F07496B3EB3C1762 108F52B48DB57BB0CC439B2997B01419BD92F80A \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C ; \
    do gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; done && \
    curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" && \
    curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc && \
    grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - && tar -xf "node-v$NODE_VERSION.tar.xz" && \
    cd "node-v$NODE_VERSION" && ./configure && make -j$(getconf _NPROCESSORS_ONLN) V= && make install && apk del .build-deps-full && cd .. && \
    rm -Rf "node-v$NODE_VERSION" && rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt; fi && \
    rm -f "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" && apk del .build-deps && node --version && npm --version && \
    echo "#=================Add Maven===============#" && \
    mkdir -p /usr/share/maven /usr/share/maven/ref && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    #echo "${SHA} /tmp/apache-maven.tar.gz" | sha256sum -c - && 
    tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 && rm -f /tmp/apache-maven.tar.gz && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && \
    echo "#=================Add Python===============#" && \
    apk add --no-cache --virtual .build-deps gnupg tar xz bluez-dev bzip2-dev dpkg-dev dpkg expat-dev findutils gcc gdbm-dev libc-dev libffi-dev libnsl-dev libtirpc-dev && \
    linux-headers make ncurses-dev openssl-dev pax-utils readline-dev sqlite-dev tcl-dev tk tk-dev util-linux-dev xz-dev zlib-dev ; \
    wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
    wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc"; \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY"; \
    gpg --batch --verify python.tar.xz.asc python.tar.xz; gpgconf --kill all; rm -rf "$GNUPGHOME" python.tar.xz.asc; mkdir -p /usr/src/python; \
    tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz; rm python.tar.xz; cd /usr/src/python; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure --build="$gnuArch" --enable-loadable-sqlite-extensions --enable-optimizations --enable-option-checking=fatal --enable-shared --with-system-expat \
    --without-ensurepip ; nproc="$(nproc)"; EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000"; LDFLAGS="${LDFLAGS:--Wl},--strip-all"; \
    make -j "$nproc" "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" "LDFLAGS=${LDFLAGS:-}" "PROFILE_TASK=${PROFILE_TASK:-}" ; rm python; \
    make -j "$nproc" "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" "LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" "PROFILE_TASK=${PROFILE_TASK:-}" python ; make install; cd /; \
    rm -rf /usr/src/python; \
    find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \) -exec rm -rf '{}' + ; \
    find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' | xargs -rt apk add --no-network --virtual .python-rundeps ; \
    apk del --no-network .build-deps; python3 --version && \
    for src in idle3 pydoc3 python3 python3-config; do dst="$(echo "$src" | tr -d 3)"; [ -s "/usr/local/bin/$src" ]; [ ! -e "/usr/local/bin/$dst" ]; ln -svT "$src" "/usr/local/bin/$dst"; && \
    wget -O get-pip.py "$PYTHON_GET_PIP_URL"; echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum -c -; export PYTHONDONTWRITEBYTECODE=1; \
    python get-pip.py --disable-pip-version-check --no-cache-dir --no-compile "pip==$PYTHON_PIP_VERSION" "setuptools==$PYTHON_SETUPTOOLS_VERSION" ; \
    rm -f get-pip.py; pip --version
