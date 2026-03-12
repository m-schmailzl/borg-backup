#!/bin/bash
# image entrypoint

if [ -n "$ADMIN_EMAIL" ]; then
    if [ -z "$SMTP_EMAIL" ]; then
	    echo "Error: You have to provide SMTP_EMAIL."
	    exit 1
    fi

    if ! [ -e "/etc/msmtprc" ]; then
        echo "Generating SMTP configuration..."
        if [ -z "$SMTP_USER" ]; then
            export SMTP_USER="$SMTP_EMAIL"
        fi
	    envsubst < "/etc/msmtprc.tpl" > "/etc/msmtprc"
    fi
fi


if [ "$SERVER_MODE" = "1" ]; then
    echo "Starting backup server..."
    echo "$(date)"
    /app/server/setup.sh
    if ! [ $? = 0 ]; then
        echo "Server setup failed."
        exit 2; 
    fi

    exec /usr/sbin/sshd -e -D
fi


/app/client/setup.sh
if ! [ $? = 0 ]; then
    echo "Backup client setup failed."
    exit 2; 
fi

source /app/client/backup.sh
