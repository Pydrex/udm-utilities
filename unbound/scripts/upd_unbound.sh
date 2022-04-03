#!/bin/sh
CONTAINER=unbound
IMAGE=klutchell/unbound:latest

podman pull $IMAGE
podman stop $CONTAINER
podman rm  $CONTAINER
podman run -d --net unbound --restart always \
    --name  $CONTAINER \
    -v "/mnt/data/unbound/:/opt/unbound/etc/unbound/ " \
    $IMAGE