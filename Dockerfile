FROM alpine:3.15 as downloader

ARG rport_version=0.6.0
ARG frontend_build=0.6.0-build-966

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

RUN apt update && apt install wget fail2ban -y

RUN echo -e "# Fail2Ban filter for rportd client connect \n[Definition] \n# Identify scanners \nfailregex = 404 [0-9]+\w+ \(<HOST>\) \n# Identify password guesser \n" >> test.conf
RUN echo -e "# service name \n[rportd-client-connect] \n# turn on /off \nenabled  = true \n# ports to ban (numeric or text) \n port     = 8080 \n# filter from previous step \nfilter   = rportd-client-connect \n# file to parse \nlogpath  = /var/lib/rport/rportd.log \n# ban rule: \n# ban all IPs that have created two 404 request during the last 20 seconds for 1hour \nmaxretry = 2 \nfindtime = 20 \n# ban on 10 minutes \nbantime = 3600" >> /etc/fail2ban/jail.conf
RUN sed -i "1s/.*/[rportd-client-connect]/" /etc/fail2ban/jail.d/defaults-debian.conf

COPY --from=downloader /app/rportd /usr/local/bin/rportd
COPY --from=downloader /app/frontend/ /var/www/html/

RUN useradd -d /var/lib/rport -m -U -r -s /bin/false rport

RUN apt-get remove --purge -y --allow-remove-essential apt && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER rport

VOLUME [ "/var/lib/rport/" ]

EXPOSE 8080
EXPOSE 3000
EXPOSE 20000-30000

HEALTHCHECK --interval=30s --timeout=5s\
    CMD wget --spider -S http://localhost:3000 2>&1 > /dev/null | grep -q "200 OK$"
