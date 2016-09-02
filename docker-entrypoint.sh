#!/bin/bash

if [ ! "$(ls -A /usr/local/etc)" ]; then
    cp -R $HOME/php-default-conf/* /usr/local/etc
fi

cron

exec php-fpm