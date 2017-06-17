#!/usr/bin/env bash

CURRENT_DIR=$(dirname $(readlink -f $0))

function print_usage {
    MESSAGE=$1
    echo -e "\033[1;37mUseage\033[0m: ./run.sh command [command_argument, ...]"
    echo $MESSAGE
}

function print_available_commands {
    echo -e "\033[1;37mAvailable commands:\033[0m"
    echo -e "\033[0;32mup\033[0m: build or run containers"
    echo -e "\033[0;32mbash\033[0m: launch bash in container"
    echo -e "\033[0;32mshell_php\033[0m: launch bash as www-user in container"
    echo -e "\033[0;32mshell_mysql\033[0m: launch mysql in container"
    echo -e "\033[0;32mdrop\033[0m: drop container"
    echo -e "\033[0;32mstop\033[0m: stop container"
    echo ""
}

function drop_container {
    COMPOSE_PROJECT_NAME=$1
    # ask for confirm
    while true; do
        read -p "Do you really want to drop containers? (y/n): " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    # drop containers
    docker ps -a -f NAME=${COMPOSE_PROJECT_NAME} --format "{{.Names}}" | xargs -I{} docker rm {}
}

function stop_container {
    # drop containers
    docker ps -a -f NAME=${COMPOSE_PROJECT_NAME} --format "{{.Names}}" | xargs -I{} docker stop {}
}

function up_container {
    DOCKER_COMPOSE_COMMAND="docker-compose --project-name ${COMPOSE_PROJECT_NAME} --project-directory ${CURRENT_DIR}"

    # append service confugs
    if [[ ! -z $NGINX_IMAGE ]];
    then
        DOCKER_COMPOSE_COMMAND="${DOCKER_COMPOSE_COMMAND} -f ${CURRENT_DIR}/compose/nginx/compose.yaml"
    fi

    if [[ ! -z $MYSQL_IMAGE ]];
    then
        DOCKER_COMPOSE_COMMAND="${DOCKER_COMPOSE_COMMAND} -f ${CURRENT_DIR}/compose/php/compose.yaml"
    fi

    if [[ ! -z $PHP_IMAGE ]];
    then
        DOCKER_COMPOSE_COMMAND="${DOCKER_COMPOSE_COMMAND} -f ${CURRENT_DIR}/compose/mysql/compose.yaml"
    fi

    # append up params
    DOCKER_COMPOSE_COMMAND="${DOCKER_COMPOSE_COMMAND} ${@}"

    # show command
    echo -e "\033[1;37mCommand\033[0m: ${DOCKER_COMPOSE_COMMAND}"

    # start up
    bash -c "${DOCKER_COMPOSE_COMMAND}"
}

function exec_container_command_root {
    COMPOSE_PROJECT_NAME=$1
    SERVICE_NAME=$2
    SHELL_COMMAND=$3
    docker exec -it ${COMPOSE_PROJECT_NAME}_${SERVICE_NAME} ${SHELL_COMMAND}
}

function exec_container_command_user {
    COMPOSE_PROJECT_NAME=$1
    SERVICE_NAME=$2
    SHELL_COMMAND=$3
    USER_NAME=$4
    docker exec --user ${USER_NAME} -it ${COMPOSE_PROJECT_NAME}_${SERVICE_NAME} $SHELL_COMMAND
}

# read command cli arguments
COMMAND_NAME=$1
if [[ -z $COMMAND_NAME ]];
then
    echo -e "\033[1;31mInvalid command specified\033[0m"
    print_available_commands
    exit
fi

# import environment
set -o allexport
source .env
set +o allexport

# dispatch command
case $COMMAND_NAME in
    up)
        up_container ${@:1}
        ;;
    bash)
        SERVICE_NAME=$2
        exec_container_command_root ${COMPOSE_PROJECT_NAME} $SERVICE_NAME bash
        ;;
    shell_php)
        exec_container_command_user ${COMPOSE_PROJECT_NAME} php bash www-data
        ;;
    shell_mysql)
        exec_container_command_root ${COMPOSE_PROJECT_NAME} php "mysql ${COMPOSE_PROJECT_NAME}"
        ;;
    drop)
        drop_container "${COMPOSE_PROJECT_NAME}"
        ;;
    stop)
        stop_container
        ;;
    *)
        echo "Unknown command"
        ;;
esac
