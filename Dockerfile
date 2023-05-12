FROM alpine:3.17 as downloader

ARG rport_version=0.9.12
ARG frontend_build=0.9.12-build-1128
#ARG rportplus=0.1.0
ARG NOVNC_VERSION=1.3.0

RUN apk add unzip

WORKDIR /app/

RUN wget -q https://github.com/cloudradar-monitoring/rport/releases/download/${rport_version}/rportd_${rport_version}_Linux_x86_64.tar.gz -O rportd.tar.gz \
     && tar xzf rportd.tar.gz rportd
RUN wget -q https://downloads.rport.io/frontend/stable/rport-frontend-${frontend_build}.zip -O frontend.zip \
    && unzip frontend.zip -d ./frontend
RUN mkdir rportplus && wget -q https://github.com/realvnc-labs/rport/releases/download/0.9.12/rport-plus_0.3.0@0.9.12_Linux_x86_64.tar.gz -O rportplus.tar.gz \
    && tar xzf rportplus.tar.gz -C rportplus
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.zip -O novnc.zip \
    && unzip novnc.zip && mv noVNC-${NOVNC_VERSION} ./novnc

FROM ubuntu:latest

USER root

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt update \
  && apt upgrade -y \
  && apt install -y --no-install-recommends wget procps supervisor\
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=downloader /app/rportd /usr/local/bin/rportd
COPY --from=downloader /app/frontend/ /var/www/html/
COPY --from=downloader /app/novnc/ /var/lib/rport-novnc
#COPY supervisord.conf /etc/supervisor/supervisord.conf

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
