FROM gaozhi/docker-php5-fpm-phalcon3:latest

ENV GYPFLAGS="-Dv8_use_external_startup_data=0 -Dlinux_use_bundled_gold=0"

RUN \
    apt-get update && \
    apt-get install -y binutils chrpath python && \
    apt-get clean && \
    rm -rf /var/lib/apt/list/*

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
    make && make test && make install

RUN \
    apt-get update && \
    apt-get install -y libgearman-dev && \
    pecl install gearman-1.1.2 && \
    docker-php-ext-enable gearman.so && \
    pecl clear-cache && \
    apt-get clean && \
    rm -rf /var/lib/apt/list/*

RUN \
    apt-get update && \
    apt-get install -y tesseract-ocr libglib2.0-dev libcurl4-openssl-dev cron && \
    cd ${HOME} && \
    curl -L 'https://megatools.megous.com/builds/megatools-1.9.97.tar.gz' > megatools-1.9.97.tar.gz && \
    tar -zxf megatools-1.9.97.tar.gz && \
    cd megatools-1.9.97 && \
    ./configure --disable-shared --enable-static && \
    make && make install && \
    rm -rf ${HOME}/megatools-1.9.97 && \
    rm ${HOME}/megatools-1.9.97.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/list/*

RUN \
    rm -rf ${HOME}/depot_tools && \
    rm -rf ${HOME}/v8 && \
    rm -rf /tmp/v8js

RUN \
    docker-php-ext-enable v8js.so && \
    mkdir -p ${HOME}/php-default-conf && \
    cp -R /usr/local/etc/* ${HOME}/php-default-conf

VOLUME ["/var/spool/cron/crontabs"]

ADD ["./docker-entrypoint.sh", "/root/"]

ENTRYPOINT ["sh", "-c", "${HOME}/docker-entrypoint.sh"]