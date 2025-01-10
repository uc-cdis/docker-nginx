ARG AZLINUX_BASE_VERSION=master

# For local development
FROM quay.io/cdis/amazonlinux-base:${AZLINUX_BASE_VERSION}

LABEL name="revproxy-nginx-modsec"

# Install all necessary packages in one layer
RUN dnf update -y && \
    dnf install -y \
    nginx \
    gcc \
    gcc-c++ \
    git \
    make \
    automake \
    autoconf \
    libtool \
    libxml2-devel \
    pcre-devel \
    curl-devel \
    yajl-devel \
    doxygen \
    zlib-devel \
    lmdb-devel \
    flex \
    bison \
    yum-utils \
    wget \
    tar \
    --setopt=install_weak_deps=False \
    --setopt=tsflags=nodocs && \
    dnf clean all && \
    rm -rf /var/cache/yum

# Set working directory
WORKDIR /opt

# Clone and install ModSecurity
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
    cd ModSecurity && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && \
    make && \
    make install && \
    cd ..

# Get Nginx version and source
RUN NGINX_VERSION=$(nginx -v 2>&1 | cut -d '/' -f 2) && \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxvf nginx-${NGINX_VERSION}.tar.gz

# Clone ModSecurity-nginx connector
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

# Compile Nginx with ModSecurity module
RUN NGINX_VERSION=$(nginx -v 2>&1 | cut -d '/' -f 2) && \
    cd nginx-${NGINX_VERSION} && \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules && \
    mkdir -p /usr/lib64/nginx/modules/ && \
    cp objs/ngx_http_modsecurity_module.so /usr/lib64/nginx/modules/

# Set up ModSecurity configuration
RUN mkdir -p /etc/nginx/modsec && \
    cd /etc/nginx/modsec && \
    git clone https://github.com/coreruleset/coreruleset.git && \
    mv coreruleset/crs-setup.conf.example coreruleset/crs-setup.conf && \
    mv coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example \
       coreruleset/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf && \
    cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

# Configure Nginx to use ModSecurity
RUN echo 'load_module modules/ngx_http_modsecurity_module.so;' > /etc/nginx/modules.conf && \
    echo 'modsecurity on;' > /etc/nginx/conf.d/modsecurity.conf && \
    echo 'modsecurity_rules_file /etc/nginx/modsec/main.conf;' >> /etc/nginx/conf.d/modsecurity.conf && \
    echo 'Include /etc/nginx/modsec/modsecurity.conf' > /etc/nginx/modsec/main.conf && \
    echo 'Include /etc/nginx/modsec/coreruleset/crs-setup.conf' >> /etc/nginx/modsec/main.conf && \
    echo 'Include /etc/nginx/modsec/coreruleset/rules/*.conf' >> /etc/nginx/modsec/main.conf


EXPOSE 80
STOPSIGNAL SIGTERM
# CMD nginx -g 'daemon off;'
