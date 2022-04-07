#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi

repo=0

normal=`echo "\033[m"`
menu=`echo "\033[1;31m"` 
number=`echo "\033[33m"` 
bgred=`echo "\033[41m"`
fgred=`echo "\033[31m"`
green=`echo "\033[1;32m"`
yellow=`echo "\033[1;33m"`

update_package(){
    apt update
}

install_package(){
    printf "${yellow}Removing krb5.conf (if exists)\n${normal}"
    rm -rf /etc/krb5.conf 2> /dev/null
    printf "${yellow}Installing packages\n${normal}"
    apt install acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind libpam-krb5 krb5-config krb5-user dnsutils smbclient -y
    printf "${yellow}Disabling services and enabling samba active directory\n${normal}"
    systemctl disable --now smbd nmbd winbind
    systemctl mask smbd nmbd winbind
    systemctl unmask samba-ad-dc
}

remove_package(){
    rm -rf /etc/krb5.conf 2> /dev/null
    apt remove acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind libpam-krb5 krb5-config krb5-user dnsutils smbclient -y
}

show_menu(){

    clear

    printf "\n${menu}—————————————————————————————————————————————${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 1)${menu} Install Samba AD DC ${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 2)${menu} Install Samba AD DC (Change hostname) ${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 3)${menu} Remove Samba AD DC ${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 4)${menu} Remove Samba AD DC (With packages) ${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 5)${menu} Github Repository${normal}\n"
    printf "${menu}—————————————————————————————————————————————${normal}\n"
    printf "Please enter a menu option and enter or ${fgred}x to exit. ${normal}\n\n"
    printf "\033[4;33mMade by Tee${normal} —ฅ/ᐠ. ̫ .ᐟ\ฅ — \n"

    if [ "$repo" -eq "1" ]; then
        printf "Repository:${yellow} https://github.com/lolitee/samba-ad-dc-install\n"
        repo=0
    fi
    
    read -n 1 -p "" userinput

    case "${userinput}" in
        1)
            update_package
            install_package
            ;;
        2)
            update_package
            install_package
            ;;
        3)
            ;;
        4)
            remove_package
            ;;
        5)
            printf "\n"
            repo=1
            show_menu
            ;;
        x|X)
            clear
            exit;;
        *)
        show_menu
        ;;
    esac

}

show_menu
