#!/bin/bash
# starts the backup

error () {
    FAILED=true
    MSG="${MSG}$1\n"
    echo "$1"
}

MSG="The backup of $CLIENT_NAME failed:\n"
FAILED=false
shutdown_containers=()

echo "-----------------------------------------------------------------------------"
echo "Started backup on $(date)"
echo "-----------------------------------------------------------------------------"

if [ -z "$CLIENT_NAME" ] || [ -z "$BACKUP_SERVER" ] || [ -z "$BACKUP_PORT" ]; then
    echo "Error: CLIENT_NAME, BACKUP_SERVER and BACKUP_PORT are required."
    echo "Aborting..."
    exit 1
fi


if [ "$BORG_AUTO_INIT" = "1" ]; then
   ssh -p "$BACKUP_PORT" -i "$SSH_KEYFILE" "$SSH_USER@$BACKUP_SERVER" "init-repo '$CLIENT_NAME'"
    if ! [ $? = 0 ]; then 
        error "Could not initialize the borg repository!"
    fi
fi


if ! $FAILED && [ "$DB_BACKUP" = "1" ]; then
    source /app/client/dump-databases.sh
fi


source /app/client/check-space.sh


if ! $FAILED; then
    echo "Starting backup..."

    if [ -z "$BORG_REPO" ]; then
        export BORG_REPO="ssh://$SSH_USER@$BACKUP_SERVER:${BACKUP_PORT}${TARGET_DIR}/$CLIENT_NAME"
    fi

    if [ -z "$BORG_RSH" ]; then
        export BORG_RSH="ssh -p $BACKUP_PORT -i "$SSH_KEYFILE" $SSH_PARAMS"
    fi

    cd "${BACKUP_DIR}"

    exec 3>&1
    output=$(
        borg create \
            --compression "$BORG_COMPRESSION" \
            --upload-ratelimit "$BORG_UPLOAD_LIMIT" \
            --checkpoint-interval "$BORG_CHECKPOINT_INTERVAL" \
            $BORG_PARAMS \
            "::${BACKUP_PREFIX}$(date +%Y-%m-%dT%H:%M:%S)${BACKUP_SUFFIX}" \
            . \
            2>&1 | tee /dev/fd/3
    )

    echo

    echo "--- backup stats:"
    borg info --json --last 1 | jq '.archives[0] | {start, end, duration, stats}'

    if ! [ $? = 0 ]; then
        error "Backup command failed:\n$output"
    fi
fi

if [ -n "$stopped_containers" ]; then
	echo "Starting containers which have been stopped for the backup..."
    for container in $stopped_containers; do
    	docker start "$container"
	done
fi

if $FAILED; then
    printf "\n\n\nBACKUP FAILED!\n"
    printf "$MSG"
    
    if [ -n "$ADMIN_EMAIL" ]; then
        adminmail "Backup of '$CLIENT_NAME' failed!" "$MSG"
    fi

    exit 2
else
    echo "Backup finished without errors."
fi
