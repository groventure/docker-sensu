set -e

cmd="$1"

if [[ "$cmd" != 'server' && "$cmd" != 'api' && "$cmd" != 'client' ]]; then
  echo "Usage: $0 <server|api|client>" >&2
  exit 1
fi

function escape_sed {
  echo "$1" | sed -r 's/\//\\\//g'
}

function sed_rabbitmq_config {
  if [[ -z "$RABBITMQ_PORT_5672_TCP_ADDR" ]]; then
    if [[ "$cmd" == 'client' && -n "$RABBITMQ_HOST" ]]; then
      RABBITMQ_PORT_5672_TCP_ADDR="$RABBITMQ_HOST"
    else
      echo '$RABBITMQ_PORT_5672_TCP_ADDR not defined. Aborting...' >&2
      exit 1
    fi
  fi

  if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST" ]]; then
    if [[ "$cmd" == 'client' && -n "$RABBITMQ_VHOST" ]]; then
      RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST="$RABBITMQ_VHOST"
    else
      echo '$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST not defined. Aborting...' >&2
      exit 1
    fi
  fi

  if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER" ]]; then
    if [[ "$cmd" == 'client' && -n "$RABBITMQ_USER" ]]; then
      RABBITMQ_ENV_RABBITMQ_DEFAULT_USER="$RABBITMQ_USER"
    else
      echo '$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER not defined. Aborting...' >&2
      exit 1
    fi
  fi

  if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS" ]]; then
    if [[ "$cmd" == 'client' && -n "$RABBITMQ_PASSWORD" ]]; then
      RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS="$RABBITMQ_PASSWORD"
    else
      echo '$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS not defined. Aborting...' >&2
      exit 1
    fi
  fi

  sed -i.tmp 's/{{\s*RABBITMQ_PORT_5672_TCP_ADDR\s*}}/'"$(escape_sed "$RABBITMQ_PORT_5672_TCP_ADDR")"'/g' \
    "$config"
  sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST")"'/g' \
    "$config"
  sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_USER\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER")"'/g' \
    "$config"
  sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS")"'/g' \
    "$config"
  rm -vf "${config}.tmp"
}

function sed_redis_config {
  sed -i.tmp 's/{{\s*REDIS_PORT_6379_TCP_ADDR\s*}}/'"$(escape_sed "$REDIS_PORT_6379_TCP_ADDR")"'/g' \
    "$config"
  rm -vf "${config}.tmp"
}

function sed_api_config {
  if [[ -z "$API_USER" ]]; then
    echo '$API_USER not defined. Aborting...' >&2
    exit 1
  fi

  if [[ -z "$API_PASSWORD" ]]; then
    echo '$API_PASSWORD not defined. Aborting...' >&2
    exit 1
  fi

  sed -i.tmp 's/{{\s*API_USER\s*}}/'"$(escape_sed "$API_USER")"'/g' \
    "$config"
  sed -i.tmp 's/{{\s*API_PASSWORD\s*}}/'"$(escape_sed "$API_PASSWORD")"'/g' \
    "$config"
  rm -vf "${config}.tmp"
}

function sed_client_config {
  if [[ -z "$NAME" ]]; then
    echo '$NAME not defined. Aborting...' >&2
    exit 1
  fi

  ipaddr="$(head -n1 /etc/hosts | sed -rn 's/^\s*(172\.17\.[0-9]{1,3}\.[0-9]{1,3})\s+[a-f0-9]{12}\s*$/\1/pg')"

  sed -i.tmp 's/{{\s*NAME\s*}}/'"$(escape_sed "$NAME")"'/g' \
    "$config"
  sed -i.tmp 's/{{\s*ipaddr\s*}}/'"$(escape_sed "$ipaddr")"'/g' \
    "$config"
  rm -vf "${config}.tmp"
}

cat <<EOF
Before the server starts, certain configration file are replaced by templates
in '/docker-templates'. Therefore to edit options in those configration files,
it is important to edit the template file itself.
EOF

case "$cmd" in
  api)
    template='/docker-templates/api-config.tmpl.json'
    config='/etc/sensu/config.json'

    install -Zvm 600 "$template" "$config"
    sed_rabbitmq_config
    sed_redis_config
    sed_api_config
    ;;
  client)
    template='/docker-templates/client-config.tmpl.json'
    config='/etc/sensu/conf.d/client.json'

    install -Zvm 600 "$template" "$config"
    sed_client_config

    template='/docker-templates/client-rabbitmq-config.tmpl.json'
    config='/etc/sensu/config.json'

    install -Zvm 600 "$template" "$config"
    sed_rabbitmq_config
    ;;
  server)
    template='/docker-templates/server-config.tmpl.json'
    config='/etc/sensu/config.json'

    install -Zvm 600 "$template" "$config"
    sed_rabbitmq_config
    sed_redis_config
    ;;
esac

PATH="${PATH}:/opt/sensu/bin:/opt/sensu/embedded/bin" exec \
  "/opt/sensu/bin/sensu-$cmd" \
  -c "$config" \
  -d '/etc/sensu/conf.d' \
  -e '/etc/sensu/extensions' \
  "$@"
