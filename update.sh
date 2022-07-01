#!/usr/bin/bash

set -e
cd ~
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <SERVICE_NAME>" >&2
  exit 1
fi

echo "update.sh"
echo
if [ ! -d $1 ]; then
  echo "-> Cloning github.com/maltejur/$1"
  git clone "https://github.com/maltejur/$1.git"
  echo "-> Entering directory"
  cd $1
else
  echo "-> Entering directory"
  cd $1
  echo "-> Pulling git changes"
  git pull
fi
if [ -f ./yarn.lock ]; then
  echo "-> Updating dependencies with yarn"
  yarn
elif [ -f ./pnpm-lock.yaml ]; then
  echo "-> Updating dependencies with pnpm"
  pnpm i
elif [ -f ./package-lock.json ]; then
  echo "-> Updating dependencies with npm"
  pnpm i
fi
if [ -d "prisma" ]; then
  echo "-> Pushing prisma db"
  npx prisma db push
fi
if [ -f "package.json" ]; then
  if grep -q "directus" "package.json"; then
    echo "-> Running Directus migrations"
    npx directus bootstrap
  fi
  if grep -q "\"build\": " "package.json"; then
    echo "-> Rebuilding"
    yarn build
  fi
fi
if [ -f /etc/systemd/system/$1.service ]; then
  echo "-> Restarting service"
  sudo systemctl restart $1
elif [ -f "Deployfile" ]; then
  echo "-> Creating service from Deployfile"
  source ./Deployfile
  if [ -z "$exec" ]; then
    echo "Invalid Deployfile, skipping"
  else
    if [ -z "$cwd" ]; then
      cwd="$(readlink -f ~/$1)"
    fi
    create_service.sh "$1" "$1" "$exec" "$cwd" -q
    if [ ! -z "$timer_exec" ]; then
      if [ -z "$timer_time" ]; then
        echo "Deployfile is missing 'timer_time', skipping timer creation"
      else
        create_timer.sh "$1" "$1" "$timer_exec" "$timer_time" "$cwd" -q
      fi
    fi
  fi
fi
echo
echo "Done!"
