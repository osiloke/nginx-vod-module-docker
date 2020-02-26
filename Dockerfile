FROM alpine:3.8 AS base_image

FROM base_image AS build

RUN apk add --no-cache curl build-base openssl openssl-dev zlib-dev linux-headers pcre-dev ffmpeg ffmpeg-dev libxslt-dev  libgd
RUN apk add --no-cache perl perl-dev
RUN apk add --no-cache geoip geoip-dev 
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
	--user=nginx \
	--group=nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--with-select_module \
	--with-poll_module \
	--with-threads \
	--with-file-aio \
	--with-http_ssl_module \
	--with-http_v2_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_xslt_module \
	--with-http_xslt_module=dynamic \
	--with-http_geoip_module \
	--with-http_geoip_module=dynamic \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_auth_request_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_degradation_module \
	--with-http_slice_module \
	--with-http_stub_status_module \
	--with-http_perl_module \
	--with-http_perl_module=dynamic \
	--with-mail \
	--with-mail=dynamic \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream=dynamic \
	--with-stream_ssl_module \
	--with-stream_realip_module \
	--with-stream_geoip_module \
	--with-stream_geoip_module=dynamic \
	--with-stream_ssl_preread_module \
	--with-cpp_test_module \
	--with-compat \
	--with-pcre \
	--with-pcre-jit \
	--with-zlib-asm=CPU \ 
	--with-debug \
	--with-ld-opt=-Wl,-E \ 
	--with-http_ssl_module \  
	--with-http_stub_status_module \ 
	--add-module=../nginx-vod-module \
	--add-module=../nginx-akamai-token-validate-module-master \ 
	--add-module=../nginx-secure-token-module-master \
	--add-module=../echo-nginx-module-master \
	--with-http_ssl_module \
	--with-file-aio \
	--with-threads \ 
	--with-cc-opt=-O3
RUN make
RUN make install

FROM base_image
RUN apk add --no-cache ca-certificates openssl pcre zlib ffmpeg
COPY --from=build /usr/local/nginx /usr/local/nginx
RUN rm -rf /usr/local/nginx/html /usr/local/nginx/conf/*.default
EXPOSE 80 443

ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
CMD ["-g", "daemon off;"]
