mkdir certs
openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
  -x509 -days 3650 -out certs/domain.crt