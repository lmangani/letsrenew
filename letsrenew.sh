#!/bin/bash
# Letsencrypt helper mixture from various PD sources

web_service='nginx'
config_file="/tmp/null.ini"
timestamp=$(date +%s)

le_path='/opt/letsencrypt'
exp_limit=30;

email='root@localhost'
domains='example.com, www.example.com'
webroot='/usr/share/nginx/html'
keysize='4096'

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# USER OPTIONS
while [ "$1" != "" ]; do
case $1 in
    -e | -email )
        email=$2
        if [ "$email" = "" ]; then echo "Error: Missing E-Mail Address"; exit 1; fi
        ;;

    -d | -domains )
        domains=$2
        if [ "$domains" = "" ]; then echo "Error: Missing Domain(s)"; exit 1; fi
        ;;

    -w | -webroot )
        webroot=$2
        if [ "$webroot" = "" ]; then echo "Error: Missing Webroot Path"; exit 1; fi
        ;;

    -k | -keysize )
        keysize=$2
        if [ "$keysize" = "" ]; then echo "Error: Missing Keysize"; exit 1; fi
        ;;

    -p | -path )
        le_path=$2
        if [ "$le_path" = "" ]; then echo "Error: Missing letsencrypt Path"; exit 1; fi
        ;;

    -h | -help )
        echo "Options:"
        echo "  -e |-email		Admin E-Mail Address (you@somewhere.com)"
        echo "  -d |-domains		Domain List (example.com, www.example.com)"
        echo "  -w |-webroot		Webroot Path (/usr/share/nginx/html)"
        echo "  -k |-keysize		RSA Key Size (4096)"
        echo "  -p |-path		Letsencrypt Path (/opt/letsencrypt)"
	echo
        exit 0
        ;;

     *)
        echo "Error: Unknown option $2"; exit 1
        ;;

esac
shift 2
done

## Generate temporary config
CONF='/tmp/letsconfig-tmp-$timestamp.ini'
: > $CONF
echo "rsa-key-size = $keysize" >> $CONF
echo; echo "email = $email" >> $CONF
echo; echo "domains = $domains" >> $CONF
echo; echo "webroot-path = $webroot" >> $CONF
# replace config path
config_file=$CONF

if [ ! -f $config_file ]; then
        echo "[ERROR] config file does not exist: $config_file"
        exit 1;
fi

domain=`grep "^\s*domains" $config_file | sed "s/^\s*domains\s*=\s*//" | sed 's/(\s*)\|,.*$//'`
cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"

if [ ! -f $cert_file ]; then
	echo "[ERROR] certificate file not found for domain $domain."
fi

exp=$(date -d "`openssl x509 -in $cert_file -text -noout|grep "Not After"|cut -c 25-`" +%s)
datenow=$(date -d "now" +%s)
days_exp=$(echo \( $exp - $datenow \) / 86400 |bc)

echo "Checking expiration date for $domain..."

if [ "$days_exp" -gt "$exp_limit" ] ; then
	echo "The certificate is up to date, no need for renewal ($days_exp days left)."
	# remove temp ini
	rm -rf $CONF
	exit 0;
else
	echo "The certificate for $domain is about to expire soon. Starting webroot renewal script..."
        $le_path/letsencrypt-auto certonly -a webroot --agree-tos --renew-by-default --config $config_file
	echo "Reloading $web_service"
	/usr/sbin/service $web_service reload
	echo "Renewal process finished for domain $domain"
	# remove temp ini
	rm -rf $CONF
	exit 0;
fi
