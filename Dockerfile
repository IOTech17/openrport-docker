FROM alpine:3.15 as downloader

ARG rport_version=0.5.20
ARG frontend_build=0.5.0-build-823

RUN apk add unzip

WORKDIR /app/

RUN wget -q https://github.com/cloudradar-monitoring/rport/releases/download/${rport_version}/rportd_${rport_version}_Linux_x86_64.tar.gz -O rportd.tar.gz
RUN wget -q https://downloads.rport.io/frontend/stable/rport-frontend-stable-${frontend_build}.zip -O frontend.zip

RUN tar xzf rportd.tar.gz rportd

RUN unzip frontend.zip -d ./frontend

FROM debian:latest

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

COPY --from=downloader /app/rportd /usr/local/bin/rportd
COPY --from=downloader /app/frontend/ /var/www/html/

RUN useradd -d /var/lib/rport -m -U -r -s /bin/false rport

RUN apt-get remove --purge -y --allow-remove-essential apt && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER rport

VOLUME [ "/var/lib/rport/" ]

EXPOSE 8080
EXPOSE 3000
EXPOSE 20000-20050

HEALTHCHECK --interval=10s --timeout=5s\
    CMD wget --spider -S http://localhost:3000 2>&1 > /dev/null | grep -q "200 OK$"
