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
  rm -f /opt/app-root/session/*.lock

  # Run rtorrent and wait for the log file to be created
  rtorrent -n -o import="$rtorrentrc" &
  while [ ! -f /opt/app-root/log/rtorrent.log ]; do
    sleep 0.1
  done

  # show the rtorrent log
  tail -f /opt/app-root/log/rtorrent.log

else
  # if the first argument is not "rtorrent", try to execute the command
  exec "$@"
fi
