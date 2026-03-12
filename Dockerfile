FROM alpine:3
LABEL maintainer="maximilian@schmailzl.net"

RUN apk add --no-cache bash openssh openssh-client borgbackup rsync docker-cli gettext jq msmtp tzdata

COPY sshd_config /etc/ssh
COPY msmtprc.tpl /etc
COPY scripts/ /app/
RUN chmod -R 755 /app && \
	chown -R root:root /app && \
	mv /app/commands/* /usr/local/bin && \
	rm -rf /app/commands /etc/msmtprc

ENV TARGET_DIR="/media/backups" \
	SSH_USER="borg" \
	SSH_KEYFILE="/app/ssh/id_ed25519" \
	UID=1000 \
	GID=1000 \
	BACKUP_DIR="/media/backup" \
	VOLUME_DIR="/media/volumes" \
	BORG_AUTO_INIT=1 \
	BORG_ENCRYPTION="repokey" \
	BORG_COMPRESSION="lz4" \
	BORG_UPLOAD_LIMIT=0 \
	BORG_CHECKPOINT_INTERVAL=0 \
	BORG_PARAMS="--verbose --list --filter=AMCE --stats --exclude-caches -e '*.sock'" \
	SMTP_FROM="borg-backup" \
	SMTP_PORT=587 \
	SMTP_TLS="on" \
	SMTP_STARTTLS="on" \
	SMTP_CERTCHECK="on"

VOLUME /app/ssh
VOLUME /root/.cache/borg

EXPOSE 22

ENTRYPOINT ["/app/entrypoint.sh"]
