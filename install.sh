#!/bin/bash
#
# Author : Denis REMACLE, Amad MOHAMMAD
# Year : 2021
# License : GPLv3
# 

# set -e
# set -x
clear

function install_utils
{
        apt update && apt upgrade -y
        apt install vim sudo rsync git net-tools mlocate htop screen figlet curl -y
}

function install_cheat
{
	# Téléchargement de cheat
	wget https://github.com/cheat/cheat/releases/download/4.2.3/cheat-linux-amd64.gz

	# Décompresser le programme
	gunzip cheat-linux-amd64.gz

	# Autoriser l'exécution à tout les utilisateurs
	chmod a+x cheat-linux-amd64

	# Déplacer le programme vers /usr/local/bin/
	mv -v cheat-linux-amd64 /usr/local/bin/cheat
}

function uninstall_cheat
{
	rm -f /usr/local/bin/cheat
}

function create_dirs
{
	# Créer les dossiers pour la conf
	mkdir -vp /opt/COMMUN/cheat/cheatsheets/community
	mkdir -v /opt/COMMUN/cheat/cheatsheets/personal
}

function configure_cheat
{
	# Générer la conf pour le script dans le bon fichier
	cheat --init > /opt/COMMUN/cheat/conf.yml

	# Changer le path de la conf générée
	sed -i 's;/root/.config/; /opt/COMMUN/;' /opt/COMMUN/cheat/conf.yml
}

function install_cheatsheets
{
	# télécharger les cheatsheets
	git clone https://github.com/cheat/cheatsheets.git

	# Les déplacer dans le dossier créé précédement
	mv -v cheatsheets/* /opt/COMMUN/cheat/cheatsheets/community
}

function config_dir_making
{
	# Créer les dossier .config chez root et /etc/skel
	mkdir -v /root/.config/
	mkdir -v /etc/skel/.config/
	make_root_bashrc
	make_skel_bashrc
}

function make_root_bashrc
{
	echo "umask 007" >> /root/.bashrc
	cat >> /root/.bashrc << EOF
export PS1="\[\033[38;5;1m\]\n[\t] \u@\h \w\n\\$ :\[$(tput sgr0)\] \[$(tput sgr0)\]"
alias ll='ls -rtl'
alias la='ls -lsa'
alias rm='rm -Iv --preserve-root'
alias chown="chown -v --preserve-root"
alias chmod="chmod -v --preserve-root"
alias chgrp="chgrp -v --preserve-root"
alias su="su - "
alias hs='history|grep -i '
EOF
}

function make_skel_bashrc
{
	echo "umask 007" >> /etc/skel/.bashrc
	cat >> /etc/skel/.bashrc << EOF
export PS1="\[\033[38;5;14m\]\n[\t]\u@\h \w\n\\$ :\[$(tput sgr0)\] \[$(tput sgr0)\]"
alias ll='ls -rtl'
alias la='ls -lsa'
alias rm='rm -Iv --preserve-root'
alias chown="chown -v --preserve-root"
alias chmod="chmod -v --preserve-root"
alias chgrp="chgrp -v --preserve-root"
alias su="su - "
alias hs='history|grep -i '
EOF
}

function make_user_bashrc
{
	echo "umask 007" >> /home/$1/.bashrc
	cat >> /home/$1/.bashrc << EOF
export PS1="\[\033[38;5;14m\]\n[\t]\u@\h \w\n\\$ :\[$(tput sgr0)\] \[$(tput sgr0)\]"
alias ll='ls -rtl'
alias la='ls -lsa'
alias rm='rm -Iv --preserve-root'
alias chown="chown -v --preserve-root"
alias chmod="chmod -v --preserve-root"
alias chgrp="chgrp -v --preserve-root"
alias su="su - "
alias hs='history|grep -i '
EOF
}

function group_create
{
	# Créer un groupe commun pour les droits sur les cheatsheets
	groupadd -g 10000 commun
	chgrp -Rv commun /opt/COMMUN
	chmod -Rv 2770 /opt/COMMUN/cheat/cheatsheets/personal
}

function config_linking
{
	# Créer les liens symboliques pour les utilisateurs
	ln -vs /opt/COMMUN/cheat /root/.config/cheat
	ln -vs /opt/COMMUN/cheat /etc/skel/.config/cheat

	# Défini bash comme shell par défaut
	rm /bin/sh
	ln -vs /bin/bash /bin/sh

	# Récupérer une liste des utilisateur "legité
	users=($(grep '/bin/bash' /etc/passwd | awk -F : '{print $1}'))

	# Dans une boucle créer le dossier .config faire le lien symbolique et un ajouts aux groupes
	# Pour chaque utilisateurs sauf root
	for user in "${users[@]}"; do
		if [ $user != "root" ];
		then
			usermod -a -G commun $user
			usermod -a -G sudo $user
			mkdir /home/$user/.config
			ln -vs /opt/COMMUN/cheat /home/$user/.config/cheat
			chown -R $user /home/$user/.config
			make_user_bashrc $user
		fi
	done
}

function password_generator
{
	# génère un mot de passe de 10 charactères
	password=$(< /dev/urandom tr -dc a-zA-Z0-9 | head -c10)
	echo $1":"$password >> passwords
}

function create_users
{
	# Créé un utilisateur
	useradd -G sudo,commun -s /bin/bash --create-home $1
	password_generator $1
	yes $password | passwd $1
}

function banner_install
{
	# Créé un motd
	rm /etc/motd
	rm /etc/update-motd.d/*
	echo "#!/bin/sh" >> /etc/profile.d/mymotd.sh
	echo "hostname | figlet" >> /etc/profile.d/mymotd.sh
	echo "cat /etc/mymotd" >> /etc/profile.d/mymotd.sh
	cat >> /etc/mymotd << EOF
Hello dear user,

You may use this server responsibly and be mindful of the commands type.
Or there will be trouble !

Cheerfully,
Your system administrator

EOF
	echo "who -H" >> /etc/profile.d/mymotd.sh
	chmod 744 /etc/mymotd
	chmod +x /etc/profile.d/mymotd.sh
}

echo "Installing utils"
echo "__________________________"
install_utils
sleep 5
clear

echo "Installing cheat"
echo "__________________________"
install_cheat
sleep 5
clear

echo "Creating directories"
echo "__________________________"
create_dirs
sleep 5
clear

echo "Configuring cheat"
echo "__________________________"
configure_cheat
sleep 5
clear

echo "Installing cheatsheets"
echo "__________________________"
install_cheatsheets
sleep 5
clear

echo "Making .config directories"
echo "__________________________"
config_dir_making
sleep 5
clear

echo "Creating group commun"
echo "__________________________"
group_create
sleep 5
clear

echo "Linking configurations"
echo "__________________________"
config_linking
sleep 5
clear

echo "Installing motd"
echo "__________________________"
banner_install
sleep 5
clear

if  [ $# -gt 0 ]; then
	echo "Creating users"
	echo "__________________________"
	for user in "$@"; do
		create_users $user
	done
	sleep 5
	clear
fi
