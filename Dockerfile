FROM ubuntu:16.04

MAINTAINER Lialosiu <lialosiu@gmail.com>

WORKDIR /

ENV SS_PORT        8388
ENV SS_PASSWORD    password
ENV SS_METHOD      chacha20-ietf-poly1305
ENV SS_TIMEOUT     300
ENV SS_DNS_ADDR    8.8.8.8
ENV SS_DNS_ADDR_2  8.8.4.4

ENV KCPTUN_VERSION     20170525
ENV KCPTUN_URL         https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz
ENV KCPTUN_PORT        8389
ENV KCPTUN_CRYPT       none
ENV KCPTUN_MTU         1200
ENV KCPTUN_MODE        normal
ENV KCPTUN_DSCP        46
ENV KCPTUN_DATASHARD   10
ENV KCPTUN_PARITYSHARD 3

RUN apt-get update
RUN apt-get install -y --force-yes --no-install-recommends \
    software-properties-common \ 
    nano \
    wget \
    tar
RUN add-apt-repository ppa:max-c-lv/shadowsocks-libev
RUN apt-get update
RUN apt-get install -y --force-yes shadowsocks-libev

RUN wget $KCPTUN_URL
RUN tar zxfv kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

USER nobody

EXPOSE $SS_PORT/tcp $SS_PORT/udp $KCPTUN_PORT/udp

CMD ./server_linux_amd64 \
        -l :$KCPTUN_PORT \
        -t 127.0.0.1:$SS_PORT \
        --crypt $KCPTUN_CRYPT \
        --mtu $KCPTUN_MTU \
        --mode $KCPTUN_MODE \
        --dscp $KCPTUN_DSCP \
        --datashard $KCPTUN_DATASHARD \
        --parityshard $KCPTUN_PARITYSHARD \
        --nocomp \
    & ss-server \
        -s 0.0.0.0 \
        -p $SS_PORT \
        -k $SS_PASSWORD \
        -m $SS_METHOD \
        -t $SS_TIMEOUT \
        -d $SS_DNS_ADDR \
        -d $SS_DNS_ADDR_2 \
        -u \
        -v \
        --fast-open