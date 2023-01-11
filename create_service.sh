#!/usr/bin/bash

set -e
if [ $(whoami) != "root" ]; then
  sudo $0 "$@"
  exit 0
fi
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <name> <description> <exec> (cwd) (user)" >&2
  exit 1
fi

name=$1
description=$2
exec=$3
cwd=$4
user=$5
temp_file=$(mktemp)
service_file=/etc/systemd/system/${name}.service

if [ -f $service_file ]; then
  echo "Error: Service '$name' already exists"
  exit 1
fi

if [[ "$*" == *-q* ]]; then
  quiet=true
else
  quiet=false
  echo "create_service.sh"
  echo
fi

echo "-> Creating system service"
cat >$temp_file <<EOF
[Unit]
Description=$description

[Service]
Type=simple
ExecStart=$exec
Restart=on-failure
$(if [ "$cwd" != "" ] && [ "$cwd" != "-q" ]; then printf WorkingDirectory=${cwd}; fi)
$(if [ "$user" != "" ] && [ "$user" != "-q" ]; then printf "User=${user}\nGroup=${user}"; fi)

[Install]
WantedBy=multi-user.target
EOF
if [[ $quiet == "false" ]]; then
  nano $temp_file
  echo vvvvvvvvvvvv
  cat $temp_file
  echo ^^^^^^^^^^^^
  read -p "-? Is this ok [Y|n] " -r
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    rm $temp_file
    exit 1
  fi
fi
mv -v $temp_file $service_file

echo "-> Enabling service"
systemctl daemon-reload
systemctl enable --now $name
systemctl status $name

if [[ $quiet == "false" ]]; then
  echo
  echo Done.
fi
