FROM alpine:3.12

LABEL maintainer="Ruoge3s <ruoge3s@qq.com>" version="1.0" license="GPL"

WORKDIR /home

RUN set -ex \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache \
    ca-certificates curl wget tar xz libressl tzdata pcre \
    php7 php7-fpm php7-bcmath php7-curl php7-ctype php7-dom php7-fileinfo php7-gd php7-iconv php7-json \
    php7-mbstring php7-mysqlnd php7-openssl php7-pdo php7-pdo_mysql php7-pdo_sqlite php7-phar \
    php7-posix php7-redis php7-simplexml php7-sockets php7-sodium php7-sysvshm php7-sysvmsg \
    php7-sysvsem php7-tokenizer php7-zip php7-zlib php7-xml php7-xmlreader php7-xmlwriter \
    php7-pcntl \
    && apk del --purge *-dev \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/share/php7 \
    && php -v \
    && php -m \
    && echo -e "\033[42;37m Build Completed Step1 :).\033[0m\n"

ARG SWOOLE_VERSION

ENV SWOOLE_VERSION=${SWOOLE_VERSION:-"4.5.2"}

# 安装依赖
RUN set -ex \
    && apk add --no-cache libstdc++ openssl git bash \
    && apk add --no-cache --virtual .build-deps autoconf dpkg-dev dpkg file g++ gcc libc-dev make php7-dev php7-pear pkgconf re2c pcre-dev zlib-dev libtool automake libaio-dev openssl-dev

# 安装swoole扩展
RUN set -ex \
    && cd /tmp \
    && curl -SL "https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz" -o swoole.tar.gz \
    && ls -alh \
    # php extension:swoole
    && cd /tmp \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-mysqlnd --enable-openssl --enable-http2 \
        && make -s -j$(nproc) && make install \
    ) \
    && echo "memory_limit=1G" > /etc/php7/conf.d/00_default.ini \
    && echo "extension=swoole.so" > /etc/php7/conf.d/50_swoole.ini \
    && echo "swoole.use_shortname = 'Off'" >> /etc/php7/conf.d/50_swoole.ini \
    # clear
    && php -v \
    && php -m \
    && php --ri swoole \
    && echo -e "\033[42;37m Build Completed Step2 :).\033[0m\n"

# 安装memcache相关扩展
RUN set -ex \
    && cd /tmp \
    && mkdir -p memcache \
    && curl -SL https://github.com/websupport-sk/pecl-memcache/archive/4.0.4.tar.gz -o memcache.tar.gz \
    && tar -xf memcache.tar.gz -C memcache --strip-components=1 \
    && ( \
        cd memcache \
        && phpize \
        && ./configure --with-php-config=/usr/bin/php-config --disable-memcache-session \
        && make -s -j$(nproc) && make install \
    ) \
    && echo "extension=memcache.so" > /etc/php7/conf.d/50_memcache.ini \
    && echo -e "\033[42;37m Build Completed Step2 :).\033[0m\n"

# 安装rabbitmq相关扩展
RUN set -ex \
    && cd /tmp \
    && mkdir -p rabbitmq-c \
    && curl -SL https://github.com/alanxz/rabbitmq-c/releases/download/v0.8.0/rabbitmq-c-0.8.0.tar.gz -o rabbitmq-c.tar.gz \
    && tar -xf rabbitmq-c.tar.gz -C rabbitmq-c --strip-components=1 \
    && ( \
        cd rabbitmq-c \
        && ./configure --prefix=/usr/local/rabbitmq-c \
        && make -s -j$(nproc) && make install \
    ) \
    # 安装amqp
    && cd /tmp \
    && mkdir -p rabbitmq \
    && curl -SL https://github.com/php-amqp/php-amqp/archive/v1.10.2.tar.gz -o rabbitmq.tar.gz \
    && tar -xf rabbitmq.tar.gz -C rabbitmq --strip-components=1 \
    && ( \
        cd rabbitmq \
        && phpize \
        && ./configure --with-librabbitmq-dir=/usr/local/rabbitmq-c \
        && make -s -j$(nproc) && make install \
    ) \
    && echo "extension=amqp.so" > /etc/php7/conf.d/50_amqp.ini

# 后续处理
RUN set -ex \
    # 设置php-fpm为非进程守护模式
    && echo "daemonize = no" > /etc/php7/php-fpm.d/daemon.conf \
    # 设置时区
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    # 删除无用文件
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man

# docker build -t saas:1-alpine .

# docker run -it --rm --name tmp -v $(pwd):/home --entrypoint=/bin/sh  saas:1-alpine

# docker run -it --rm --name tmp -v $(pwd):/home -p 9501:9501 -p 9010:9000 --entrypoint=/bin/sh  saas:1-alpine

# docker run -itd --rm --name tmp -v $(pwd):/home  -p 9009:9008 -p 9010:9000 --entrypoint=/bin/sh  saas:1-alpine

# docker run -itd --rm --name tmp -v $(pwd):/home -p 9000:9000 saas:1-alpine

# docker run -itd --rm --name tmp -v $(pwd):/home -p 9000:9000 php:7-fpm
