# borg-backup
[![m-schmailzl/borg-backup](https://img.shields.io/badge/m--schmailzl%2Fborg--backup-gray?logo=github)](https://github.com/m-schmailzl/borg-backup)
[![schmailzl/borg-backup](https://img.shields.io/badge/schmailzl%2Fborg--backup-blue?logo=docker&logoColor=white)](https://hub.docker.com/r/schmailzl/borg-backup)

![Build Status](https://img.shields.io/github/actions/workflow/status/m-schmailzl/borg-backup/docker-publish.yml?branch=main)
![GitHub issues](https://img.shields.io/github/issues-raw/m-schmailzl/borg-backup)
![Docker Image Size (amd64)](https://img.shields.io/docker/image-size/schmailzl/borg-backup)
![Docker Pulls](https://img.shields.io/docker/pulls/schmailzl/borg-backup)
![Docker Stars](https://img.shields.io/docker/stars/schmailzl/borg-backup)

Docker image to backup files and databases with borg-backup

This image is WIP, come back later!


## Usage

### general configuration

* `TZ`

* `TARGET_DIR`

* `SSH_USER`

* `SSH_KEYFILE`

* `UID`

* `GID`

* `SERVER_MODE`

* `BORG_PASSPHRASE`


### client configuration

* `CLIENT_NAME`

* `BACKUP_DIR`

* `VOLUME_DIR`

* `BACKUP_SERVER`

* `BACKUP_PORT`

* `SSH_PARAMS`

* `BACKUP_PREFIX`

* `BACKUP_SUFFIX`

* `MIN_BACKUP_SIZE`

* `MAX_BACKUP_SIZE`

* `FREE_BACKUP_SPACE`


### Borg backup (client)

* `BORG_AUTO_INIT`

* `BORG_ENCRYPTION`

* `BORG_COMPRESSION`

* `BORG_UPLOAD_LIMIT`

* `BORG_CHECKPOINT_INTERVAL`

* `BORG_PARAMS`


### Database backup (client)

* `DB_BACKUP`

* `DB_BACKUP_FILTER`

* `DB_BACKUP_DEFAULT_METHOD`


### Database backup (containers)

* `DB_BACKUP_METHOD`

* `DB_BACKUP_COMMAND`

* `DB_BACKUP_USER`

* `DB_BACKUP_PASSWORD`


### Email notifications

You have to provide at least these two variables to enable email notifications:

* `ADMIN_EMAIL` - Notification emails are sent to this email address.

* `SMTP_EMAIL` - Email address from which the emails are sent

You have to set your SMTP server by either mounting `/etc/msmtprc` or using the following environment variables:

* `SMTP_FROM` - Name of the sender (default: `borg-backup`)

* `SMTP_HOST` - Hostname of the SMTP server

* `SMTP_PORT` - Port of the SMTP server (default: `587`)

* `SMTP_USER` - Username/email for authentication (default: `$SMTP_EMAIL`)

* `SMTP_PASSWORD` - Password for authentication

* `SMTP_TLS` - Enable/disable TLS (`on/off`, default: `on`)

* `SMTP_STARTTLS` - Enable/disable STARTTLS (`on/off`, default: `on`)

* `SMTP_CERTCHECK` - Enable/disable certificate verification (`on/off`, default: `on`)
