FROM quay.io/3scale/base:trusty

MAINTAINER Michal Cichra <michal@3scale.net> # 2014-05-21

# have to install wget first to download the key for dotdeb
RUN apt-install wget
RUN wget -qO- http://www.dotdeb.org/dotdeb.gpg | apt-key add - \
 && echo 'deb http://packages.dotdeb.org squeeze all' > /etc/apt/sources.list.d/redis.list \
 && apt-get update \
 && apt-install redis-server cron supervisor logrotate \
                make build-essential libpcre3-dev libssl-dev \
                iputils-arping libexpat1-dev unzip curl

ENV OPENRESTY_VERSION 1.7.4.1
ADD ngx_openresty-${OPENRESTY_VERSION}.tar.gz /root/
RUN cd /root/ngx_openresty-* \
 && curl https://gist.githubusercontent.com/mikz/4dae10a0ef94de7c8139/raw/33d6d5f9baf68fc5a0748b072b4d94951e463eae/system-ssl.patch | patch -p0 \
 && ./configure --prefix=/opt/openresty --with-http_gunzip_module --with-luajit \
    --with-luajit-xcflags=-DLUAJIT_ENABLE_LUA52COMPAT \
    --http-client-body-temp-path=/var/nginx/client_body_temp \
    --http-proxy-temp-path=/var/nginx/proxy_temp \
    --http-log-path=/var/nginx/access.log \
    --error-log-path=/var/nginx/error.log \
    --pid-path=/var/nginx/nginx.pid \
    --lock-path=/var/nginx/nginx.lock \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_auth_request_module \
    --without-http_fastcgi_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --with-md5-asm \
    --with-sha1-asm \
    --with-file-aio \
 && make \
 && make install \
 && rm -rf /root/ngx_openresty* \
 && ln -sf /opt/openresty/nginx/sbin/nginx /usr/local/bin/nginx \
 && ln -sf /usr/local/bin/nginx /usr/local/bin/openresty \
 && ln -sf /opt/openresty/bin/resty /usr/local/bin/resty

RUN ln -sf /opt/openresty/luajit/bin/luajit-2.1.0-alpha /opt/openresty/luajit/bin/lua \
 && ln -sf /opt/openresty/luajit/bin/lua /usr/local/bin/lua

RUN wget -qO- http://luarocks.org/releases/luarocks-2.2.0.tar.gz | tar xvz -C /tmp/ \
 && cd /tmp/luarocks-* \
 && ./configure --with-lua=/opt/openresty/luajit \
    --with-lua-include=/opt/openresty/luajit/include/luajit-2.1 \
    --with-lua-lib=/opt/openresty/lualib \
 && make && make install \
 && rm -rf /tmp/luarocks-*

#ADD redis.conf /etc/redis/
ADD supervisor /etc/supervisor
ADD redis.conf /etc/redis/

ONBUILD CMD ["supervisord", "-n"]
