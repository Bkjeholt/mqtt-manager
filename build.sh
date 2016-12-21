#!/bin/sh

ROOT_PATH_SUPPORT_FILES=/Users/bjorn/Dropbox/Development/Docker/SupportFiles
DROPBOX_SUPPORT_FILES=Docker/SupportFiles
DROPBOX_PACKAGE_PATH=Docker/mqtt-agents/mqtt-agent-ts
DOCKER_HUB_USER=bkjeholt
DOCKERFILE_ROOT_PATH=${ROOT_PATH_SUPPORT_FILES}/docker/v2.2/Dockerfiles/nodejs-ts


# If applicable, download the latest and greatest files from Dropbox

${ROOT_PATH_SUPPORT_FILES}/dropbox/v2.1/download-package.sh \
                    ${DROPBOX_PACKAGE_PATH}
${ROOT_PATH_SUPPORT_FILES}/dropbox/v2.1/download-support.sh \
                    ${DROPBOX_SUPPORT_FILES} \
                    ${ROOT_PATH_SUPPORT_FILES}

# Start the build

${ROOT_PATH_SUPPORT_FILES}/docker/v2.2/build.sh \
                    ${DOCKERFILE_ROOT_PATH} \
                    ${DOCKER_HUB_USER}
