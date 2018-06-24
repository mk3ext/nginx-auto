#!/bin/bash
yum install gcc-c++ pcre-dev pcre-devel zlib-devel make unzip

NPS_VERSION=1.13.35.1-beta;

NGINXVER=1.14.0;

MODVER=3.0.2;

NGINXEXTRAMOD=" --with-http_realip_module --with-http_ssl_module ";

NGINXADDMOD=''

WDIRC=/tmp/nginxpm

mkdir -p $WDIRC
cd $WDIRC
yum install libtool httpd-devel libxml2 libxml2-devel
git clone https://github.com/SpiderLabs/ModSecurity.git
cd ModSecurity
git checkout tags/v${MODVER}
./autogen.sh
./configure --enable-standalone-module --disable-mlogc
make
make install
NGINXADDMOD="$NGINXADDMOD --add-module=$WDIRC/ModSecurity/nginx/modsecurity "
wget https://raw.githubusercontent.com/SpiderLabs/ModSecurity/master/modsecurity.conf-recommended
cat modsecurity.conf-recommended  > /etc/nginx/modsecurity.conf
wget https://github.com/SpiderLabs/owasp-modsecurity-crs/tarball/master -O owasp-modsecurity-crs.tar.gz
tar -xvzf owasp-modsecurity-crs.tar.gz
CRS_DIR=$(find . -type d -name SpiderLabs-owasp-modsecurity-crs*)
cat ${CRS_DIR}/modsecurity_crs_10_setup.conf.example >> /etc/nginx/modsecurity.conf
cat ${CRS_DIR}/base_rules/modsecurity_*.conf >> /etc/nginx/modsecurity.conf
for f in $(find $CRS_DIR -type f -name *.data)
do
    FILE=$(basename $f)
    CMD="cp $f /etc/nginx/$FILE"
    echo ${CMD}
    ${CMD}
done
cp ModSecurity/unicode.mapping /etc/nginx/unicode.mapping
cd $WDIRC
wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip
unzip release-${NPS_VERSION}-beta.zip
cd ngx_pagespeed-release-${NPS_VERSION}-beta/
wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
tar -xzvf ${NPS_VERSION}.tar.gz  # extracts to psol/
NGINXADDMOD="$NGINXADDMOD --add-module=$WDIRC/ngx_pagespeed-release-${NPS_VERSION}-beta "
cd $WDIRC
wget http://nginx.org/download/nginx-${NGINXVER}.tar.gz
tar -xvzf nginx-${NGINXVER}.tar.gz
cd nginx-${NGINXVER}/
./configure $NGINXADDMOD $NGINXEXTRAMOD
make
sudo make install
nginx -V
/etc/init.d/nginx configtest


echo "
===============================================================================

You need to go and look at the /etc/nginx/modsecurity.conf file and change settings

You need to modify your nginx host config - see:
https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual#Configuration_Steps
"