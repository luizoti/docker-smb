#!/bin/bash
# https://github.com/fschuindt/docker-smb
# https://stackoverflow.com/questions/28721699/root-password-inside-a-docker-container
# https://stackoverflow.com/questions/43671482/how-to-run-docker-compose-up-d-at-system-start-up

USERNAME=$(id -un 1000)
CLONE_DIR=/home/${USERNAME}/.docker-smb

# function update () {
#   sudo apt-get update 
#   sudo apt-get upgrade -y
# }

# if [[ ! $(which curl) ]]; then
#   sudo apt install curl -y
# fi

# if [[ ! $(which git) ]]; then
#   sudo apt install git -y
# fi

# if [[ ! -d "${CLONE_DIR}" ]]; then
#   git clone https://github.com/luizoti/docker-smb.git "${CLONE_DIR}"
#   echo
#   cd "${CLONE_DIR}"
# fi

if [[ ! $(which docker-compose) ]]; then
    echo
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo " #                           docker-compose instalation                                # "
    echo " #                                                                                     # "
    echo " #                           Instalation based in docs                                 # "
    echo " #                     https://docs.docker.com/compose/install/                        # "
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "

    # python-dev-is-python2 >>>> python-dev
    # libc6-dev >>>>>>>>>>>>>>>> libc-dev
    # openssl  >>>>>>>>>>>>>>>>  openssl-dev
    # python3-pip >>>>>>>>>>>>>>>> py-pip

    GIT_API="https://api.github.com"
    COMPOSE_PATH="/usr/local/bin/docker-compose"
    VERSION_FILE="docker-compose-$(uname -s)-$(uname -m)"
    PART_DOWNLOAD_URL="https://github.com/docker/compose/releases/download"
    REPO="docker/compose"

    get_latest_release() {
        curl --silent "https://api.github.com/repos/$1/releases/latest" | 
        tr -d , | 
        grep "tag_name" | 
        awk '{ print $2 }' | 
        tr -d '"'
    }

    COMPOSE_URL="${PART_DOWNLOAD_URL}/$(get_latest_release ${REPO})/${VERSION_FILE}"
    
    echo
    echo "Compose version: $(get_latest_release "docker/compose")"
    echo "Compose file   : ${VERSION_FILE}"
    echo "Comsole URL    : ${COMPOSE_URL}"
    echo "Download dir   : ${COMPOSE_PATH}"
    echo
    sudo curl -L "${COMPOSE_URL}" -o "${COMPOSE_PATH}"
    sleep 2

    if [[ $(which docker-compose) ]]; then
        echo
        sudo apt install python3-pip python-dev-is-python2 libffi-dev openssl gcc libc6-dev make -y
        sudo chmod +x "${COMPOSE_PATH}"
        sudo ln -s "${COMPOSE_PATH}" "/usr/bin/docker-compose"
    fi
fi

if [[ ! $(which docker) ]]; then
    echo
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo " #                           docker engine instalation                                 # "
    echo " #                                                                                     # "
    echo " #                           Instalation based in docs                                 # "
    echo " #                     https://docs.docker.com/engine/install/                         # "
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "

    sudo apt-get update
    sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
    # 
    echo
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    # 
    echo
    sudo apt-key fingerprint 0EBFCD88
    # 
    echo
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    # 
    echo
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y
fi

function change_hostname () {
  if [[ -f "${CLONE_DIR}/docker-compose.yml" ]]; then
      sed -i "s/hostname: .*/hostname: $(hostname)/g" "${CLONE_DIR}/docker-compose.yml"
  fi

  if [[ -f "${CLONE_DIR}/smb.conf" ]]; then
      sed -i "s/netbios name = .*/netbios name = $(hostname)/g" "${CLONE_DIR}/smb.conf"
  fi
}

