FROM alpine:3.17 as downloader

ARG rport_version=0.9.14
ARG frontend_build=0.9.12-17-build-1145
ARG NOVNC_VERSION=1.3.0

RUN apk add unzip

WORKDIR /app/

RUN wget -q https://github.com/openrport/openrport/releases/download/${rport_version}/rportd_${rport_version}_Linux_x86_64.tar.gz -O rportd.tar.gz \
     && tar xzf rportd.tar.gz rportd
RUN wget -q https://downloads.openrport.io/frontend/stable/rport-frontend-${frontend_build}.zip -O frontend.zip \
    && unzip frontend.zip -d ./frontend
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.zip -O novnc.zip \
    && unzip novnc.zip && mv noVNC-${NOVNC_VERSION} ./novnc

FROM guacamole/guacd:latest

USER root

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

RUN echo 'https://storage.sev.monster/alpine/edge/testing' | tee -a /etc/apk/repositories && \
    wget https://storage.sev.monster/alpine/edge/testing/x86_64/sevmonster-keys-1-r0.apk && \ 
    sh -c ' apk add --allow-untrusted ./sevmonster-keys-1-r0.apk && \ 
    apk update \
    && apk add gcompat wget supervisor \
    && rm /lib/ld-linux-x86-64.so.2 \
    && apk add --force-overwrite glibc \
    && apk add glibc-bin'
    
RUN apk --purge del apk-tools && rm -rf /tmp/* /var/tmp/*


COPY --from=downloader /app/rportd /usr/local/bin/rportd
COPY --from=downloader /app/frontend/ /var/www/html/
COPY --from=downloader /app/novnc/ /var/lib/rport-novnc
COPY supervisord.conf /etc/supervisord.conf

RUN useradd -d /var/lib/rport -m -U -r -s /bin/false rport

RUN touch /var/lib/rport/rport.log && chown rport /var/lib/rport/rport.log

#COPY jail.conf /etc/fail2ban/
#COPY defaults-debian.conf  /etc/fail2ban/jail.d
#COPY rportd-client-connect.conf /etc/fail2ban/filter.d/

#RUN service fail2ban restart

USER rport

RUN chmod 755 -R /var/lib/rport/

EXPOSE 8080
EXPOSE 3000
EXPOSE 20000-30000
EXPOSE 4822

CMD ["/usr/bin/supervisord"]
