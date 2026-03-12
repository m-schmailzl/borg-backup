#!/bin/bash
# dumps databases according to configuration

mkdir -p "$BACKUP_DIR/databases"
cd "$BACKUP_DIR/databases"    

if [ -z "$DB_BACKUP_FILTER" ]; then
    db_containers=$(docker ps -q)
else
    db_containers=$(docker ps -q -f "name=$DB_BACKUP_FILTER")
fi

for container in $db_containers; do
    container_name=$(docker inspect -f '{{.Name}}' "$container" | cut -c2-)
    method=$(docker inspect -f '{{ range .Config.Env }}{{ println . }}{{ end }}' "$container" | grep ^DB_BACKUP_METHOD= | cut -d= -f2-)
    if [ $? != 0 ] || [ -z "$method" ]; then method="$DB_BACKUP_DEFAULT_METHOD"; fi

    if [ -z "$method" ] || [ "$method" = "none" ]; then
        continue
    fi


    echo "Running backup for container '$container_name' with method '$method'..."
    exit_code=0


    if [[ "$method" =~ ^(mysql|mariadb|postgres)$ ]]; then
        if [[ $(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null) != "true" ]]; then
            error "Error ($container_name): The container has to be running for database backup method '$method'."
            continue
        fi

        user=$(docker exec "$container" printenv DB_BACKUP_USER)
        if [ -z "$user" ]; then
            user=$(docker exec "$container" bash -c 'echo "${MARIADB_USER:-${MYSQL_USER:-root}}"')
        fi

		password=$(docker exec "$container" printenv DB_BACKUP_PASSWORD)
        if [ -z "$password" ]; then
            if [ "$user" = "root" ]; then
                password=$(docker exec "$container" bash -c 'echo "${MARIADB_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD:-${MARIADB_PASSWORD:-${MYSQL_PASSWORD}}}}"')
            else
                password=$(docker exec "$container" bash -c 'echo "${MARIADB_PASSWORD:-${MYSQL_PASSWORD:-${MARIADB_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD}}}}"')
            fi
        fi
    fi
    

    if [ "$method" = "volume" ]; then
        volumes=$(docker inspect -f '{{ range .Mounts }}{{ if eq .Type "volume" }}{{ .Name }}{{ println }}{{ end }}{{ end }}' "$container_name")
        
        if [ -z "$volumes" ]; then
            error "Error ($container_name): You chose the database backup method '$method' but the container has no named volumes."
            continue
        fi

        # backup the volume with rsync
        for volume in "$volumes"; do
            if ! [ -d "$VOLUME_DIR/$volume" ]; then
                error "Error ($container_name): You chose the database backup method '$method' but the volume '$volume' could not be found. Make sure it is mounted to '$VOLUME_DIR/$volume'."
            else
                rsync -a -q -l "$VOLUME_DIR/$volume" .
                if [ $? != 0 ]; then exit_code=100; fi
            fi
        done

        docker stop "$container"
        if [ $? != 0 ]; then exit_code=100; fi

        # backup the volume again after stopping the container
        for volume in "$volumes"; do
            if [ -d "$VOLUME_DIR/$volume" ]; then
                rsync -a -q -l "$VOLUME_DIR/$volume" .
                if [ $? != 0 ]; then exit_code=100; fi
            fi
        done

        docker start "$container"
        if [ $? != 0 ]; then exit_code=100; fi

    elif [ "$method" = "mysql" ]; then
        docker exec "$container" mysqldump -u "$user" -p"$password" --all-databases --single-transaction --routines --triggers --events > "$container_name.sql"
        exit_code=$?
    elif [ "$method" = "mariadb" ]; then
        docker exec "$container" mariadb-dump -u "$user" -p"$password" --all-databases --single-transaction --routines --triggers --events > "$container_name.sql"
        exit_code=$?
    elif [ "$method" = "postgres" ]; then
        docker exec "$container" pg_dumpall -U "$user" -w > "$container_name.bak"
        exit_code=$?
    elif [ "$method" = "stop" ]; then
        stopped_containers[${#stopped_containers[@]}]=$container
        echo "Stopping container '$container_name'..."
        docker stop "$container"
    elif [ "$method" = "command" ]; then
        if [[ $(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null) != "true" ]]; then
            error "Error ($container_name): The container has to be running for database backup method '$method'."
            continue
        fi
            
        command=$(docker exec "$container" printenv DB_BACKUP_COMMAND)
        if [ -z "$command" ]; then
            error "Error ($container_name): You need to specify DB_BACKUP_COMMAND for database backup method '$method'."
            continue
        fi

        docker exec "$container" bash -c "$command" > "$container_name.bak"
        exit_code=$?
    else
        error "Error: Invalid DB_BACKUP_METHOD for '$container_name'"
    fi


    if ! [ $exit_code = 0 ]; then
        error "Error: Database backup for '$container_name' failed. (Exit code: $exit_code)"
    fi
done