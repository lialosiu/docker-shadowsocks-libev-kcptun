FROM alpine:3.6

MAINTAINER Lialosiu <lialosiu@gmail.com>

WORKDIR /

ARG SS_VER=3.1.0
ARG SS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${SS_VER}/shadowsocks-libev-${SS_VER}.tar.gz
ARG KCPTUN_VER=20170930
ARG KCPTUN_URL=https://github.com/xtaci/kcptun/releases/download/v${KCPTUN_VER}/kcptun-linux-amd64-${KCPTUN_VER}.tar.gz
ARG OBFS_VER=0.0.3
ARG OBFS_URL=https://github.com/shadowsocks/simple-obfs.git
ARG TZ='Asia/Shanghai'

ENV SS_LISTEN      127.0.0.1
ENV SS_PORT        8388
ENV SS_PASSWORD    password
ENV SS_METHOD      chacha20-ietf-poly1305
ENV SS_TIMEOUT     300
ENV SS_DNS_ADDR    8.8.8.8
ENV SS_DNS_ADDR_2  8.8.4.4

ENV KCPTUN_LISTEN       127.0.0.1
ENV KCPTUN_PORT         8389
ENV KCPTUN_CRYPT        none
ENV KCPTUN_MTU          1200
ENV KCPTUN_MODE         normal
ENV KCPTUN_DSCP         46
ENV KCPTUN_DATASHARD    10
ENV KCPTUN_PARITYSHARD  3

ENV OBFS_LISTEN    127.0.0.1
ENV OBFS_PORT      8390
ENV OBFS_TYPE      http
ENV OBFS_FAILOVER  127.0.0.1:80

RUN set -ex && \
    apk add --no-cache --virtual .build-deps \
                                autoconf \
                                automake \
                                asciidoc \
                                build-base \
                                c-ares-dev \
                                curl \
                                libev-dev \
                                libtool \
                                linux-headers \
                                xmlto \
                                libsodium-dev \
                                mbedtls-dev \
                                pcre-dev \
                                udns-dev \
                                tar \
                                git && \
    cd /tmp && \
    curl -sSL $SS_URL | tar xz --strip 1 && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    rm -rf /tmp/* && \
    curl -sSL $KCPTUN_URL | tar xz && \
    mv ./server_linux_amd64 /usr/bin/kcptunserver && \
    mv ./client_linux_amd64 /usr/bin/kcptunclient && \
    rm -rf /tmp/* && \
    git clone $OBFS_URL && \
    cd simple-obfs && \
    git checkout v$OBFS_VER && \
    git submodule update --init --recursive && \
    ./autogen.sh && ./configure && \
    make && make install && \
    rm -rf /tmp/* && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* /usr/local/bin/obfs-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \
    apk del .build-deps && \
    rm -rf /tmp/* /var/cache/apk/*

USER nobody

EXPOSE $SS_PORT/tcp $SS_PORT/udp $KCPTUN_PORT/udp

CMD kcptunserver \
        -l $KCPTUN_LISTEN:$KCPTUN_PORT \
        -t $SS_LISTEN:$SS_PORT \
        --crypt $KCPTUN_CRYPT \
        --mtu $KCPTUN_MTU \
        --mode $KCPTUN_MODE \
        --dscp $KCPTUN_DSCP \
        --datashard $KCPTUN_DATASHARD \
        --parityshard $KCPTUN_PARITYSHARD \
        --nocomp & \
    ss-server \
        -s $SS_LISTEN \
        -p $SS_PORT \
        -k $SS_PASSWORD \
        -m $SS_METHOD \
        -t $SS_TIMEOUT \
        -d $SS_DNS_ADDR \
        -d $SS_DNS_ADDR_2 \
        -u \
        -v \
        --fast-open & \
    obfs-server \
        -s $OBFS_LISTEN \
        -p $OBFS_PORT \
        --obfs $OBFS_TYPE \
        --failover $OBFS_FAILOVER \
        --fast-open \
        -r $SS_LISTEN:$SS_PORT \
        -v
