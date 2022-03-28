FROM alpine:3.15 as downloader

ARG rport_version=0.6.3
ARG frontend_build=0.6.0-build-966
ARG NOVNC_VERSION=1.3.0

RUN apk add unzip

WORKDIR /app/

RUN wget -q https://github.com/cloudradar-monitoring/rport/releases/download/${rport_version}/rportd_${rport_version}_Linux_x86_64.tar.gz -O rportd.tar.gz \
     && tar xzf rportd.tar.gz rportd
RUN wget -q https://downloads.rport.io/frontend/stable/rport-frontend-stable-${frontend_build}.zip -O frontend.zip \
    && unzip frontend.zip -d ./frontend
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.zip -O novnc.zip \
    && unzip novnc.zip && mv noVNC-${NOVNC_VERSION} ./novnc

FROM guacamole/guacd:latest

USER root

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

RUN export DEBIAN_FRONTEND=noninteractive && apt update && apt install -y --no-install-recommends wget fail2ban iptables supervisor

COPY --from=downloader /app/rportd /usr/local/bin/rportd
COPY --from=downloader /app/frontend/ /var/www/html/
COPY --from=downloader /app/novnc/ /var/lib/rport-novnc
COPY supervisord.conf /etc/supervisor/supervisord.conf

RUN useradd -d /var/lib/rport -m -U -r -s /bin/false rport

RUN touch /var/lib/rport/rport.log && chown rport /var/lib/rport/rport.log

COPY jail.conf /etc/fail2ban/
COPY defaults-debian.conf  /etc/fail2ban/jail.d
COPY rportd-client-connect.conf /etc/fail2ban/filter.d/

RUN service fail2ban restart

RUN apt-get remove --purge -y --allow-remove-essential apt && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER rport

VOLUME [ "/var/lib/rport/" ]

EXPOSE 8080
EXPOSE 3000
EXPOSE 20000-30000
EXPOSE 4822

CMD ["/usr/bin/supervisord"]

HEALTHCHECK --interval=30s --timeout=5s\
    CMD wget --no-check-certificate --spider -S https://localhost:3000 2>&1 > /dev/null | grep -q "200 OK$"
