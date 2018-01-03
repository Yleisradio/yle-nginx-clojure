FROM openjdk:8

ARG NGINX_VERSION
ARG NGINX_CLOJURE_VERSION

ENV NGINX_VERSION $NGINX_VERSION
ENV NGINX_CLOJURE_VERSION $NGINX_CLOJURE_VERSION
ENV DEBIAN_FRONTEND noninteractive

# Upgrade the OS and install build dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
            gcc \
            libpcre3-dev \
            libssl-dev \
            make \
            zlib1g-dev

# Add sources
ADD src /build/

# Build nginx with nginx-clojure module
RUN cd /build/nginx-${NGINX_VERSION} && \
    ./configure \
        --add-module=/build/nginx-clojure-${NGINX_CLOJURE_VERSION}/src/c \
        --prefix=/usr/share/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-client-body-temp-path=/var/lib/nginx/body \
	--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
	--http-log-path=/var/log/nginx/access.log \
	--http-proxy-temp-path=/var/lib/nginx/proxy \
	--http-scgi-temp-path=/var/lib/nginx/scgi \
	--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
	--lock-path=/var/lock/nginx.lock \
	--pid-path=/run/nginx.pid \
	--with-http_realip_module \
	--with-http_stub_status_module \
	--with-http_ssl_module \
	--with-ipv6 \
	--with-sha1=/usr/include/openssl \
	--with-md5=/usr/include/openssl && \
    make && \
    make install

# Build and copy nginx-clojure uberjar
ADD scripts/lein /build/
RUN cd /build/nginx-clojure-${NGINX_CLOJURE_VERSION} && \
    LEIN_ROOT=1 /build/lein uberjar && \
    mkdir -p /usr/lib/nginx/jars && \
    cp target/nginx-clojure-${NGINX_CLOJURE_VERSION}-standalone.jar \
	/usr/lib/nginx/jars/nginx-clojure.jar && \
    cp $HOME/.m2/repository/org/clojure/clojure/1.5.1/clojure-1.5.1.jar \
	/usr/lib/nginx/jars/ && \
    rm -rf $HOME/.m2 $HOME/.lein

# Add config
ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/clojure.conf /etc/nginx/conf.d/clojure.conf
RUN mkdir -p \
          /etc/nginx/conf.d \
          /etc/nginx/sites-available \
          /etc/nginx/sites-enabled \
          /var/lib/nginx

# Clean up
RUN apt-get purge -y \
            gcc \
            libpcre3-dev \
            libssl-dev \
            make \
            zlib1g-dev && \
    apt-get autoremove -y && \
    rm -rf /build /var/lib/apt/lists/*

CMD /usr/sbin/nginx -g 'daemon off;'
