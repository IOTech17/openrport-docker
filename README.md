# rport-docker
repository to build a docker container for rport
```
rportd:
    Image: acwhiteglint\rport:latest
    restart: unless-stopped
    ports:
      - 3000:3000
      - 8080:8080
    command: -c /etc/rport/rportd.conf
    volumes:
      - ./dev/rportd/rportd.conf:/etc/rport/rportd.conf```
