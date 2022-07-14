#!/bin/bash
set -u
dir=$(pwd)
[[ -f env/default/variables ]] && source env/default/variables
[[ -f .env ]] && source .env
export DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME}"
export DOCKERHUB_PASSWORD="${DOCKERHUB_PASSWORD}"

export APP_NAME="${APP_NAME:-"hello_world"}"
export APP_VERSION="${APP_VERSION:-"0.0.1"}"

function docker_login() {
    echo "${DOCKERHUB_PASSWORD}" | docker login -u ${DOCKERHUB_USERNAME} --password-stdin > /dev/null 2>&1
    if [[ "${?}" != 0 ]]; then
        echo "docker login failed"
        echo "${FUNCNAME}::::::FAIL"
        exit 1
    fi
}

function docker_image_build() {
    docker build -t ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION} .
    docker tag ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION} ${DOCKERHUB_USERNAME}/${APP_NAME}:latest
}

function docker_image_push() {
    docker push ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION}
    docker push ${DOCKERHUB_USERNAME}/${APP_NAME}:latest
}

function docker_test() {
    local isLocal=${1}
    port=8080
    until ! $(docker ps | grep -q ${port}) ; do
        port=$(( port + 1 ))
    done
    docker run -d --name ${APP_NAME}_test_${port} -p ${port}:8080 ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION} > /dev/null 2>&1

    curl -s -o /dev/null -w "%{http_code}" http://localhost:${port} | grep 200 > /dev/null
    if [[ "${?}" == 0 ]]; then
        echo "TEST SUCCESS"
        if [[ ${isLocal} == "true" ]]; then
            echo ""
            echo ""
            echo "Go to below link from browser to check !!!"
            echo "  http://localhost:${port}"
            echo ""
            echo ""
            echo "For container logs"
            echo "  docker logs ${APP_NAME}_test_${port}"
            echo ""
            echo ""
            echo "to remove container"
            echo "  docker rm -f ${APP_NAME}_test_${port}"
            echo ""
            echo ""
            echo "to check docker scan result open docker_scan_result.txt"
            echo "  cat docker_scan_result.txt"

        else
            docker rm -f ${APP_NAME}_test_${port}
        fi
    else
        echo "TEST FAIL"
        docker rm -f ${APP_NAME}_test_${port}
    fi
}

function docker_scan() {
    docker scan ${DOCKERHUB_USERNAME}/${APP_NAME}:${APP_VERSION} >> docker_scan_result.txt
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
                docker_test "false"
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
                echo "######################### Step:2 Docker login"
                docker_login
                echo "######################### Step:3 Docker image push"
                docker_image_push
                echo "######################### Step:4 Docker image scan"
                docker_scan
                echo "######################### Step:5 Docker image test"
                docker_test "true"
                ;;
            *)

                echo ""
                usage
                exit 1
                ;;
        esac
    done

}

main $@