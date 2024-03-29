#!/bin/bash
##################################################################################################################################
# Script para executar toda instalação de forma automatizada dos pacotes necessários e toda ELK Stack
# em uma VM nova rodando Debian 10 - Será adicionado uma nova tack de monitoramento neste mesmo script
# Autor: Guilherme Martins
##################################################################################################################################

DIRDESTINO='/tmp/elkStack'
logfile='/var/log/elk-installer.log'

USE_MESSAGE="
Uso: $(basename "$0") [OPÇÕES]
OPÇÕES:
    -h, --help      Show this help menu
    -e, --elk       Install ELK Stack
    -p, --pro    Install Prometheus Stack (Not ready yet)
"

function LOG(){
    echo "[`date \"+%d-%m-%Y %H:%M:%S:%s\"`] [ELK Installer] - $1" >> $logfile
}

function is_root_user() {
    if [[ $EUID != 0 ]]; then
        return 1
    fi
    return 0
}

installPkgs(){
    LOG "Installing necessary packages"
    apt-get -y update && apt-get -y upgrade && apt-get -y install curl vim git docker docker-compose

    LOG "Tuning Virtual Machine Memory"
    sysctl -w vm.max_map_count=262144
}

cloneGit(){
    local REPO='https://github.com/elastic/stack-docker.git'

    if [[ -e $DIRDESTINO ]]; then
        LOG "Install directory found"
    else
        LOG "Install directory not found, creating..."
        mkdir $DIRDESTINO
    fi

    LOG "Changing destination directory and cloning repository..."
    cd $DIRDESTINO && git clone $REPO
}

installMonitoring(){
    local REPO='' #Adicionar link github
    local CONFPRO='conf/prometheus/prometheus.yml'
    local CONFALRT='conf/alertmanager/config.yml'

    LOG "Instalando net-data" #porta 19999
    bash <(curl -Ss https://my-netdata.io/kickstart.sh)

    LOG "Cloning git from github"
    git clone $REPO


    LOG "Ajustando Slack"
    echo "Insert host IP address" ; read 
    echo "Insert slack username: " ; read USERNAME
    echo "Insert slack channel: " ; read CHANNEL
    echo "Insert Incomming WebHook: " ; read INWBHK

    LOG "Setting ip in Prometheus config"
    sed -i "s/YOUR_NETDATA_IP/$/g" $CONFPRO

    LOG "Setting config for allert manager"
    sed -i "s/USERNAME/$USENAME/g" $CONFALRT
    sed -i "s/YOURCHANNEL/$CHANNEL/g" $CONFALRT
    sed -i "s/WEBHOOK/$INWBHK" $INWBHK

    #Necessário utilizar docker-swarm caso for mais de um cluster
    #LOG "Init Docker Swarm"
    #docker swarm init
    
    LOG "Deploying docker compose"
    docker stack deploy -c docker-compose.yml monitoring

}

if ! is_root_user; then
    echo "You must be root to execute the installation!" 2>&1
    echo  2>&1
    exit 1
fi

if [[ -z $1 ]]; then
    echo "$USE_MESSAGE"
fi

while [[ -n "$1" ]]; do
    case "$1" in
        -h | --help)    echo "$USE_MESSAGE" && exit 0 ;;
        -e | --elk )    
        installPkgs
        cloneGit

        if [[ $? -eq 0 ]]; then
            cd $DIRDESTINO/stack-docker/
            docker-compose -f setup.yml up
            
            if [[ $? -eq 0 ]]; then
                echo -e "Install complete, please execute the follow command to remove orphans:
                docker-compose -f docker-compose.yml -f docker-compose.setup.yml down --remove-orphans
                Execute \"docker-compose up -d\" to turn up the infrastructure"
            fi
        else
            LOG "Error installing packages, check to proceed!"
        fi
        ;;
        -z | --pro) echo "Not create yet, please use -h or --help for help" ;;
        *) echo "Invalid option, please use -h or --help to help" && exit 1 ;;
    esac
    shift
done
