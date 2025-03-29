# TO-DOs

This document is probably no longer needed, but I left it for a later reference.

## Add installation files to image
Add files obtained from web (wget) and add them to project and use ADD to copy them to the image directly.

This is probably not a good idea, as a lot of files would need to be added and on each Minecraft update a new jar would need to be added.
This would also require pre-built Spigot versions (which would be great, as the container would start quicker when run for te first time).
But it is a lot of work, and each new Minecraft version would need a new docker tag. And this would only confuse users not using Spigot.
I probably won't do it...

## Consider migrating to AMP
AMP is successor of McMyAdmin2: https://github.com/cubecoders/amp/wiki
The problem is - it needs a service running on host. Then you can use their docker image.
I don't like this. Maybe the docker-compose may help.
I don't have the time for this now...

## Shrink this image
Image is too large. Use smaller base image, and utilize multi-staged build, and other tricks to make the image smaller in the end.

## Delete this document
It is useful only during the development.

# Not Todos (useful during development)
## Testing the image
```
cd ~/projects/private/minecraft-server/
```

```
docker build -t mc .
```

```
docker run -dit --name mc mc
```

```
docker exec -it mc /bin/bash
```

```
docker stop mc
```

```
docker rm mc
```

```
docker image rm mc
```

```
docker image prune
```

## All in one
### Development
```
docker stop mc && docker rm mc && docker image rm mc && docker image prune
```

```
docker build -t mc . && docker run -dit --name mc -e WEBSERVER_PORT=11 mc && docker exec -it mc /bin/bash
```

### Test run
#### Create
```
docker build -t mc .
```
Run
```
docker run -d \
    --name mc \
    -p 8080:8080 \
    -p 25565:25565 \
    --stop-timeout 30 \
    -v mc:/McMyAdmin \
    -e JAVA_MEMORY=2048 \
    -e JAVA_CUSTOM_OPTS=-server \
    -e ONLINE_MODE=false \
    -e MINECRAFT_FLAVOR=Forge \
    -e MINECRAFT_VERSION=1.12.2 \
    mc
```
Remove
```
docker stop mc && docker rm mc && docker image rm mc && docker image prune && docker volume rm mc
```

### Push to docker hub
Go to repository root and execute the following:  

```shell
docker build -t bymatej/minecraft-server .
```

```shell
docker login
```

```shell
docker push bymatej/minecraft-server:latest
```
