set -e

if [[ "$1" != 'server' && "$1" != 'api' && "$1" != 'client' ]]; then
  echo "Usage: $0 <server|api|client>" >&2
  exit 1
fi

if [[ -z "$RABBITMQ_PORT_5672_TCP_ADDR" ]]; then
  echo '$RABBITMQ_PORT_5672_TCP_ADDR not defined. Aborting...' >&2
  exit 1
fi

if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST" ]]; then
  echo '$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST not defined. Aborting...' >&2
  exit 1
fi

if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER" ]]; then
  echo '$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER not defined. Aborting...' >&2
  exit 1
fi

if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS" ]]; then
  echo '$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS not defined. Aborting...' >&2
  exit 1
fi

localconf_path='/etc/sensu/config.json'

if [[ "$1" == 'client' ]]; then
  cat > "$localconf_path" <<EOF
{
  "rabbitmq": {
    "host": "$RABBITMQ_PORT_5672_TCP_ADDR",
    "vhost": "$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST",
    "user": "$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER",
    "password": "$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS"
  }
}
EOF
else
  if [[ -z "$REDIS_PORT_6379_TCP_ADDR" ]]; then
    echo '$REDIS_PORT_6379_TCP_ADDR not defined. Aborting...' >&2
    exit 1
  fi
  cat > "$localconf_path" <<EOF
{
  "rabbitmq": {
    "host": "$RABBITMQ_PORT_5672_TCP_ADDR",
    "vhost": "$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST",
    "user": "$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER",
    "password": "$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS"
  },
  "redis": {
    "host": "$REDIS_PORT_6379_TCP_ADDR"
  }
}
EOF
fi

exec "/opt/sensu/bin/sensu-$1" \
  -c "$localconf_path" \
  -d '/etc/sensu/conf.d' \
  -e '/etc/sensu/extensions' \
  "$@"
