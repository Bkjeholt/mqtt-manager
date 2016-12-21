#!/bin/bash -f

DOCKER_IMAGE_NAME=bkjeholt/mqtt-manager
DOCKER_CONTAINER_NAME=hic-manager

DOCKER_CONTAINER_NAME_MYSQL=mysql-db-hic
DOCKER_CONTAINER_NAME_MQTT=mqtt-broker

echo "------------------------------------------------------------------------"
echo "-- Run image:       $DOCKER_IMAGE_NAME:latest "

DOCKER_IMAGE=$(../SupportFiles/DockerSupport/get-latest-image-string.sh $DOCKER_IMAGE_NAME)

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
