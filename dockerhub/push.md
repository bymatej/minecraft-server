# Push the new version/tag to docker hub

## Pull the latest code from this repo
```
cd /home/matej/projects/minecraft-server && git pull
```

## Log in
```
docker login --username bymatej --password pass
```

## Build
```
docker build -t bymatej/minecraft-server .
```

## Run & test locally
```
docker run bymatej/minecraft-server
```

## Push
```
docker push bymatej/minecraft-server
```

## Build and push multiarch
- Skip _Build_ and _Run & test locally_ steps
```
docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag bymatej/minecraft-server:buildx-latest .
```

Note: 
If you get this error: 
```                                                               
error: multiple platforms feature is currently not supported for docker driver. Please switch to a different driver (eg. "docker buildx create --use")
```

Just run `docker buildx create --use` as suggested, and re-run the build/push command.

More info: https://docs.docker.com/docker-hub/ 
