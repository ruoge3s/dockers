FROM centos:centos8.2.2004

ENV WORK_DIR "/home/tmp"
ENV PHP_INSTALL_RID /usr/local/php72
ENV PHP_INI_DIR /usr/local/etc/php

# 创建工作目录
RUN mkdir -p ${WORK_DIR} \
&& yum update -y \
&& yum install -y epel-release \
&& yum install -y libmcrypt libmcrypt-devel \
&& yum install -y \
  make \
  gcc \
  autoconf \
  pcre pcre-devel \
  zlib zlib-devel \
  libxml2 libxml2-devel \
  openssl openssl-devel \
  libjpeg libjpeg-devel \
  libpng libpng-devel \
  glibc-headers gcc-c++ \
&& yum install -y libcurl libcurl-devel --skip-broken \
&& yum install -y freetype freetype-devel --skip-broken \
&& cd ${WORK_DIR} \
&& curl -SL "http://mirrors.sohu.com/php/php-7.2.33.tar.gz"  -o php72.tar.gz \
&& mkdir -p php72 \
&& tar -xf ${WORK_DIR}/php72.tar.gz -C php72 --strip-components=1 \
&& cd php72 \
  && mkdir -p "${PHP_INI_DIR}/conf.d" \
  && ./configure \
    --prefix=${PHP_INSTALL_RID} \
    --with-config-file-path="${PHP_INI_DIR}" \
    --with-config-file-scan-dir="${PHP_INI_DIR}/conf.d" \
    --with-mysqli \
    --with-pdo-mysql \
    --with-jpeg-dir \
    --with-png-dir \
    --with-iconv-dir \
    --with-freetype-dir \
    --with-zlib \
    --with-libxml-dir \
    --with-gd \
    --with-openssl \
    --with-mhash \
    --with-curl \
    --with-fpm-user=nobody \
    --with-fpm-group=nobody \
    --enable-bcmath \
    --enable-soap \
    --enable-zip \
    --enable-fpm \
    --enable-mbstring \
    --enable-sockets \
    --enable-opcache \
    --enable-pcntl \
    --enable-simplexml \
    --enable-xml \
    --disable-fileinfo \
    --disable-rpath \
  && make -s -j$(nproc) \
  && make install \
  && /bin/cp -rf php.ini-production ${PHP_INI_DIR}/php.ini \
# 设置php-fpm.conf
&& cd "${PHP_INSTALL_RID}/etc" \
&& /bin/cp -rf php-fpm.conf.default php-fpm.conf \
&& /bin/cp -rf php-fpm.d/www.conf.default php-fpm.d/www.conf \
# 把PHP加入环境变量
&& echo "PATH=\$PATH:/usr/local/php72/bin:/usr/local/php72/sbin" > /etc/profile.d/php.sh \
&& echo "export PATH" >> /etc/profile.d/php.sh \
&& source /etc/profile \
&& cd ${WORK_DIR} \
&& curl -SL "https://github.com/swoole/swoole-src/archive/v4.5.2.tar.gz" -o swoole.tar.gz \
&& mkdir -p swoole \
&& tar -xf swoole.tar.gz -C swoole --strip-components=1 \
&& cd swoole \
    && phpize \
    && ./configure --enable-mysqlnd --enable-openssl --enable-http2 \
    && make -s -j$(nproc) \
    && make install \
&& echo "extension=swoole.so" > ${PHP_INI_DIR}/conf.d/50_swoole.ini \
&& php --ri swoole \
## 安装memcache
&& source /etc/profile \
&& cd ${WORK_DIR} \
&& curl -SL "https://github.com/websupport-sk/pecl-memcache/archive/4.0.4.tar.gz" -o memcache.tar.gz \
&& mkdir -p memcache \
&& tar -xf memcache.tar.gz -C memcache --strip-components=1 \
&& cd memcache \
    && phpize \
    && ./configure --disable-memcache-session \
    && make -s -j$(nproc) \
    && make install \
&& echo "extension=memcache.so" > ${PHP_INI_DIR}/conf.d/50_memcache.ini \
&& php --ri memcache \
&& cd ${WORK_DIR} \
&& curl -SL "https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz" -o libmemcached.tar.gz \
&& mkdir -p libmemcached \
&& tar -xf libmemcached.tar.gz -C libmemcached --strip-components=1 \
&& cd libmemcached \
    && sed -i '42c \ \ if (!opt_servers)' clients/memflush.cc \
    && sed -i '51c \ \ if (!opt_servers)' clients/memflush.cc \
    && ./configure \
    && make -s -j$(nproc) \
    && make install \
&& source /etc/profile \
&& cd ${WORK_DIR} \
&& curl -SL "https://github.com/php-memcached-dev/php-memcached/archive/v3.1.5.tar.gz" -o memcached.tar.gz \
&& mkdir -p memcached \
&& tar -xf memcached.tar.gz -C memcached --strip-components=1 \
&& cd memcached \
    && phpize \
    && ./configure --disable-memcached-sasl \
    && make -s -j$(nproc) \
    && make install \
&& echo "extension=memcached.so" > ${PHP_INI_DIR}/conf.d/50_memcached.ini \
&& php --ri memcached \
# 安装amqp依赖、amqp
&& cd ${WORK_DIR} \
&& curl -SL "https://github.com/alanxz/rabbitmq-c/releases/download/v0.8.0/rabbitmq-c-0.8.0.tar.gz" -o rabbitmq-c.tar.gz \
&& mkdir -p rabbitmq-c \
&& tar -xf rabbitmq-c.tar.gz -C rabbitmq-c --strip-components=1 \
&& cd rabbitmq-c \
    && ./configure --prefix=/usr/local/rabbitmq-c \
    && make -s -j$(nproc) \
    && make install \
&& source /etc/profile \
&& cd ${WORK_DIR} \
&& curl -SL "https://github.com/php-amqp/php-amqp/archive/v1.10.2.tar.gz" -o rabbitmq.tar.gz \
&& mkdir -p rabbitmq \
&& tar -xf rabbitmq.tar.gz -C rabbitmq --strip-components=1 \
&& cd rabbitmq \
    && phpize \
    && ./configure --with-librabbitmq-dir=/usr/local/rabbitmq-c \
    && make -s -j$(nproc) \
    && make install \
&& echo "extension=amqp.so" > ${PHP_INI_DIR}/conf.d/50_amqp.ini \
&& php --ri amqp \
# 安装redis扩展
&& source /etc/profile \
&& cd ${WORK_DIR} \
&& curl -SL "https://github.com/phpredis/phpredis/archive/5.3.1.tar.gz" -o redis.tar.gz \
&& mkdir -p redis \
&& tar -xf redis.tar.gz -C redis --strip-components=1 \
&& cd redis \
    && phpize \
    && ./configure \
    && make -s -j$(nproc) \
    && make install \
&& echo "extension=redis.so" > ${PHP_INI_DIR}/conf.d/50_redis.ini \
&& php --ri redis \
# 清除内容缓存内容
&& rm -rf /usr/local/php72/php/man \
&& yum clean all \
&& rm -rf /var/cache/yum/* \
&& dnf clean all \
&& rm -rf /var/cache/dnf/* \
&& rm -rf ${WORK_DIR} \
&& echo -e "\033[32m😂 mission completed.\033[0m"

EXPOSE 9000

