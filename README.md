# openrport-docker
repository to build a docker container for rport using alpine as the base image, this version contains guacd to use RDP via web browser (remember to disable nla authentication for RDP).
Fail2ban and iptables are also running to further protect rport from scanner and password guessing attacks.
You will need to add a config file (preferably as a mounted read-only volume pointing to your local file)

If you want to use a database to store the data please follow this guide : https://oss.openrport.io

docker-compose
```
version: '3.9'
services:
  rport-server:
    container_name: rport
    image: iotech17/openrport-docker:latest
    restart: always
    privileged: true
    ports:
      - 3000:3000
      - 4822:4822
      - 20000:8080
      - 30000-30100:30000-30100
    volumes:
     - /home/user/rport/rportd.conf:/etc/rport/rportd.conf:ro
     - /home/user/rport/rport.key:/var/lib/rport/rport.key:ro
     - /home/user/rport/rport.crt:/var/lib/rport/rport.crt:ro
      - data:/var/lib/rport/
    healthcheck:
      test: ["CMD-SHELL", "wget --no-check-certificate --spider -S http://localhost:3000 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  data:
