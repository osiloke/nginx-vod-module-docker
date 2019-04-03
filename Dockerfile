FROM alpine:3.8 AS base_image

FROM base_image AS build

RUN apk add --no-cache curl build-base openssl openssl-dev zlib-dev linux-headers pcre-dev ffmpeg ffmpeg-dev
RUN mkdir nginx nginx-vod-module

ENV NGINX_VERSION 1.14.0
ENV VOD_MODULE_VERSION 1.23
ENV AKAMAI_MODULE_VERSION master

RUN curl -sL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -C nginx --strip 1 -xz
RUN curl -sL https://github.com/kaltura/nginx-vod-module/archive/${VOD_MODULE_VERSION}.tar.gz | tar -C nginx-vod-module --strip 1 -xz
RUN curl -sL https://github.com/kaltura/nginx-akamai-token-validate-module/archive/master.tar.gz | tar -xz
RUN curl -sL https://github.com/kaltura/nginx-secure-token-module/archive/master.tar.gz |  tar -xz 
RUN curl -sL https://github.com/openresty/echo-nginx-module/archive/master.tar.gz | tar -xz

WORKDIR nginx
RUN ./configure --prefix=/usr/local/nginx \
	--add-module=../nginx-vod-module \
	--add-module=../nginx-akamai-token-validate-module-master \ 
	--add-module=../nginx-secure-token-module-master \
	--add-module=../echo-nginx-module-master \
	--with-http_ssl_module \
	--with-file-aio \
	--with-threads \
	--with-cc-opt="-O3"
RUN make
RUN make install

FROM base_image
RUN apk add --no-cache ca-certificates openssl pcre zlib ffmpeg
COPY --from=build /usr/local/nginx /usr/local/nginx
RUN rm -rf /usr/local/nginx/html /usr/local/nginx/conf/*.default
ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
CMD ["-g", "daemon off;"]
