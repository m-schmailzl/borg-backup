#!/bin/bash
# first time server setup

env > /server.env

cd /app/ssh


if ! [ -e "/app/ssh/authorized_keys" ]; then
	if ! [ -e "$SSH_KEYFILE.pub" ]; then
		echo "Generating ssh authentification key..."
		ssh-keygen -t ed25519 -N "" -f "$SSH_KEYFILE"
		if ! [ $? = 0 ]; then exit $?; fi
	fi

	echo "Copying ssh authentification key..."
	cp -f "$SSH_KEYFILE.pub" "/app/ssh/authorized_keys"
	if ! [ $? = 0 ]; then exit $?; fi
fi


if ! [ -e ssh_host_ed25519_key ]; then
	echo "Generating ssh host key..."
	ssh-keygen -N "" -t ed25519 -a 256 -f ssh_host_ed25519_key
	if ! [ $? = 0 ]; then exit $?; fi
fi

chown -R root .
chmod 644 *
chmod 600 ssh_host_ed25519_key "$SSH_KEYFILE"


if ! getent group borg > /dev/null 2>&1; then
	echo "Adding user '$SSH_USER' with $UID:$GID..."
    addgroup -g $GID borg
	adduser -D -s "/bin/bash" -u $UID -G borg "$SSH_USER"
	passwd -u "$SSH_USER"
fi

mkdir -p "$TARGET_DIR"
