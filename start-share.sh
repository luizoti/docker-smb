#!/bin/bash

USER=$1
ACTION=$2


start(){
    sudo docker-compose -f "/home/${USER}/.docker-smb/docker-compose.yml" up -d
    if [[ "$?" -eq 0 ]]; then
        message="Container iniciado sem erros, use 'sudo journalctl -f' para ver detalhes!"
    else
        message="Não foi possivel iniciar o container use 'sudo journalctl -f' para ver detalhes!"
    fi
    logger "${message}"
}

stop(){
    id_to_stop=$(sudo docker ps | grep docker-smb-samba | cut -d " " -f1)
    
    if [[ -n "${id_to_stop}" ]]; then
        logger "docker-smb container id: ${id_to_stop}"
        sudo docker stop "${id_to_stop}" 2>/dev/null
    else
        logger "O container 'docker-smb-samba' parece não estar rodando, nada a ser feito!"
    fi  
}

case "${ACTION}" in
  "start")
    logger "Iniciando o container docker-smb!"
    start
    ;;
  "restart")
    logger "Reiniciando o container docker-smb!"
    stop
    start
    ;;
  "stop")
    logger "Parando o container docker-smb!"
    stop
    ;;
  *)
    echo "Opção invalida!"
    ;;
esac
