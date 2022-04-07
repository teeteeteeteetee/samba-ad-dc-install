#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi

repo=0

update_package(){
    apt update
}

install_package(){
    rm -rf /etc/krb5.conf 2> /dev/null
}

show_menu(){

    clear

    normal=`echo "\033[m"`
    menu=`echo "\033[1;31m"` #Blue
    number=`echo "\033[33m"` #yellow
    bgred=`echo "\033[41m"`
    fgred=`echo "\033[31m"`
    printf "\n${menu}—————————————————————————————————————————————${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 1)${menu} Install Samba AD DC ${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 2)${menu} Install Samba AD DC (Change hostname) ${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 3)${menu} Remove Samba AD DC ${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 4)${menu} Remove Samba AD DC (Full) ${normal}\n"
    printf "${menu}ᓚᘏᗢ${number} 5)${menu} Github Repository${normal}\n"
    printf "${menu}—————————————————————————————————————————————${normal}\n"
    printf "Please enter a menu option and enter or ${fgred}x to exit. ${normal}\n\n"
    printf "\033[4;33mMade by Tee\033[0m —ฅ/ᐠ. ̫ .ᐟ\ฅ — \n"

    if [ "$repo" -eq "1" ]; then
        printf "Repository:\033[1;32m https://github.com/lolitee/samba-ad-dc-install\n"
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
