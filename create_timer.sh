#!/usr/bin/bash

set -e
if [ $(whoami) != "root" ]; then
  sudo $0 "$@"
  exit 0
fi
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <name> <description> <exec> <unit_active_sec> (cwd)" >&2
  echo "       (for unit_active_sec see 'man systemd.time')"
  exit 1
fi

name=$1
description=$2
exec=$3
unit_active_sec=$4
cwd=$5
temp_file=$(mktemp)
service_file=/etc/systemd/system/${name}.service
timer_file=/etc/systemd/system/${name}.timer

if [ -f $service_file ]; then
  echo "Error: Service '$name' already exists"
  exit 1
fi
if [ -f $timer_file ]; then
  echo "Error: Timer '$name' already exists"
  exit 1
fi

if [[ "$*" == *-q* ]]; then
  quiet=true
else
  quiet=false
  echo "create_timer.sh"
  echo
fi

echo "-> Creating system service"
cat >$temp_file <<EOF
[Unit]
Description=$description

[Service]
Type=oneshot
ExecStart=$exec
$(if [ "$cwd" != "" ]; then echo WorkingDirectory=${cwd}; fi)
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

echo "-> Creating system timer"
cat >$timer_file <<EOF
[Unit]
Requires=${name}.service

[Timer]
OnUnitInactiveSec=$unit_active_sec

[Install]
WantedBy=timers.target
EOF
echo vvvvvvvvvvvv
cat $timer_file
echo ^^^^^^^^^^^^

echo "-> Enabling timer"
systemctl enable --now ${name}.timer
journalctl -f -u ${name}.service

if [[ $quiet == "false" ]]; then
  echo
  echo Done.
fi
