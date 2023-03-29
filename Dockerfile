FROM alpine:3.17 as downloader

ARG rport_version=0.9.9
ARG frontend_build=0.9.5-build-1131
#ARG rportplus=0.1.0
ARG NOVNC_VERSION=1.3.0

RUN apk add unzip

WORKDIR /app/

RUN wget -q https://github.com/cloudradar-monitoring/rport/releases/download/${rport_version}/rportd_${rport_version}_Linux_x86_64.tar.gz -O rportd.tar.gz \
     && tar xzf rportd.tar.gz rportd
RUN wget -q https://downloads.rport.io/frontend/stable/rport-frontend-${frontend_build}.zip -O frontend.zip \
    && unzip frontend.zip -d ./frontend
RUN mkdir rportplus && wget -q https://github.com/realvnc-labs/rport/releases/download/0.9.9/rport-plus_0.3.0@0.9.9_Linux_x86_64.tar.gz -O rportplus.tar.gz \
    && tar xzf rportplus.tar.gz -C rportplus
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.zip -O novnc.zip \
    && unzip novnc.zip && mv noVNC-${NOVNC_VERSION} ./novnc

FROM guacamole/guacd:latest

USER root

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

RUN apk update && apk upgrade && apk add --no-cache wget supervisor && apk --purge del apk-tools

COPY --from=downloader /app/rportd /usr/local/bin/rportd
COPY --from=downloader /app/frontend/ /var/www/html/
COPY --from=downloader /app/novnc/ /var/lib/rport-novnc
COPY supervisord.conf /etc/supervisor/supervisord.conf

RUN useradd -d /var/lib/rport -m -U -r -s /bin/false rport

RUN touch /var/lib/rport/rport.log && chown rport /var/lib/rport/rport.log

#COPY jail.conf /etc/fail2ban/
#COPY defaults-debian.conf  /etc/fail2ban/jail.d
#COPY rportd-client-connect.conf /etc/fail2ban/filter.d/

#RUN service fail2ban restart

USER rport

EXPOSE 8080
EXPOSE 3000
EXPOSE 20000-30000
EXPOSE 4822

CMD ["/usr/bin/supervisord"]
