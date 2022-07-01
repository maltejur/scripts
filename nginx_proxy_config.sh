#!/bin/sh

set -e
if [ $(whoami) != "root" ]; then
  sudo $0 $@
  exit 0
fi
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <DOMAIN> <PROXY_URL>" >&2
  exit 1
fi

echo "nginx_proxy_conf.sh"
echo
echo "-> Creating configuration file"
cat << EOF >> /etc/nginx/sites-available/$1
server {
    listen 80;
    server_name $1;

    location / {
        proxy_pass $2;
    }
}
EOF
echo vvvvvvvvvvvv
cat /etc/nginx/sites-available/$1
echo ^^^^^^^^^^^^
echo "-> Enabling configuration"
ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled/$1
echo "-> Running certbot"
certbot -d $1
echo
echo "Done!"
