#!/bin/sh -f
DOCKER_IMAGE_NAME=bkjeholt/mqtt-agent-onewire
DOCKER_CONTAINER_NAME=hic-agent-onewire

DOCKER_IMAGE_BASE_TAG=${1}

ARCHITECTURE=rpi

echo "------------------------------------------------------------------------"
echo "-- Run image:       $DOCKER_IMAGE_NAME:latest "

DOCKER_IMAGE=${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_BASE_TAG}-${ARCHITECTURE}

echo "------------------------------------------------------------------------"
echo "-- Remove docker container if it exists"
echo "-- Container:   $DOCKER_CONTAINER_NAME "
echo "------------------------------------------------------------------------"

docker rm -f $DOCKER_CONTAINER_NAME

echo "------------------------------------------------------------------------"
echo "-- Start container "
echo "-- Based on image: $DOCKER_IMAGE "
echo "------------------------------------------------------------------------"
docker run -d \
           --restart="always" \
           --link ${DOCKER_CONTAINER_NAME_MYSQL}:mysql \
           --link ${DOCKER_CONTAINER_NAME_MQTT}:mqtt \
           --name $DOCKER_CONTAINER_NAME \
           $DOCKER_IMAGE
