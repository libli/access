#!/bin/bash

if [ ! -n "$1" ] ;then
  echo "you must enter docker tocken"
  exit 1;
fi

docker build --platform linux/amd64 -t libli/access:latest -t libli/access:0.1 .
docker login -u libli -p $1
docker push libli/access -a