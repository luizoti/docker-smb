#!/bin/bash
# https://github.com/fschuindt/docker-smb
# https://stackoverflow.com/questions/28721699/root-password-inside-a-docker-container
# https://stackoverflow.com/questions/43671482/how-to-run-docker-compose-up-d-at-system-start-up

USERNAME=$(id -un 1000)
CLONE_DIR=/home/${USERNAME}/.docker-smb

CLONE_SMB_CONF="${CLONE_DIR}/smb.conf"
CLONE_COMPOSE_CONF="${CLONE_DIR}/docker-compose.yml"
CLONE_DOCKER_FILE="${CLONE_DIR}/Dockerfile"

function update() {
  sudo apt-get update 
  sudo apt-get upgrade -y
}

if [[ ! $(which curl) ]]; then
  sudo apt install curl -y
fi

if [[ ! $(which git) ]]; then
  sudo apt install git -y
fi

if [[ ! -d "${CLONE_DIR}" ]]; then
    clear
    echo
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo " #                           Cloning docker-smb Repository                             # "
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    git clone https://github.com/luizoti/docker-smb.git "${CLONE_DIR}"
    echo
    cd "${CLONE_DIR}"
fi

if [[ ! $(which docker-compose) ]]; then
    clear
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
    clear
    echo
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo " #                           docker engine instalation                                 # "
    echo " #                                                                                     # "
    echo " #                           Instalation based in docs                                 # "
    echo " #                     https://docs.docker.com/engine/install/                         # "
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo
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
    clear
    echo
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo " #                              Changing Hostname                                      # "
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    if [[ -f "${CLONE_COMPOSE_CONF}" ]]; then
        sed -i "s/hostname: .*/hostname: $(hostname)/g" "${CLONE_COMPOSE_CONF}"
    fi

    if [[ -f "${CLONE_SMB_CONF}" ]]; then
        sed -i "s/netbios name = .*/netbios name = $(hostname)/g" "${CLONE_COMPOSE_CONF}"
    fi
}

function change_smbuser () {
    clear
    echo
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo " #                            Changing smbconf user                                    # "
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "

    if [[ -f "${CLONE_SMB_CONF}" ]]; then
        sed -i "s/force user = .*/force user = ${USERNAME}/g" "${CLONE_SMB_CONF}"
    fi
}

function change_userpass () {
    clear
    echo
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo " #                             Changing smbconf pass                                   # "
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "

    if [[ -f "${CLONE_DOCKER_FILE}" ]]; then
        VARS=$(cat "${CLONE_DOCKER_FILE}" | grep ARG | sed "s/ARG//g")

        for VAR in ${VARS}; do
            if [[ "${VAR}" == *"USER"* ]]; then
                sed -i "s/USER='.*'/USER='${USERNAME}'/g" "${CLONE_DOCKER_FILE}"
            fi
            
            if [[ "${VAR}" == *"PASS"* ]]; then
                echo
                read -p "Enter a password for the system and SMB user: " -s NEWPASS
                sed -i "s/PASS='.*'/PASS='${NEWPASS}'/g" "${CLONE_DOCKER_FILE}"
            fi
        done
    fi
}

function build () {
    clear
    echo
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "
    echo " #                          Start Docker Compose Build                                 # "
    echo " # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # "

    if [[ "${PWD}" == "${CLONE_DIR}" ]]; then
        sudo docker-compose build
    fi

    SERVICE='/etc/systemd/system/docker-smb.service'

    echo -e "[Unit]
Description=Docker Samba Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
User=root
Group=root
RemainAfterExit=yes
ExecStart=/bin/sudo /home/${USERNAME}/.docker-smb/start-share.sh ${USERNAME} start
ExecRestart=/bin/sudo /home/${USERNAME}/.docker-smb/start-share.sh ${USERNAME} restart
ExecStop=/bin/sudo /home/${USERNAME}/.docker-smb/start-share.sh ${USERNAME} stop
TimeoutStartSec=5

[Install]
WantedBy=multi-user.target" > "${SERVICE}"

    if [[ -f "${SERVICE}" ]]; then
        echo
        echo "  The service ${SERVICE} was created!"
        echo
        sudo systemctl daemon-reload
        sudo systemctl enable docker-smb.service
        sudo systemctl restart docker-smb.service
    fi
}

function waitedit () {
    clear
    echo
    echo "TO FINISH THE PROCESS YOU NEED TO EDIT THE "SMB SHARES" AND "VOLUMES" IN THE FILES:"
    echo "    ${CLONE_COMPOSE_CONF}"
    echo "    ${CLONE_SMB_CONF}"
    echo 
    read -p "When finished, press Y to continue or N to exit (y/n): " EDITCHOICE

    case "${EDITCHOICE}" in 
        y|Y )
            echo
            build
        ;;
        n|N )
            echo
            echo "Leaving, process not finished."
        ;;
    esac
}

case $1 in
    -a|-A|--auto )
        update
        echo "This is the silent installation option!"
        build
    ;;
    -h|-H|--help )
        echo ""
        echo "-i, -I, --install - Start the installation."
        echo "-a, -A, --auto    - Silent installation (only if the files are already ready)" 
    ;;
    -i|-I|--install )
        update
        change_hostname
        change_smbuser
        change_userpass
        waitedit
    ;;
esac