#!/bin/sh

# uncomment if you have dynamic ip as target
# export ATTIC_RELOCATED_REPO_ACCESS_IS_OK

# This uses your ssh-key to log into the server
# as user attic. The server needs and attic
# installation and data would be stored in
# /home/attic/server.attic for this example.
REPOSITORY=attic@vps.domain.de:server.attic

# this is just an example to backup MyISAM
# .MYD and .frm files skiping index files
# because they can be reconstructed.
attic create --stats \
  $REPOSITORY::`date +%Y-%m-%d--%H-%M-%S` \
  "/var/lib/mysql/database1" \
  "/var/lib/mysql/datanase2" \
  --exclude "*.MYI"

# keep all backups of the last 7 days and keep
# the last one of each day infinitely
attic prune -v $REPOSITORY --keep-within=7d --keep-daily=-1
