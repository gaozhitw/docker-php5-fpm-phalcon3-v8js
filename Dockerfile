FROM php:5-fpm

ENV GYPFLAGS="-Dv8_use_external_startup_data=0 -Dlinux_use_bundled_gold=0"

RUN \
    apt-get update && \
    apt-get install -y binutils chrpath php5-dev libpcre3-dev g++ gcc make python git libvpx-dev libjpeg62-turbo-dev libpng12-dev libfreetype6-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/list/*

RUN \
    cd ${HOME} && \
    git clone git://github.com/phalcon/cphalcon.git && \
    cd cphalcon/build && \
    ./install && \
    docker-php-ext-enable phalcon.so

RUN \
    cd ${HOME} && \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git && \
    export PATH=${PWD}/depot_tools:$PATH && \
    fetch v8 && \
    cd v8 && \
    make native library=shared snapshot=on -j8

RUN \
    mkdir -p /usr/lib /usr/include && \
    cp ${HOME}/v8/out/native/lib.target/lib*.so /usr/lib/ && \
    cp -R ${HOME}/v8/include/* /usr/include && \
    chrpath -r $ORIGIN /usr/lib/libv8.so && \
    echo "create /usr/lib/libv8_libplatform.a\naddlib ${HOME}/v8/out/native/obj.target/src/libv8_libplatform.a\nsave\nend" | ar -M

RUN \
    cd /tmp && \
    git clone https://github.com/phpv8/v8js.git && \
    cd v8js && \
    git checkout 0.6.4 && \
    phpize && \
    ./configure && \
    make && make test && make install && \
    docker-php-ext-enable v8js.so

RUN \
    docker-php-ext-configure pdo_mysql && \
    docker-php-ext-configure mbstring && \
    docker-php-ext-configure sockets && \
    docker-php-ext-configure gd --with-jpeg-dir=/usr/include --with-vpx-dir=/usr/include --with-freetype-dir=/usr/include && \
    docker-php-ext-configure opcache && \
    docker-php-ext-configure exif && \
    docker-php-ext-install pdo_mysql mbstring sockets gd opcache exif

RUN \
    pecl install redis-2.2.8 && \
    docker-php-ext-enable redis.so && \
    pecl install mongo-1.6.14 && \
    docker-php-ext-enable mongo.so && \
    pecl clear-cache

RUN \
    apt-get update && \
    apt-get install -y libmcrypt-dev && \
    docker-php-ext-configure mcrypt && \
    docker-php-ext-install mcrypt && \
    apt-get clean && \
    rm -rf ${HOME}/cphalcon && \
    rm -rf ${HOME}/depot_tools && \
    rm -rf ${HOME}/v8 && \
    rm -rf /tmp/v8js && \
    rm -rf /var/lib/apt/list/*

RUN \
    mkdir -p ${HOME}/php-default-conf && \
    cp -R /usr/local/etc/* ${HOME}/php-default-conf

ADD ["./docker-entrypoint.sh", "/root/"]

VOLUME ["/var/www", "/usr/local/etc"]

ENTRYPOINT ["sh", "-c", "${HOME}/docker-entrypoint.sh"]
