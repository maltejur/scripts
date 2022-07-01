#!/bin/sh

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <TITLE> <MESSAGE>" >&2
  exit 1
fi

smtp-cli --from pushnotify@shorsh.de --to maltejur@dismail.de --subject "$1" --body-html "$(echo $2 | sed -z 's/\n/<br\/>/g')" --verbose ; true
