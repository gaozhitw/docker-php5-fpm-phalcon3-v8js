FROM gaozhi/docker-php5-fpm-phalcon3:latest

RUN \
    apt-get update && \
    apt-get install -y binutils python wget zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/list/*

RUN \
    cd ${HOME} && \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git && \
    export PATH=${PWD}/depot_tools:$PATH && \
    fetch v8 && \
    cd v8 && \
    ${PWD}/tools/dev/v8gen.py x64.release && \
    wget https://github.com/ninja-build/ninja/releases/download/v1.7.1/ninja-linux.zip && \
    unzip ninja-linux.zip && \
    rm ninja-linux.zip && \
    mv ninja /usr/local/bin && \
    echo "is_component_build = true\nv8_enable_i18n_support = false" >> ${PWD}/out.gn/x64.release/args.gn && \
    ninja -C out.gn/x64.release

RUN \
    mkdir -p /usr/lib /usr/include && \
    cp ${HOME}/v8/out.gn/x64.release/lib*.so /usr/lib/ && \
    cp ${HOME}/v8/out.gn/x64.release/*.bin /usr/lib/ && \
    cp -R ${HOME}/v8/include/* /usr/include && \
    cd out.gn/x64.release/obj && \
    ar rcsDT libv8_libplatform.a v8_libplatform/*.o && \
    echo "create /usr/lib/libv8_libplatform.a\naddlib ${HOME}/v8/out.gn/x64.release/obj/libv8_libplatform.a\nsave\nend" | ar -M

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
    apt-get install -y tesseract-ocr libglib2.0-dev libcurl4-openssl-dev cron imagemagick && \
    cd ${HOME} && \
    curl -L 'https://megatools.megous.com/builds/megatools-1.9.98.tar.gz' > megatools-1.9.98.tar.gz && \
    tar -zxf megatools-1.9.98.tar.gz && \
    cd megatools-1.9.98 && \
    ./configure --disable-docs && \
    make && make install && \
    chmod ug+s /usr/local/bin/mega* && \
    rm -rf ${HOME}/megatools-1.9.98 && \
    rm ${HOME}/megatools-1.9.98.tar.gz && \
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

VOLUME ["/var/spool/cron/crontabs", "/var/www", "/usr/local/etc"]

ADD ["./docker-entrypoint.sh", "/root/"]

ENTRYPOINT ["sh", "-c", "${HOME}/docker-entrypoint.sh"]