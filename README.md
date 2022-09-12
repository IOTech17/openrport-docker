# rport-docker
repository to build a docker container for rport, this version contains guacd to use RDP via web browser (remember to disable nla authentication for RDP).
Fail2ban and iptables are also running to further protect rport from scanner and password guessing attacks.
You will need to add a config file (preferably as a mounted read-only volume pointing to your local file)

docker-compose
```
version: '3.9'
services:
  rport-server:
    container_name: rport
    image: iotech17/rport:latest
    cap_add:
     - sys_nice
    ulimits:
      nproc: 65535
      nofile:
        soft: 262144
        hard: 262144
    restart: always
    privileged: true
    ports:
      - 3000:3000
      - 4822:4822
      - 10000:8080
      - 20000-20100:20000-20100
    volumes:
      - /path/rportd.conf:/etc/rport/rportd.conf:ro
      - /path/rport.key:/var/lib/rport/rport.key:ro
      - /path/rport.crt:/var/lib/rport/rport.crt:ro
      - data:/var/lib/rport/

volumes:
  data:
