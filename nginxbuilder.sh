#!/bin/bash


# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# Software versions
NGINX_VER=1.19.1
LIBRESSL_VER=3.1.3
OPENSSL_VER=1.1.1g
NPS_VER=1.13.35.2
HEADERMOD_VER=0.33
NAXSI_VER=0.56

# Clear log files
echo "" > /tmp/nginx-autoinstall-output.log
echo "" > /tmp/nginx-autoinstall-error.log

echo "This will build the following"
echo -e "   ${CGREEN}Nginx Latest version${CEND}"
echo -e "   ${CGREEN}Nginx PageSpeed latest version${CEND}"
echo -e "   ${CGREEN}Nginx Brotli Latest version${CEND}"
echo -e "   ${CGREEN}CloudFlare TLS Dynamic RR patch${CEND}"
echo -e "   ${CGREEN}Nginx Naxsi WAF Latest version${CEND}"
echo "What to do you want to do?"
echo "   1) Continue.."
echo "   2) Update"
echo "   3) Exit"

while [[ $OPTION !=  "1" && $OPTION != "3" ]]; do
	read -p "Select an option [1-2]: " OPTION
done
case $OPTION in
	1)
	echo -ne "       Installing dependencies	[..]\r"
        apt-get update 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        apt-get install build-essential ca-certificates wget curl libpcre3 libpcre3-dev autoconf unzip automake libtool tar git libssl-dev zlib1g-dev -y 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        if [ $? -eq 0 ]; then
			echo -ne "       Installing dependencies      [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "        Installing dependencies      [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi
        cd /usr/local/src
        #Cleaning up in case of an update
        rm -r ngx_pagespeed-*-stable 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log 
        # Download and extract of PageSpeed module
        echo -ne "       Downloading ngx_pagespeed      [..]\r"
        wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VER}-stable.zip 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        unzip v${NPS_VER}-stable.zip 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        rm v${NPS_VER}-stable.zip
        cd ngx_pagespeed-${NPS_VER}-stable
        psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
        [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
        wget ${psol_url} 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        tar -xzvf $(basename ${psol_url}) 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        rm $(basename ${psol_url})
        if [ $? -eq 0 ]; then
			echo -ne "       Downloading ngx_pagespeed      [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Downloading ngx_pagespeed      [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi
        #Download Brotli
        # Cleaning up in case of update
		rm -r libbrotli 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        echo -ne "       Downloading libbrotli          [..]\r"
        git clone https://github.com/bagder/libbrotli 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        if [ $? -eq 0 ]; then
			echo -ne "       Downloading libbrotli          [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -ne "       Downloading libbrotli          [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi
        cd libbrotli
        echo -ne "       Configuring libbrotli          [..]\r"
        ./autogen.sh 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        ./configure 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        if [ $? -eq 0 ]; then
			echo -ne "       Configuring libbrotli          [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -ne "       Configuring libbrotli          [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi
        echo -ne "       Compiling libbrotli            [..]\r"
        make -j $(nproc) 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        if [ $? -eq 0 ]; then
			echo -ne "       Compiling libbrotli            [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
            		echo -e "       Compiling libbrotli            [${CRED}FAIL${CEND}]"
            		echo ""
            		echo "Please look /tmp/nginx-autoinstall-error.log"
            		echo ""
            		exit 1
		fi

        # libbrotli install
        echo -ne "       Installing libbrotli           [..]\r"
        make install 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        if [ $? -eq 0 ]; then
            echo -ne "       Installing libbrotli           [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Installing libbrotli           [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look /tmp/nginx-autoinstall-error.log"
            echo ""
            exit 1
        fi

        # Linking libraries to avoid errors
        ldconfig 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log

        # ngx_brotli module download
        cd /usr/local/src
        rm -r ngx_brotli 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        echo -ne "       Downloading ngx_brotli         [..]\r"
        git clone https://github.com/google/ngx_brotli 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        cd ngx_brotli
        git submodule update --init 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        if [ $? -eq 0 ]; then
            echo -ne "       Downloading ngx_brotli         [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -ne "       Downloading ngx_brotli         [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look /tmp/nginx-autoinstall-error.log"
            echo ""
            exit 1
        fi

        #More Header
        cd /usr/local/src
        # Cleaning up in case of update
        rm -r headers-more-nginx-module-* 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        echo -ne "       Downloading ngx_headers_more   [..]\r"
        wget https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERMOD_VER}.tar.gz 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        tar xaf v${HEADERMOD_VER}.tar.gz
        rm v${HEADERMOD_VER}.tar.gz
        if [ $? -eq 0 ]; then
            echo -ne "       Downloading ngx_headers_more   [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -ne "       Downloading ngx_headers_more   [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look /tmp/nginx-autoinstall-error.log"
            echo ""
            exit 1
        fi

        # LibreSSL
        cd /usr/local/src
        # Cleaning up in case of update
		rm -r libressl-* 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log 
        mkdir libressl-${LIBRESSL_VER}
        cd libressl-${LIBRESSL_VER}
        echo -ne "       Downloading LibreSSL           [..]\r"
        wget -qO- http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VER}.tar.gz | tar xz --strip 1
        if [ $? -eq 0 ]; then
            echo -ne "       Downloading LibreSSL           [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Downloading LibreSSL           [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look /tmp/nginx-autoinstall-error.log"
            echo ""
            exit 1
        fi

        echo -ne "       Configuring LibreSSL           [..]\r"
        ./configure \
            LDFLAGS=-lrt \
            CFLAGS=-fstack-protector-strong \
            --prefix=/usr/local/src/libressl-${LIBRESSL_VER}/.openssl/ \
            --enable-shared=no 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        if [ $? -eq 0 ]; then
            echo -ne "       Configuring LibreSSL           [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Configuring LibreSSL         [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look /tmp/nginx-autoinstall-error.log"
            echo ""
            exit 1
        fi
        echo -ne "       Installing LibreSSL            [..]\r"
        make install-strip -j $(nproc) 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log

        if [ $? -eq 0 ]; then
            echo -ne "       Installing LibreSSL            [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Installing LibreSSL            [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look /tmp/nginx-autoinstall-error.log"
            echo ""
            exit 1
        fi

        #installing naxsi system
        cd /usr/local/src
        # Cleaning up in case of update
	rm -r naxsi-* 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
	echo -ne "       Installing  Naxsi           [..]\r"
	wget https://github.com/nbs-system/naxsi/archive/${NAXSI_VER}.tar.gz 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        tar xaf ${NAXSI_VER}.tar.gz
        rm ${NAXSI_VER}.tar.gz

        if [ $? -eq 0 ]; then
	    echo -ne "       Downloading Naxsi              [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Downloading naxsi 		    [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look /tmp/nginx-autoinstall-error.log"
            echo ""
            exit 1
        fi

        #Installing Nginx now
        rm -r /usr/local/src/nginx-* 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        cd /usr/local/src/
        echo -ne "       Downloading Nginx              [..]\r"
        wget -qO- http://nginx.org/download/nginx-${NGINX_VER}.tar.gz | tar zxf -
        cd nginx-${NGINX_VER}

        if [ $? -eq 0 ]; then
			echo -ne "       Downloading Nginx              [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -ne "       Downloading Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi

        # We need nginx conf here new
        if [[ ! -e /etc/nginx/nginx.conf ]]; then
			mkdir -p /etc/nginx
			cd /etc/nginx
			wget https://raw.githubusercontent.com/nagug/Kaapi-nginx/master/nginx.conf 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
		fi

         # We need naxsi core rules here
        if [[ ! -e /etc/nginx/naxsi_core.rules ]]; then
			mkdir -p /etc/nginx
			cd /etc/nginx
			wget https://raw.githubusercontent.com/nagug/Kaapi-nginx/master/naxsi_core.rules 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
		fi

        cd /usr/local/src/nginx-${NGINX_VER}

        # Modules configuration
		# Common configuration 
		NGINX_OPTIONS="
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--user=nginx \
		--group=nginx \
		--with-cc-opt=-Wno-deprecated-declarations"

        NGINX_MODULES="--without-http_ssi_module \
		--without-http_scgi_module \
		--without-http_uwsgi_module \
		--without-http_geo_module \
		--without-http_split_clients_module \
		--without-http_memcached_module \
		--without-http_empty_gif_module \
		--without-http_browser_module \
		--with-threads \
		--with-file-aio \
		--with-http_ssl_module \
		--with-http_v2_module \
		--with-http_mp4_module \
		--with-http_auth_request_module \
		--with-http_slice_module \
		--with-http_stub_status_module \
		--with-http_realip_module"

        NGINX_MODULES=$(echo $NGINX_MODULES; echo --with-openssl=/usr/local/src/libressl-${LIBRESSL_VER})
        NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/ngx_pagespeed-${NPS_VER}-stable")
        NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/ngx_brotli")
        NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/headers-more-nginx-module-${HEADERMOD_VER}")
        NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/naxsi-${NAXSI_VER}/naxsi_src/")

 	# Cloudflare's TLS Dynamic Record Resizing patch
        echo -ne "       TLS Dynamic Records support    [..]\r"
        wget https://raw.githubusercontent.com/cloudflare/sslconfig/master/patches/nginx__1.11.5_dynamic_tls_records.patch 2>> /tmp$
        patch -p1 < nginx__1.11.5_dynamic_tls_records.patch 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.$
        if [ $? -eq 0 ]; then
            echo -ne "       TLS Dynamic Records support    [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       TLS Dynamic Records support    [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look /tmp/nginx-autoinstall-error.log"
            echo ""
            exit 1
        fi

        # Configuring Nginx
        echo -ne "       Configuring Nginx              [..]\r"
        ./configure $NGINX_OPTIONS $NGINX_MODULES 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log

        if [ $? -eq 0 ]; then
			echo -ne "       Configuring Nginx              [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Configuring Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi

        #Compiling Nginx
		echo -ne "       Compiling Nginx                [..]\r"
		make -j $(nproc) 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log

		if [ $? -eq 0 ]; then
			echo -ne "       Compiling Nginx                [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -ne "       Compiling Nginx                [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi

        #Installing nginx
        echo -ne "       Installing Nginx               [..]\r"
        make install 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log


        # cleanup debugging symbols
        strip -s /usr/sbin/nginx
        if [ $? -eq 0 ]; then
			echo -ne "       Installing Nginx               [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -ne "       Installing Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi

        # Nginx installation from source does not add an init script for systemd and logrotate
		# Using the official systemd script and logrotate conf from nginx.org
		if [[ ! -e /lib/systemd/system/nginx.service ]]; then
			cd /lib/systemd/system/
			wget https://raw.githubusercontent.com/nagug/Kaapi-nginx/master/nginx.service 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
			# Enable nginx start at boot
			systemctl enable nginx 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
		fi

		if [[ ! -e /etc/logrotate.d/nginx ]]; then
			cd /etc/logrotate.d/
			wget https://raw.githubusercontent.com/nagug/Kaapi-nginx/master/nginx-logrotate -O nginx 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
		fi

		# Nginx's cache directory is not created by default
		if [[ ! -d /var/cache/nginx ]]; then
			mkdir -p /var/cache/nginx
		fi

		# Restart Nginx
		echo -ne "       Restarting Nginx               [..]\r"
		systemctl restart nginx 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log

		if [ $? -eq 0 ]; then
			echo -ne "       Restarting Nginx               [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -ne "       Restarting Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look /tmp/nginx-autoinstall-error.log"
			echo ""
			exit 1
		fi
        touch /var/log/default.access.log;
        mkdir -p /var/www
        mkdir -p /var/www/default
        mkdir -p /var/www/default/htdocs
        touch /var/www/default/htdocs/index.html
        mkdir -p  /etc/nginx/sites-enabled
        mkdir -p  /etc/nginx/sites-available

		# We're done !
		echo ""
		echo -ne "       ${CGREEN}Installation successful !${CEND}"
		echo ""

        exit 
    ;;
    2)
        echo "you selected 2"
        wget https://raw.githubusercontent.com/nagug/Kaapi-nginx/master/nginxbuilder.sh -O nginx-autoinstall.sh 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
        chmod +x nginxbuilder.sh
        echo ""
		echo -e "${CGREEN}Update succcessful !${CEND}"
		sleep 2
		./nginxbuilder.sh
		exit
    ;;
    3)
        exit
esac
