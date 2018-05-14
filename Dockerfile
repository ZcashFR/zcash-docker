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

FROM alpine:latest

ENV ZCASH_CONF=/root/.zcash/zcash.conf

RUN apk --no-cache add wget bash && \
    mkdir -p /root/.zcash; \
    echo "rpcuser=zcash" > ${ZCASH_CONF} && \
    echo "addnode=mainnet.z.cash" >> ${ZCASH_CONF} && \
    echo "addnode=mainnet.zcashfr.io" >> ${ZCASH_CONF} && \
    echo "Success"

COPY --from=debian /src/zcash/zcash/src/zcash-cli /zcash/src/zcash-cli
COPY --from=debian /src/zcash/zcash/src/zcashd /zcash/src/zcashd
COPY --from=debian /src/zcash/zcash/src/zcash-gtest /zcash/src/zcash-gtest
COPY --from=debian /src/zcash/zcash/src/zcash-tx /zcash/src/zcash-tx
COPY --from=debian /src/zcash/zcash/src/wallet-utility /zcash/src/wallet-utility
COPY --from=debian /src/zcash/zcash/zcutil/fetch-params.sh /zcash/zcutil/fetch-params.sh

ENTRYPOINT ["/zcash/src/zcashd"]

WORKDIR ["/zcash/src"]
VOLUME ["/root" 
