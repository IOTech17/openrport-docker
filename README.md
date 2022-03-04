# rport-docker
repository to build a docker container for rport
You will need to add a config file (preferably as a mounted read-only volume pointing to your local file)
docker-compose
```
rportd:
    Image: acwhiteglint\rport:latest
    restart: unless-stopped
    ports:
      - 3000:3000
      - 8080:8080
    command: -c /etc/rport/rportd.conf
    volumes:
      - ./dev/rportd/rportd.conf:/etc/rport/rportd.conf
