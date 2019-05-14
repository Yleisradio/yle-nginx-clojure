FROM openjdk:8-jdk-alpine

ARG NGINX_VERSION
ARG NGINX_CLOJURE_VERSION

ENV NGINX_VERSION $NGINX_VERSION
ENV NGINX_CLOJURE_VERSION $NGINX_CLOJURE_VERSION
ENV DEBIAN_FRONTEND noninteractive

# Upgrade the OS and install build dependencies
RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        bash \
        build-base \
        pcre-dev \
        openssl-dev \
        zlib-dev

# Add sources
COPY src /build/

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
        # Building in Alpine defaults to error from warnings, which differs from previously used Debian
        --with-cc-opt="-Wno-error" \
        --with-md5=/usr/include/openssl && \
    make && \
    make install

# Build and copy nginx-clojure uberjar
COPY scripts/lein /build/
RUN cd /build/nginx-clojure-${NGINX_CLOJURE_VERSION} && \
    LEIN_ROOT=1 /build/lein uberjar && \
    mkdir -p /usr/lib/nginx/jars && \
    cp target/nginx-clojure-${NGINX_CLOJURE_VERSION}-standalone.jar \
        /usr/lib/nginx/jars/nginx-clojure.jar && \
    rm -rf $HOME/.m2 $HOME/.lein

# Add config
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/clojure.conf /etc/nginx/conf.d/clojure.conf

# -------------------------------------------------------------------
# Build the runtime container
# -------------------------------------------------------------------
FROM openjdk:8-jre-alpine

ARG NGINX_CLOJURE_VERSION
ENV NGINX_CLOJURE_VERSION ${NGINX_CLOJURE_VERSION}

RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache pcre

# ensure www-data user exists
RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data

RUN mkdir -p \
          /etc/nginx/conf.d \
          /etc/nginx/sites-available \
          /etc/nginx/sites-enabled \
          /usr/lib/nginx/jars \
          /usr/sbin \
          /usr/share \
          /var/log/nginx \
          /var/lib/nginx && \
    chown -R www-data /var/log/nginx

COPY --from=0 /usr/sbin/nginx /usr/sbin/nginx
RUN chmod -R 755 /usr/sbin/nginx

COPY --from=0 /etc/nginx/ /etc/nginx/
RUN rm -f /etc/nginx/*.default
COPY --from=0 /etc/nginx/conf.d/clojure.conf /etc/nginx/conf.d/clojure.conf

COPY --from=0 /usr/lib/nginx/jars/nginx-clojure.jar /usr/lib/nginx/jars/nginx-clojure.jar

COPY --from=0 /usr/share/nginx/ /usr/share/nginx/

# I don't know if this is a bug or what, but libjvm.so could not be found from under server directory.
RUN ln -s /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/server/libjvm.so /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/libjvm.so

CMD /usr/sbin/nginx -g 'daemon off;'
