#!/bin/bash
# https://github.com/fschuindt/docker-smb
# https://stackoverflow.com/questions/28721699/root-password-inside-a-docker-container
# https://stackoverflow.com/questions/43671482/how-to-run-docker-compose-up-d-at-system-start-up

USERNAME=$(id -un 1000)
CLONE_DIR=/home/${USERNAME}/.docker-smb


function update () {
	sudo apt-get update 
	sudo apt-get upgrade
}

if [[ ! $(which curl) ]]; then
	sudo apt install curl -y
fi

if [[ ! $(which git) ]]; then
	sudo apt install git -y
fi

if [[ ! -d ${CLONE_DIR} ]]; then
	git clone https://github.com/luizoti/docker-smb.git ${CLONE_DIR}
	echo
fi

cd ${CLONE_DIR}

if [[ ! $(which docker-compose) ]]; then
	# Instalação do docker-compose
	# Instalação baseada em: https://docs.docker.com/compose/install/

 	# python-dev-is-python2 >>>> python-dev
 	# libc6-dev >>>>>>>>>>>>>>>> libc-dev
 	# openssl  >>>>>>>>>>>>>>>>  openssl-dev
 	# python3-pip >>>>>>>>>>>>>>>> py-pip

	echo
	sudo apt install python3-pip python-dev-is-python2 libffi-dev openssl gcc libc6-dev make -y
	# 
	echo
	sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	# 
	echo
	sudo chmod +x /usr/local/bin/docker-compose
	# 
	echo
	sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
	# 
fi

if [[ ! $(which docker) ]]; then
	# Instalação do docker engine
	# Instalação baseada em: https://docs.docker.com/engine/install/
	echo
	sudo apt-get update
	sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
	# 
	echo
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	# 
	echo
	sudo apt-key fingerprint 0EBFCD88
	# 
	echo
	sudo add-apt-repository	"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	# 
	echo
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io -y
fi


function change_hostname () {
	if [[ -f ${CLONE_DIR}/docker-compose.yml ]]; then
		sed -i "s/hostname: .*/hostname: $(hostname)/g" ${CLONE_DIR}/docker-compose.yml
	fi

	if [[ -f ${CLONE_DIR}/smb.conf ]]; then
		sed -i "s/netbios name = .*/netbios name = $(hostname)/g" ${CLONE_DIR}/smb.conf
	fi
}

function change_smbuser () {
	if [[ -f ${CLONE_DIR}/smb.conf ]]; then
		sed -i "s/force user = .*/force user = ${USERNAME}/g" ${CLONE_DIR}/smb.conf
	fi
}

function change_userpass () {
	if [[ -f ${CLONE_DIR}/Dockerfile ]]; then
		VARS=$(cat ./Dockerfile | grep ARG | sed "s/ARG//g")

		for VAR in ${VARS}; do
			if [[ ${VAR} == *"USER"* ]]; then
				sed -i "s/USER='.*'/USER='${USERNAME}'/g" ${CLONE_DIR}/Dockerfile
			fi

			if [[ ${VAR} == *"PASS"* ]]; then
				echo "Insira uma senha para o usuario do sistema e SMB:"
				read -s NEWPASS
				sed -i "s/PASS='.*'/PASS='${NEWPASS}'/g" ${CLONE_DIR}/Dockerfile
			fi
		done
	fi
}

function smbcfg () {
	SMBCFG='/etc/samba/smb.conf'
	if [[ -f ${SMBCFG} ]]; then
		read -p "Copiar e usar a configuração contida em: ${SMBCFG} (y/n)? " CHOICE

		case "${CHOICE}" in 
		  y|Y )
			if cp ${SMBCFG} ${CLONE_DIR}/smb.conf; then
				echo "Configuração de ${SMBCFG}, copiada!"
			else
				echo "Erro ao copiar ${SMBCFG} para ${CLONE_DIR}/smb.conf!"
			fi
			;;
		  n|N )
			echo "Será usada a configuração do repositorio!"
			;;
		  * ) 
			echo "Invalid."
			;;
		esac
	fi
}

function build () {
	
	if [[ ${PWD} == ${CLONE_DIR} ]]; then
		sudo docker-compose build
	fi

	SERVICE='/etc/systemd/system/docker-smb.service'

	echo -e "[Unit]
Description=Docker Samba Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${CLONE_DIR}
ExecStart=/usr/bin/sudo /usr/local/bin/docker-compose up -d
ExecStop=/usr/bin/sudo /usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target" > ${SERVICE}

	if [[ -f ${SERVICE} ]]; then
		sudo systemctl daemon-reload
		sudo systemctl enable docker-smb.service
		sudo systemctl restart docker-smb.service
	fi
}


case $1 in
	-a|-A|--auto )
		update
		echo "Essa opção é para instalação sem perguntas!"
		build
		;;
	-h|-H|--help )
		echo ""
		echo "-i, -I, --install - Inicia a instalação"
		echo "-a, -A, --auto    - Instalação silenciosa caso as configurções estejam prontas." 
		;;
	-i|-I|--install )
		update
		change_hostname
		change_smbuser
		change_userpass
		smbcfg
		build
		;;
esac
