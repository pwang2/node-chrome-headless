FROM buildpack-deps:stretch-curl

ARG user=jenkins
ARG uid=1003
ARG group=jenkins
ARG gid=1003

ENV CI_USER_HOME                 /home/jenkins
ENV ARCH                         x64
ENV NODE_VERSION                 6.11.2
ENV NPM_CONFIG_LOGLEVEL          info
ENV YARN_VERSION                 0.27.5
ENV JAVA_DEBIAN_VERSION          8u141-b15-1~deb9u1
ENV CA_CERTIFICATES_JAVA_VERSION 20170531+nmu1
ENV CHROMEDRIVER_FILEPATH        /usr/share/chromedriver_linux64.zip
ENV CHROME_BIN                   /usr/bin/google-chrome

RUN if [ ! -d /usr/share/man/man1 ]; then \
      mkdir -p /usr/share/man/man1; \
    fi;

RUN for key in 9554F04D7259F04124DE6B476D5A82AC7E37093B \
               94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
               FD3A5288F042B6850C66B31F09FE44734EB7990E \
               71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
               DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
               B9AE9905FFD7803F25714661B63B535A4C206CA9 \
               C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
               56730D5401028683275BD23C23EFEFE93C4CFFFE \
               6A010C5166006599AA17F08146C2130DFD2497F5;\
    do gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key";\
    done

RUN curl -sSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/chrome.list

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            apt-transport-https \
            apt-utils \
            ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
            google-chrome-stable  \
            procps \
            openjdk-8-jre-headless="$JAVA_DEBIAN_VERSION" \
            xz-utils && \

    update-ca-certificates && \
    apt-get clean -qqy && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" && \
    curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" && \
    gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc && \
    grep "node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - && \
    tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt && \

    curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" && \
    curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" && \
    gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz && \
    mkdir -p /opt/yarn && \
    tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 && \
    ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn && \
    ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg && \
    rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz && \

    curl -sSL https://chromedriver.storage.googleapis.com/2.31/chromedriver_linux64.zip -o ${CHROMEDRIVER_FILEPATH}

RUN echo "$(node --version)" && \
    echo "$(yarn --version)" && \
    echo "$(google-chrome --version)" && \
    echo "$(java -version)"

RUN groupadd --gid ${gid} ${group}  && \
    useradd --uid ${uid} --gid ${gid} --home-dir "${CI_USER_HOME}" ${user} && \
    mkdir -p "${CI_USER_HOME}/.config" && \
    chown -R ${user}:${group} "${CI_USER_HOME}"

USER jenkins:jenkins
VOLUME ["/var/run/docker.sock", "/home/jenkins"]
