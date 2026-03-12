#!/bin/bash
# first time client setup

if ! [ -e "$SSH_KEYFILE" ]; then
	echo "Error: SSH authentication key not found. Make sure it is located at SSH_KEYFILE ($SSH_KEYFILE)."
	exit 2
fi

chown root:root "$SSH_KEYFILE"
chmod 600 "$SSH_KEYFILE"


cd /app/ssh

if ! [ -e ssh_host_ed25519_key.pub ]; then
	echo "Error: ssh_host_ed25519_key.pub not found. Make sure it is located at '/app/ssh/ssh_host_ed25519_key.pub'."
	exit 1
fi

key="$(head -n 1 ssh_host_ed25519_key.pub | cut -d ' ' -f1-2)"
if [ -z "$key" ]; then exit 3; fi

mkdir -p /root/.ssh
echo "[$BACKUP_SERVER]:$BACKUP_PORT $key" > /root/.ssh/known_hosts
if [ $? != 0 ]; then exit $?; fi
