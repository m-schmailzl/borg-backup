defaults
tls ${SMTP_TLS}
tls_starttls ${SMTP_STARTTLS}
tls_certcheck ${SMTP_CERTCHECK}
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account default
host ${SMTP_HOST}
port ${SMTP_PORT}
user ${SMTP_USER}
password ${SMTP_PASSWORD}
auth on
from ${SMTP_EMAIL}
logfile -
timeout 10
