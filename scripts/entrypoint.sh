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

case "$1" in
  api)
    template='/docker-templates/api-config.tmpl.json'
    if [[ -z "$API_USER" ]]; then
      echo '$API_USER not defined. Aborting...' >&2
      exit 1
    fi

    if [[ -z "$API_PASSWORD" ]]; then
      echo '$API_PASSWORD not defined. Aborting...' >&2
      exit 1
    fi
    ;;
  client)
    template='/docker-templates/client-config.tmpl.json'
    ;;
  server)
    template='/docker-templates/server-config.tmpl.json'
    ;;
esac
config='/etc/sensu/config.json'

install -Zm 600 "$template" "$config"

function escape_sed {
  echo "$1" | sed -r 's/\//\\\//g'
}

sed -i.tmp 's/{{\s*RABBITMQ_PORT_5672_TCP_ADDR\s*}}/'"$(escape_sed "$RABBITMQ_PORT_5672_TCP_ADDR")"'/g' \
  "$config"
sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST")"'/g' \
  "$config"
sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_USER\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER")"'/g' \
  "$config"
sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS")"'/g' \
  "$config"

if [[ "$1" != 'client' ]]; then
  sed -i.tmp 's/{{\s*REDIS_PORT_6379_TCP_ADDR\s*}}/'"$(escape_sed "$REDIS_PORT_6379_TCP_ADDR")"'/g' \
    "$config"
fi

if [[ "$1" == 'api' ]]; then
  sed -i.tmp 's/{{\s*API_USER\s*}}/'"$(escape_sed "$API_USER")"'/g' \
    "$config"
  sed -i.tmp 's/{{\s*API_PASSWORD\s*}}/'"$(escape_sed "$API_PASSWORD")"'/g' \
    "$config"
fi

rm -vf "${config}.tmp"

exec "/opt/sensu/bin/sensu-$1" \
  -c "$config" \
  -d '/etc/sensu/conf.d' \
  -e '/etc/sensu/extensions' \
  "$@"
