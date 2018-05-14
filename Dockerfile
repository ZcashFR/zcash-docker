FROM debian:stretch as debian
MAINTAINER Fabrice

ENV     ZCASH_URL=https://github.com/zcash/zcash.git \
        ZCASH_VERSION=v1.1.0 \
        ZCASH_CONF=/home/zcash/.zcash/zcash.conf


RUN apt-get update && apt-get -y install \
    build-essential pkg-config libc6-dev m4 g++-multilib \
    autoconf libtool ncurses-dev unzip git python python-zmq \
    zlib1g-dev wget curl bsdmainutils automake &&\
    mkdir -p /src/zcash/; cd /src/zcash; \
    git clone ${ZCASH_URL} zcash && cd zcash && git checkout ${ZCASH_VERSION} && \
    ./zcutil/build.sh -j4 && \
    echo "Success"

FROM debian:stretch

ENV ZCASH_CONF=/root/.zcash/zcash.conf \
    ZCASH_USER=zcash \
    ZCASH_PASSWORD="tIclKil6GRzwqkoigLgneU9StZH4HWgnRYDQBPRIwOY=" \
    ZCASH_GEN=0

RUN apt-get update && apt-get -y install wget libgomp1 && apt-get clean all && \
    mkdir -p /root/.zcash; mkdir -p /zcash/zcutil;\
    echo "addnode=mainnet.z.cash" > ${ZCASH_CONF} && \
    echo "addnode=mainnet.zcashfr.io" >> ${ZCASH_CONF} && \
    echo "rpcuser=$ZCASH_USER" >> ${ZCASH_CONF} && \
    echo "rpcpassword=$ZCASH_PASSWORD" >> ${ZCASH_CONF} && \
    echo "gen=$ZCASH_GEN" >> ${ZCASH_CONF} && \
    echo "genproclimit=$(nproc)" >> ${ZCASH_CONF} && \
    echo "equihashsolver=tromp" >> ${ZCASH_CONF} && \
    echo "#!/bin/bash" > "/zcash/zcutil/launch-zcashd.sh" && \
    echo "/zcash/zcutil/fetch-params.sh && /zcash/src/zcashd" >> "/zcash/zcutil/launch-zcashd.sh" && \
    chmod +x /zcash/zcutil/launch-zcashd.sh; \
    echo "Success"
    

COPY --from=debian /src/zcash/zcash/src/zcash-cli /zcash/src/zcash-cli
COPY --from=debian /src/zcash/zcash/src/zcashd /zcash/src/zcashd
COPY --from=debian /src/zcash/zcash/src/zcash-gtest /zcash/src/zcash-gtest
COPY --from=debian /src/zcash/zcash/src/zcash-tx /zcash/src/zcash-tx
COPY --from=debian /src/zcash/zcash/zcutil/fetch-params.sh /zcash/zcutil/fetch-params.sh

ENTRYPOINT ["/bin/bash", "/zcash/zcutil/launch-zcashd.sh"]

WORKDIR ["/zcash/src"]
VOLUME ["/root"]
