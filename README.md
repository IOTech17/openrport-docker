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
    
    command: bash -c "/usr/local/bin/rportd --data-dir /var/lib/rport -c /etc/rport/rportd.conf"
      
    healthcheck:
      test: wget --no-check-certificate --spider -S https://localhost:3000 2>&1 > /dev/null | grep -q "200 OK$"
      interval: 60s
      retries: 5
      start_period: 20s
      timeout: 10s

volumes:
  data:
