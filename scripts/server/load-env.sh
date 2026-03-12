#!/bin/bash
# loads all env variables stored in /server.env

while IFS='=' read -r key value; do
    if [ -z "$(eval echo \$$key)" ]; then
        export "$key=$value"
    fi
done < /server.env
