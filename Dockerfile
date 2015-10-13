FROM debian:jessie
MAINTAINER Hellyna NG <hellyna@groventure.com>

COPY scripts/* /docker-scripts/
COPY templates/* /docker-templates/
RUN /bin/bash /docker-scripts/build.sh

VOLUME ["/etc/sensu"]
ENTRYPOINT ["/bin/bash", "/docker-scripts/entrypoint.sh"]
