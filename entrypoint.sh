#!/usr/bin/env bash
set -e

rtorrentrc="/opt/app-root/config/rtorrent.rc"

if [ "$1" = "rtorrent" ]; then
  # check if rtorrent.rc exists
  if [ ! -f "$rtorrentrc" ]; then
      echo "WARNING: $rtorrentrc not found! Copying default configuration."
      cp /usr/local/share/doc/rtorrent/rtorrent.rc.dist "$rtorrentrc"
  fi

  # remove any existing lock files
  rm -f /opt/app-root/rtorrent/session/*.lock

  # Run rtorrent
  exec rtorrent -n -o import="$rtorrentrc"
elif [ "$1" = "bash" ]; then # start bash
    exec /usr/bin/env bash
else
    exec "$@"
fi
