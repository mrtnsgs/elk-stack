#!/bin/bash
##################################################################################################################################
# Script para executar toda instalação de forma automatizada dos pacotes necessários e toda ELK Stack
# em uma VM nova rodando Debian 10
# Autor: Guilherme Martins
##################################################################################################################################

## Adicionar logfile para instalação

DIRDESTINO='/tmp/elkStack'

installPkgs(){
    echo "Instalando pacotes necessários"
    apt-get -y update && apt-get -y upgrade && apt-get -y install curl vim git docker docker-compose

    echo "Ajustando memória da máquina virtual"
    sysctl -w vm.max_map_count=262144
}

cloneGit(){
    local REPO='https://github.com/elastic/stack-docker.git'

    if [[ -e $DIRDESTINO ]]; then
        echo "Diretório destino existe"
    else
        echo "Diretório destino não existe, criando..."
        mkdir $DIRDESTINO
    fi

    echo "Mudando diretório destino e clonando repositório..."
    cd $DIRDESTINO && git clone $REPO
}

installPkgs
cloneGit

if [[ $? -eq 0 ]]; then
    $DIRDESTINO/stack-docker/
    docker-compose -f setup.yml up
    #docker-compose -f docker-compose.yml -f docker-compose.setup.yml down --remove-orphans
else
    echo "Erro na instalação dos pacotes, verifique para proceder!"
fi
