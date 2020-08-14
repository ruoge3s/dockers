# Dockerfiles

写过的docker做个记录

## 这是一个有问题的dockerfile
```Dockerfile
FROM alpine:3.12

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
    && addgroup -g 82 -S www-data \
    && adduser -u 82 -D -S -G www-data www-data \
    && apk del --purge *-dev \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/share/php7 \
    && php -v \
    && php -m \
    && sed -i "s/127.0.0.1:9000/0.0.0.0:9000/g" /etc/php7/php-fpm.d/www.conf \
    && echo "<?php echo date('Y-m-d H:i:s') . PHP_EOL;" > /home/index.php \
    && echo -e "\033[42;37m Build Completed Step1 :).\033[0m\n"

# 后续处理
RUN set -ex \
    # 设置php-fpm为非进程守护模式
    && echo "daemonize = no" > /etc/php7/php-fpm.d/daemon.conf \
    # 设置时区
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    # 删除无用文件
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man

# docker build -t dphp:1.0 .

# docker run -it --rm --name tmp -p 9000:9000 dphp:1.0

# vi /etc/nginx/conf.d/default.conf
# 添加server中(倒数第二行)
#location ~ \.php$ {
#    root           /home;
#    fastcgi_pass   127.0.0.1:9000;
#    fastcgi_index  index.php;
#    fastcgi_split_path_info ^(.+\.php)(.*)$;
#    fastcgi_param PATH_INFO $fastcgi_path_info;
#    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
#    include        fastcgi_params;
#}
# 启动nginx
# nginx -t && nginx
# 启动php-fpm
# php-fpm7 -D
# curl 127.0.0.1/index.php
# 看到输出时间表示正常
# 问题： 以上流程说明php-fpm配置正常，但是在容器外面配置nginx(同上nginx配置)， 无法访问

# docker run -it --rm --name tmp -v $(pwd):/home -p 9000:9000 php:7.2-fpm-alpine

# docker run -it --rm --name tmp -v $(pwd):/home -p 9000:9000 --entrypoint=php-fpm7 dphp:1.0
# docker run -it --rm --name tmp -v $(pwd):/home -p 9000:9000 --entrypoint=/bin/sh dphp:1.0

```
