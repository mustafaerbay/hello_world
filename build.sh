#!/bin/bash
dir=$(pwd)
export DOCKER_HUB_USERNAME=anatolman
export DOCKER_HUB_PASSWORD="Anatolman.13"

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
    echo "${DOCKER_HUB_PASSWORD}" | docker login -u ${DOCKER_HUB_USERNAME} --password-stdin > /dev/null 2>&1
    if [[ "${?}" != 0 ]]; then
        echo "docker login failed"
        echo "${FUNCNAME}::::::FAIL"
        exit 1
    fi
}

function docker_image_build() {
    local env=${1}
    local image_tag=${2}

    # docker build -t ${DOCKER_HUB_USERNAME}/${APP_NAME}:${APP_VERSION}-${BUILD_TIME}
    docker build -t ${DOCKER_HUB_USERNAME}/${APP_NAME}:${APP_VERSION} .
}

function docker_image_push() {
    docker push ${DOCKER_HUB_USERNAME}/${APP_NAME}:${APP_VERSION}
}

function docker_test() {
     docker run -d --name ${APP_NAME}_test -p 8080:8080 ${DOCKER_HUB_USERNAME}/${APP_NAME}:${APP_VERSION}
     
     curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep 200 > /dev/null
     if [[ "${?}" == 0 ]]; then
        echo "TEST SUCCESS"
        docker rm -f ${APP_NAME}_test
     else
        echo "TEST FAIL"
        docker rm -f ${APP_NAME}_test
     fi

     docker scan ${DOCKER_HUB_USERNAME}/${APP_NAME}:${APP_VERSION}
}

main(){
    parameter_check DOCKER_HUB_USERNAME
    parameter_check DOCKER_HUB_PASSWORD
    docker_image_build
    docker_image_push
    docker_test
    
    case ${1} in 
        test)
            source ${dir}/env/test/variables
            ;;
        prod)
            source ${dir}/env/prod/variables
            ;;
        container)
            sed -i -e "s|LISTEN_PORT|${nginx_listen_port}|g" -e "s|SERVER_NAME|${nginx_server_name}|g" /etc/nginx/conf.d/custom.conf &&\
            sed -i -e "s|ENV_INFO|${env_info}|g" /usr/share/nginx/html/index.html
            ;;
        *)
            source ${dir}/env/default/variables
    esac

}

main $@