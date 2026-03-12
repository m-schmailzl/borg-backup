#!/bin/bash
# checks backup size and available disk space on the server

if ! [ -z "$MIN_BACKUP_SIZE" ] || ! [ -z "$MAX_BACKUP_SIZE" ]; then
    echo "Checking backup size..."
    size=$(du -sm "$BACKUP_DIR" | cut -f1)
    gb=$(($size/1024))
    if ! [ $? = 0 ]; then 
        error "Could not check backup size!"
    elif ! [ -z "$MAX_BACKUP_SIZE" ] && (( $(($MAX_BACKUP_SIZE*1024)) < "$size" )); then
        error "The source directory is too big.\nSize: $gb GB\nConfigured maximum: $MAX_BACKUP_SIZE GB"
    elif ! [ -z "$MIN_BACKUP_SIZE" ] && (( $(($MIN_BACKUP_SIZE*1024)) > "$size" )); then
        error "The source directory is too small.\nSize: $gb GB\nConfigured minimum: $MIN_BACKUP_SIZE GB"
    else
        echo "Backup size: $gb GB"
    fi
fi


if ! $FAILED && [ -n "$FREE_BACKUP_SPACE" ]; then
    echo "Checking available disk space on the server..."
    free_space=$(ssh -p "$BACKUP_PORT" -i "$SSH_KEYFILE" "$SSH_USER@$BACKUP_SERVER" "df -BM '$TARGET_DIR/$CLIENT_NAME' | awk 'NR==2 {print \$4}'")
    if ! [ $? = 0 ]; then 
        error "Could not check free disk space on the server!"
    elif (( $(($FREE_BACKUP_SPACE*1024)) > "$free_space" )); then
        space=$(($free_space/1024))
        error "There is not enough space left on the backup device.\nFree space: $space GB\nConfigured minimum: $FREE_BACKUP_SPACE GB"
    else
        space=$(($free_space/1024))
        echo "Free space on the server: $space GB"
    fi
fi
