#!/usr/bin/bash

set -e
if [ $(whoami) != "root" ]; then
  sudo $0 $@
  exit 0
fi
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <DOMAIN> <FILE_ROOT>" >&2
  exit 1
fi

if [[ "$*" == *-q* ]]; then
  quiet=true
else
  quiet=false
  echo "nginx_file_conf.sh"
  echo
fi

echo "?> Enable php? (y/N)"
read php

echo "-> Creating configuration file"
cat <<EOF >>/etc/nginx/sites-available/$1
server {
    listen 80;
    server_name $1;
    root $2;

    location / {
        try_files \$uri \$uri/ =404;
    }
EOF
if [[ $php == "y" ]]; then
  cat <<EOF >>/etc/nginx/sites-available/$1

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
EOF
fi
cat <<EOF >>/etc/nginx/sites-available/$1
}
EOF
if [[ $quiet == "false" ]]; then
  echo vvvvvvvvvvvv
  cat /etc/nginx/sites-available/$1
  echo ^^^^^^^^^^^^
fi
echo "-> Enabling configuration"
ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled/$1
echo "-> Running certbot"
certbot -d $1

if [[ $quiet == "false" ]]; then
  echo
  echo "Done!"
fi
