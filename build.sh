#!/bin/bash
set -u
dir=$(pwd)
[[ -f env/default/variables ]] && source env/default/variables
export DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME}"
export DOCKERHUB_PASSWORD="${DOCKERHUB_PASSWORD}"

export APP_NAME="${APP_NAME:-"hello_world"}"
export APP_VERSION="${APP_VERSION:-"0.0.1"}"

export BUILD_TIME="$(date +%H%M-%m%d%Y)"
echo "build time: $BUILD_TIME"
#exit 1


function docker_login() {
    echo "${DOCKERHUB_PASSWORD}" | docker login -u ${DOCKERHUB_USERNAME} --password-stdin > /dev/null 2>&1
    if [[ "${?}" != 0 ]]; then
        echo "docker login failed"
        echo "${FUNCNAME}::::::FAIL"
        exit 1
    fi
}

function docker_image_build() {
    # docker build -t ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION}-${BUILD_TIME}
    docker build -t ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION} .
}

function docker_image_push() {
    docker push ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION}
}

function docker_test() {
    port=8080
    until ! $(docker ps | grep -q ${port}) ; do
        port=$(( port + 1 ))
        echo "port is : $port"
    done
    docker run -d --name ${APP_NAME}_test -p ${port}:8080 ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION}

    curl -s -o /dev/null -w "%{http_code}" http://localhost:${port} | grep 200 > /dev/null
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
    echo "   [-b <image_tag>]  -Docker image build with image tag"
    echo "   [-t <image_tag>]  -Docker Test given image"
    echo "   [-p <image_tag>]  -Docker push given image to docker hub"
    echo "   [-s <image_tag>]  -Docker scan"
    echo "   [-a <image_tag>]  -Run all steps"
    exit 1
}
main(){

    while getopts ":b:t:p:s:a:" opts; do
        case "${opts}" in
            b)
                echo "option: ${opts} started"
                echo "Docker image build"
                APP_VERSION="${OPTARG}"
                docker_image_build
                ;;
            t)
                echo "option: ${opts} started"
                echo "Docker Test"
                APP_VERSION="${OPTARG}"
                docker_test
                ;;
            p)
                echo "option: ${opts} started"
                echo "Docker image push"
                APP_VERSION="${OPTARG}"
                docker_login
                docker_image_push
                ;;
            s)
                echo "option: ${opts} started"
                echo "Docker image vulnerability scan"
                APP_VERSION="${OPTARG}"
                docker_login
                docker_scan
                ;;
            a)
                echo "option: ${opts} started"
                echo "Docker run all steps"
                APP_VERSION="${OPTARG}"
                echo "######################### Step:1 Docker image build"
                docker_image_build
                echo "######################### Step:2 Docker image push"
                docker_image_push
                echo "######################### Step:3 Docker image test"
                docker_test
                echo "######################### Step:4 Docker image scan"
                docker_scan
                ;;
            *)

                echo ""
                usage
                exit 1
                docker_image_build
                docker_image_push
                docker_test
                ;;
        esac
    done

}

main $@