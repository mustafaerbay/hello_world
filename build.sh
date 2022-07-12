#!/bin/bash
set -x
dir=$(pwd)
export DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME}"
export DOCKERHUB_PASSWORD="${DOCKERHUB_PASSWORD}"

export APP_NAME="hello_world"
export APP_VERSION="0.0.1"

export BUILD_TIME="$(date +%H%M-%m%d%Y)"
echo "build time: $BUILD_TIME"
#exit 1

function parameter_check() {
    env | grep -i "${1}" > /dev/null 2>&1
    if [[ "${?}" != 0 ]]; then
        echo "${FUNCNAME}::::::parameter missing: ${1}"
        exit 1
    else
        echo "${FUNCNAME}::::::SUCCESS"
    fi
}


function docker_login() {
    echo "${DOCKERHUB_PASSWORD}" | docker login -u ${DOCKERHUB_USERNAME} --password-stdin > /dev/null 2>&1
    if [[ "${?}" != 0 ]]; then
        echo "docker login failed"
        echo "${FUNCNAME}::::::FAIL"
        exit 1
    fi
}

function docker_image_build() {
    local env=${1}
    local image_tag=${2}

    # docker build -t ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION}-${BUILD_TIME}
    docker build -t ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION} .
}

function docker_image_push() {
    docker push ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION}
}

function docker_test() {
    docker run -d --name ${APP_NAME}_test -p 8080:8080 ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION}
    
    curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep 200 > /dev/null
    if [[ "${?}" == 0 ]]; then
    echo "TEST SUCCESS"
    docker rm -f ${APP_NAME}_test
    else
    echo "TEST FAIL"
    docker rm -f ${APP_NAME}_test
    fi
}

function docker_scan() {
    docker scan ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION}
}

usage() {
    echo ""
    echo "Usage: $0 "
    echo "   [-b --build <APP_VERSION>]"
    echo "   [-t --test <APP_VERSION>]"
    echo "   [-p --push <APP_VERSION>]"
    echo "   [-s --scan <APP_VERSION>]"
    exit 1
}
main(){

    while getopts ":b:t:p:s:" opts; do
        case "${opts}" in
            b)
                echo "option: ${opts} started"
                APP_VERSION="${OPTARG}"
                docker_image_build
                ;;
            t)
                echo "option: ${opts} started"
                APP_VERSION="${OPTARG}"
                docker_test
                ;;
            p)
                echo "option: ${opts} started"
                parameter_check DOCKERHUB_USERNAME
                parameter_check DOCKERHUB_PASSWORD
                APP_VERSION="${OPTARG}"
                docker_login
                docker_image_push
                ;;
            s)
                echo "option: ${opts} started"
                APP_VERSION="${OPTARG}"
                docker_login
                docker_scan
                ;;
            *)

                echo "ERRROR"
                exit 1
                docker_image_build
                docker_image_push
                docker_test
                ;;
        esac
    done

}

main $@