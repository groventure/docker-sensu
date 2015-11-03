set -e

cmd="$1"

if [[ "$cmd" != 'server' && "$cmd" != 'api' && "$cmd" != 'client' ]]; then
  echo "Usage: $0 <server|api|client>" >&2
  exit 1
fi

function get_ip {
  head -n1 /etc/hosts | sed -rn 's/^\s*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\s+[a-f0-9]{12}\s*$/\1/pg'
}

function escape_sed {
  echo "$1" | sed -r 's/\//\\\//g'
}

function sed_rabbitmq_config {
  if [[ -z "$1" ]]; then
    echo 'sed_rabbitmq_config: $1 not defined. Aborting...' >&2
    exit 1
  fi

  if [[ -z "$RABBITMQ_PORT_5672_TCP_ADDR" ]]; then
    if [[ "$cmd" == 'client' && -n "$RABBITMQ_HOST" ]]; then
      RABBITMQ_PORT_5672_TCP_ADDR="$RABBITMQ_HOST"
    else
      echo 'sed_rabbitmq_config: $RABBITMQ_PORT_5672_TCP_ADDR not defined. Aborting...' >&2
      exit 1
    fi
  fi

  if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST" ]]; then
    if [[ "$cmd" == 'client' && -n "$RABBITMQ_VHOST" ]]; then
      RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST="$RABBITMQ_VHOST"
    else
      echo 'sed_rabbitmq_config: $RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST not defined. Aborting...' >&2
      exit 1
    fi
  fi

  if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER" ]]; then
    if [[ "$cmd" == 'client' && -n "$RABBITMQ_USER" ]]; then
      RABBITMQ_ENV_RABBITMQ_DEFAULT_USER="$RABBITMQ_USER"
    else
      echo 'sed_rabbitmq_config: $RABBITMQ_ENV_RABBITMQ_DEFAULT_USER not defined. Aborting...' >&2
      exit 1
    fi
  fi

  if [[ -z "$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS" ]]; then
    if [[ "$cmd" == 'client' && -n "$RABBITMQ_PASSWORD" ]]; then
      RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS="$RABBITMQ_PASSWORD"
    else
      echo 'sed_rabbitmq_config: $RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS not defined. Aborting...' >&2
      exit 1
    fi
  fi

  sed -i.tmp 's/{{\s*RABBITMQ_PORT_5672_TCP_ADDR\s*}}/'"$(escape_sed "$RABBITMQ_PORT_5672_TCP_ADDR")"'/g' \
    "$1"
  sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_VHOST")"'/g' \
    "$1"
  sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_USER\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_USER")"'/g' \
    "$1"
  sed -i.tmp 's/{{\s*RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS\s*}}/'"$(escape_sed "$RABBITMQ_ENV_RABBITMQ_DEFAULT_PASS")"'/g' \
    "$1"
  rm -vf "${1}.tmp"
}

function sed_redis_config {
  if [[ -z "$1" ]]; then
    echo 'sed_redis_config: $1 not defined. Aborting...' >&2
    exit 1
  fi

  if [[ -z "$REDIS_PORT_6379_TCP_ADDR" ]]; then
    echo 'sed_redis_config: $REDIS_PORT_6379_TCP_ADDR not defined. Aborting...' >&2
    exit 1
  fi

  sed -i.tmp 's/{{\s*REDIS_PORT_6379_TCP_ADDR\s*}}/'"$(escape_sed "$REDIS_PORT_6379_TCP_ADDR")"'/g' \
    "$1"
  rm -vf "${1}.tmp"
}

function sed_api_config {
  if [[ -z "$1" ]]; then
    echo 'sed_api_config: $1 not defined. Aborting...' >&2
    exit 1
  fi

  if [[ -z "$API_USER" ]]; then
    echo 'sed_api_config: $API_USER not defined. Aborting...' >&2
    exit 1
  fi

  if [[ -z "$API_PASSWORD" ]]; then
    echo 'sed_api_config: $API_PASSWORD not defined. Aborting...' >&2
    exit 1
  fi

  API_HOST="$(get_ip)"

  echo $API_HOST

  sed -i.tmp 's/{{\s*API_HOST\s*}}/'"$(escape_sed "$API_HOST")"'/g' \
    "$1"
  sed -i.tmp 's/{{\s*API_USER\s*}}/'"$(escape_sed "$API_USER")"'/g' \
    "$1"
  sed -i.tmp 's/{{\s*API_PASSWORD\s*}}/'"$(escape_sed "$API_PASSWORD")"'/g' \
    "$1"
  rm -vf "${1}.tmp"
}

function sed_client_config {
  if [[ -z "$1" ]]; then
    echo 'sed_client_config: $1 not defined. Aborting...' >&2
    exit 1
  fi

  if [[ -z "$NAME" ]]; then
    echo 'sed_client_config: $NAME not defined. Aborting...' >&2
    exit 1
  fi

  if [[ -z "$IP_ADDR" ]]; then
    echo 'sed_client_config: $IP_ADDR not provided, auto-detecting...' >&2
    IP_ADDR="$(get_ip)"

    if [[ -z "$IP_ADDR" ]]; then
      echo 'sed_client_config: Detecting ip address failed. Aborting...' >&2
      exit 1
    fi
  fi

  sed -i.tmp 's/{{\s*NAME\s*}}/'"$(escape_sed "$NAME")"'/g' \
    "$1"
  sed -i.tmp 's/{{\s*IP_ADDR\s*}}/'"$(escape_sed "$IP_ADDR")"'/g' \
    "$1"
  rm -vf "${1}.tmp"
}

cat <<EOF
Before the server starts, certain configration file are replaced by templates
in '/docker-templates'. Therefore to edit options in those configration files,
it is important to edit the template file itself.
EOF

template='/docker-templates/config.tmpl.json'
config='/etc/sensu/config.json'
case "$cmd" in
  api)
    install -Zvm 600 "$template" "$config"
    sed_rabbitmq_config "$config"
    sed_redis_config "$config"
    sed_api_config "$config"
    ;;
  client)
    if [[ "$2" == '--standalone' ]]; then
      install -Zvm 600 "$template" "$config"
      sed_rabbitmq_config "$config"
      sed_redis_config "$config"
      sed_api_config "$config"
    fi
    client_template='/docker-templates/client-config.tmpl.json'
    client_config='/etc/sensu/conf.d/client.json'

    install -Zvm 600 "$client_template" "$client_config"
    sed_client_config "$client_config"
    ;;
  server)
    # uh, do nothing.
    ;;
esac

PATH="${PATH}:/opt/sensu/bin:/opt/sensu/embedded/bin" exec \
  "/opt/sensu/bin/sensu-$cmd" \
  -c "$config" \
  -d '/etc/sensu/conf.d' \
  -e '/etc/sensu/extensions' \
  "$@"
