# Rtorrent for Kubernetes

***THIS IS A WORK IN PROGRESS***

Optionally with Flood for web UI. Running in daemon mode by default, with logs being sent to stdout.

## Usage

TODO

## Volumes

These should be mounted in your container with persistent volumes.

| Volume                   | Purpose                                                                                                                          |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| `/opt/app-root/config`   | This should be mounted as a ConfigMap with at least a key `rtorrent.rc` containing the actual configuration file.                |
| `/opt/app-root/download` | This is where rtorrent will download stuff to.                                                                                   |
| `/opt/app-root/session`  | The session directory contains the state of rtorrent. If this is not made persistent, you will lose any torrent data on restart. |
| `/opt/app-root/watch`    | Torrent files added in this directory will be loaded by rtorrent.                                                                |

You can optionally also mount `/opt/app-root/logs`, where logs will be saved.

That said, your setup should work with the logging from stdout instead. :)