# function change_smbuser () {
#   if [[ -f ${CLONE_DIR}/smb.conf ]]; then
#       sed -i "s/force user = .*/force user = ${USERNAME}/g" ${CLONE_DIR}/smb.conf
#   fi
# }

# function change_userpass () {
#   if [[ -f ${CLONE_DIR}/Dockerfile ]]; then
#       VARS=$(cat ./Dockerfile | grep ARG | sed "s/ARG//g")

#       for VAR in ${VARS}; do
#           if [[ ${VAR} == *"USER"* ]]; then
#               sed -i "s/USER='.*'/USER='${USERNAME}'/g" ${CLONE_DIR}/Dockerfile
#           fi

#           if [[ ${VAR} == *"PASS"* ]]; then
#               echo
#               echo "Insira uma senha para o usuario do sistema e SMB:"
#               read -s NEWPASS
#               sed -i "s/PASS='.*'/PASS='${NEWPASS}'/g" ${CLONE_DIR}/Dockerfile
#           fi
#       done
#   fi
# }

# function smbcfg () {
#   SMBCFG='/etc/samba/smb.conf'
#   if [[ -f ${SMBCFG} ]]; then
#       echo
#       read -p "Copiar e usar a configuração contida em: ${SMBCFG} (y/n)? " CHOICE

#       case "${CHOICE}" in 
#         y|Y )
#           if cp ${SMBCFG} ${CLONE_DIR}/smb.conf; then
#               echo "  Configuração de ${SMBCFG}, copiada!"
#           else
#               echo "  Erro ao copiar ${SMBCFG} para ${CLONE_DIR}/smb.conf!"
#           fi
#           ;;
#         n|N )
#           echo "  Será usada a configuração do repositorio!"
#           ;;
#         * ) 
#           echo "  Invalid."
#           smbcfg
#           ;;
#       esac
#   fi
# }

# function build () {
    
#   if [[ ${PWD} == ${CLONE_DIR} ]]; then
#       sudo docker-compose build
#   fi

#   SERVICE='/etc/systemd/system/docker-smb.service'

#   echo -e "[Unit]
# Description=Docker Samba Service
# Requires=docker.service
# After=docker.service

# [Service]
# Type=oneshot
# RemainAfterExit=yes
# WorkingDirectory=${CLONE_DIR}
# ExecStart=/usr/bin/sudo /usr/local/bin/docker-compose up -d
# ExecStop=/usr/bin/sudo /usr/local/bin/docker-compose down
# TimeoutStartSec=0

# [Install]
# WantedBy=multi-user.target" > ${SERVICE}

#   if [[ -f ${SERVICE} ]]; then
#       sudo systemctl daemon-reload
#       sudo systemctl enable docker-smb.service
#       sudo systemctl restart docker-smb.service
#   fi
# }

# function waitedit () {
#   echo
#   echo
#   echo 'PARA FINALIZAR O PROCESSO VOCÊ PRECISA EDITAR OS "COMPARTILHAMENTOS SMB" E OS "VOLUMES" NOS AQUIVOS:'
#   echo '  docker-compose.yml'
#   echo '  smb.conf'
#   echo 
#   read -p "Ao finalizar, presione Y para continuar ou N para sair (y/n)" EDITCHOICE

#   case "${EDITCHOICE}" in 
#     y|Y )
#       echo
#       build
#       ;;
#     n|N )
#       echo
#       echo "Saindo, processo não finalizado."
#       ;;
#   esac
# }

# case $1 in
#   -a|-A|--auto )
#       update
#       echo "Essa opção é para instalação sem perguntas!"
#       build
#       ;;
#   -h|-H|--help )
#       echo ""
#       echo "-i, -I, --install - Inicia a instalação"
#       echo "-a, -A, --auto    - Instalação silenciosa caso as configurções estejam prontas." 
#       ;;
#   -i|-I|--install )
#       update
#       change_hostname
#       change_smbuser
#       change_userpass
#       smbcfg
#       waitedit
#       ;;
# esac
