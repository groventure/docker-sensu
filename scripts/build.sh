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
