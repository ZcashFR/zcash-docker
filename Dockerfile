FROM debian:stretch as debian
MAINTAINER LeBleu :: ZcashFR.io

ENV     ZCASH_URL=https://github.com/zcash/zcash.git \
        ZCASH_VERSION=v2.0.1 \
        ZCASH_CONF=/home/zcash/.zcash/zcash.conf


RUN apt-get update && apt-get -y install \
    build-essential pkg-config libc6-dev m4 g++-multilib \
    autoconf libtool ncurses-dev unzip git python python-zmq \
    zlib1g-dev wget curl bsdmainutils automake &&\
    mkdir -p /src/zcash/; cd /src/zcash; \
    git clone ${ZCASH_URL} zcash && cd zcash && git checkout ${ZCASH_VERSION} && \
    ./zcutil/build.sh -j$(nproc) && \
    echo "Success"

FROM debian:stretch-slim

ENV ZCASH_CONF=/home/zcash/.zcash/zcash.conf

RUN useradd -ms /bin/bash zcash && \
    apt-get update && apt-get -y install wget libgomp1 && apt-get clean all && \
    mkdir -p /home/zcash/.zcash; \
    echo 'Write zcash.conf'; \
    echo 'addnode=mainnet.z.cash' > ${ZCASH_CONF} && \
    echo 'addnode=mainnet.zcashfr.io' >> ${ZCASH_CONF} && \
    echo 'showmetrics=0' >> ${ZCASH_CONF} && \
    echo 'Write launch-zcashd.sh'; \
    echo "#!/bin/bash" > "/usr/local/bin/launch-zcashd.sh" && \
    echo "/usr/local/bin/fetch-params.sh && /usr/local/bin/zcashd" >> "/usr/local/bin/launch-zcashd.sh" && \
    chmod +x /usr/local/bin/launch-zcashd.sh; \
    chown -R zcash:zcash /home/zcash; \
    echo "Success"

COPY --from=debian /src/zcash/zcash/src/zcash-cli /usr/local/bin/zcash-cli
COPY --from=debian /src/zcash/zcash/src/zcashd /usr/local/bin/zcashd
COPY --from=debian /src/zcash/zcash/src/zcash-gtest /usr/local/bin/zcash-gtest
COPY --from=debian /src/zcash/zcash/src/zcash-tx /usr/local/bin/zcash-tx
COPY --from=debian /src/zcash/zcash/zcutil/fetch-params.sh /usr/local/bin/fetch-params.sh

USER zcash

ENTRYPOINT ["/bin/bash", "/usr/local/bin/launch-zcashd.sh"]

EXPOSE 8233/tcp

WORKDIR ["/home/zcash"]
VOLUME ["/home/zcash"]
