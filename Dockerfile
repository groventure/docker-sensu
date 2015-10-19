FROM debian:jessie
MAINTAINER Hellyna NG <hellyna@groventure.com>

COPY scripts/build.sh /docker-scripts/
RUN /bin/bash /docker-scripts/build.sh

COPY conf/* /etc/sensu/conf.d/
COPY templates/* /docker-templates/
RUN chown -R sensu:sensu /docker-templates /etc/sensu/conf.d && \
    chmod 0700 /docker-templates /etc/sensu/conf.d && \
    chmod 0600 /docker-templates/* /etc/sensu/conf.d/*
USER sensu
COPY scripts/entrypoint.sh /docker-scripts/

VOLUME ["/etc/sensu", "/docker-templates"]
ENTRYPOINT ["/bin/bash", "/docker-scripts/entrypoint.sh"]
