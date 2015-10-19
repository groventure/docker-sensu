set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl

curl -L 'http://repos.sensuapp.org/apt/pubkey.gpg' | apt-key add -
echo 'deb http://repos.sensuapp.org/apt sensu main' > /etc/apt/sources.list.d/sensu.list

apt-get update
apt-get install -y --no-install-recommends \
  sensu

curl -L 'http://sensuapp.org/docs/0.20/files/check-memory.sh' \
  -o '/etc/sensu/plugins/check-memory.sh'

chown -R sensu:sensu /etc/sensu/plugins/
chmod 0700 /etc/sensu/plugins/*.sh

apt-get purge -y \
  ca-certificates \
  curl

apt-get autoremove -y
apt-get clean

rm -rvf \
  /tmp/* \
  /var/lib/apt/lists/* \
  /var/tmp/*

set +e
