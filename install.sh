#!/bin/bash

repo=0
ip=$(hostname -I | awk '{print $1}')
mode=0

reset=`echo "\033[m"`
menu=`echo "\033[1;31m"` 
red=`echo "\033[1;31m"`
number=`echo "\033[33m"` 
purple=`echo "\033[35m"` 
bgred=`echo "\033[41m"`
fgred=`echo "\033[31m"`
green=`echo "\033[1;32m"`
yellow=`echo "\033[1;33m"`

if [[ $EUID -ne 0 ]]; then
  printf "* ${menu}This script must be executed with root privileges (sudo).\n${reset}" 1>&2
  exit 1
fi

exit_ln(){
    printf "\n${reset}"
    exit
}

update_package(){
    apt update
}

remove(){
    rm -rf /etc/krb5.conf
    rm -rf /etc/samba/smb.conf
}

remove_package(){
    remove
    apt remove samba -y
    apt autoremove -y
}

install_package(){
    printf "${yellow}Removing krb5.conf and smb.conf (if exists) ᓚᘏᗢ\n${reset}"
    remove
    printf "${yellow}Installing packages ᓚᘏᗢ\n${reset}"
    apt install acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind libpam-krb5 krb5-config krb5-user dnsutils smbclient -y
    printf "${yellow}Disabling services and enabling samba active directory ᓚᘏᗢ\n${reset}"
    systemctl disable --now smbd nmbd winbind
    systemctl mask smbd nmbd winbind
    systemctl unmask samba-ad-dc

    while true
    do

        printf "\n${yellow}Please enter your static ip (${ip}): ${reset}"
        ip_original=$ip
        read ip
        while ! [[ $ip =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]];
        do  
            if [[ -z $ip ]]
            then 
                ip=$ip_original
                break
            fi
            ip=$ip_original
            printf "${red}Invalid ip address!\n"
            printf "${yellow}Please enter your static ip (${ip}): ${reset}"
            read ip
        done

        printf "${yellow}Configured ${reset}${ip}${yellow} as static ip address \n${reset}"

        printf "\n${yellow}Please enter your dns resolver (1.1.1.1): ${reset}"
        read dns
        while ! [[ $dns =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]];
        do  
            if [[ -z $dns ]]
            then 
                dns="1.1.1.1"
                break
            fi
            printf "${red}Invalid DNS address!\n"
            printf "${yellow}Please enter your dns resolver (1.1.1.1): ${reset}"
            read ip
        done

        printf "${yellow}Configured ${reset}${dns}${yellow} as DNS \n${reset}"

        printf "\n${yellow}Please enter your domain name. ${red}Do not use \".local\"${yellow}: ${reset}"
        read domain
        while ! [[ $domain =~ ([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$ ]];
        do
            domain=""
            printf "${red}Invalid domain name!\n"
            printf "\n${yellow}Please enter your domain name. ${red}Do not use \".local\"${yellow}: ${reset}"
            read domain
        done

            printf "${yellow}Configured ${reset}${domain}${yellow} as domain name \n${reset}"

            printf "${menu}—————————————————————————————————————————————\n${reset}"
            printf "${yellow}Static ip: ${reset}${ip}\n"
            printf "DNS: ${reset}${dns}\n"
            printf "Domain name: ${reset}${domain}\n\n"
            printf "${red}Please double check the config\n"
            printf "if anything goes wrong, \nit would be really annoying to fix..\n${reset}"
            printf "${menu}—————————————————————————————————————————————\n${reset}"
            read -n 1 -p "Is this correct? (Y/N): " yn

            if [ "$yn" == "y" ] || [ "$yn" == "Y" ]
            then
                break
            fi

        read confirm
    done

    while true
    do
        printf "\n${yellow}
                - at least 7 characters long\n
                - has at least one digit\n
                - has at least one Upper case Alphabet\n
                - has at least one Lower case Alphabet${reset}
            "
        printf "\n${yellow}Please enter your password for administrator (hidden): ${reset}\n"
        read -s password
        while true
        do
            FAIL=no
            echo $password | grep -oP "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d_@.#&+-]{8,}$" > /dev/null || FAIL=yes

            if [[ ${FAIL} == "no" ]]
            then
                break
            fi

            printf "${red}Your password doesn't meet the minimal requirement!\n"
            printf "\n${yellow}Please enter your password for administrator (hidden): ${reset}\n"
            read -s password
        done

        printf "\n${yellow}Confirm your password: ${reset}\n"
        read -s password2
        while true
        do
            FAIL=no
            echo $password2 | grep -oP "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d_@.#&+-]{8,}$" > /dev/null || FAIL=yes

            if [[ ${FAIL} == "no" ]]
            then
                break
            fi

            printf "${red}Your password doesn't meet the minimal requirement!\n"
            printf "\n${yellow}Please enter your password for administrator (hidden): ${reset}\n"
            read -s password2
        done

        if [ $password == $password2 ]
        then
            break
        fi

        printf "${red}Password doesn't match!\n"

    done

    printf "\n${yellow}Adding to hosts ᓚᘏᗢ\n${reset}"

    filtered_domain=$(echo ${domain} | grep -oP '(?<=^)[^.]+')
    echo "${ip}  ${domain} ${filtered_domain} " >> /etc/hosts

    printf "\n${yellow}Creating domain controller ᓚᘏᗢ\n${reset}"
    
    samba-tool domain provision --server-role=dc --use-rfc2307 --dns-backend=SAMBA_INTERNAL --realm=${domain} --domain=${filtered_domain} --adminpass=${password}
    
    systemctl start samba-ad-dc

    printf "\n${yellow}Finalizing ᓚᘏᗢ\n${reset}"
    printf "\n${yellow}Thank you for using my script.\n${reset}"

}

show_menu(){

    clear

    printf "\n${menu}—————————————————————————————————————————————${reset}\n"

    printf "${purple} __                 _               _        _   _                ___ _               _                   
/ _\ __ _ _ __ ___ | |__   __ _    /_\   ___| |_(_)_   _____     /   (_)_ __ ___  ___| |_ ___  _ __ _   _ 
\ \ / _\` | '_ \` _ \| '_ \ / _\` |  //_\\\\\ / __| __| \ \ / / _ \   / /\ / | '__/ _ \/ __| __/ _ \| '__| | | |
_\ \ (_| | | | | | | |_) | (_| | /  _  \ (__| |_| |\ V /  __/  / /_//| | | |  __/ (__| || (_) | |  | |_| |
\__/\__,_|_| |_| |_|_.__/ \__,_| \_/ \_/\___|\__|_| \_/ \___| /___,' |_|_|  \___|\___|\__\___/|_|   \__, |
                                                                                                    |___/ ┛"

    printf "\n  ${menu}ᓚᘏᗢ${number} 1)${menu} Install Samba AD DC ${reset}\n"
    printf "  ${menu}ᓚᘏᗢ${number} 2)${menu} Install Samba AD DC (Change hostname / may cause some issues related to /etc/hosts) ${reset}\n"
    printf "  ${menu}ᓚᘏᗢ${number} 3)${menu} Remove Samba AD DC ${reset}\n"
    printf "  ${menu}ᓚᘏᗢ${number} 4)${menu} Remove Samba AD DC (With packages) ${reset}\n"
    printf "  ${menu}ᓚᘏᗢ${number} 5)${menu} Github Repository${reset}\n\n"
    printf "${menu}Do not escape out of the script during installation, \nit may cause lots of trouble!!${reset}\n"
    printf "${menu}I'm not responsible for any of the damage.${reset}\n"
    printf "${menu}—————————————————————————————————————————————${reset}\n"
    printf "Please enter a menu option and enter or ${fgred}x to exit. ${reset}\n\n"
    printf "\033[4;33mMade by Tee${reset} —ฅ/ᐠ. ̫ .ᐟ\ฅ — \n"

    if [ "$repo" -eq "1" ]; then
        printf "Repository:${yellow} https://github.com/lolitee/samba-ad-dc-install\n"
        repo=0
    fi
    
    read -n 1 -p "" userinput

    case "${userinput}" in
        1)
            printf "\n"
            read -n 1 -p "This will remove your current settings. Are you sure about that? (Y/N): " yn
            if [ "$yn" != "y" ] && [ "$yn" != "Y" ]
            then
                show_menu
            fi
                update_package
                install_package
            ;;
        2)
            printf "\n"
            read -n 1 -p "This will remove your current settings. Are you sure about that? (Y/N): " yn
            if [ "$yn" != "y" ] && [ "$yn" != "Y" ]
            then
                show_menu
            fi

            printf "\n${yellow}Please enter your new hostname (dc1): ${reset} "
            read hst
            if [ -n "$hst" ]
            then
                read -n 1 -p "This will be your current hostname (${hst}). Are you sure about that? (Y/N): " yn
                    if [ "$yn" != "y" ] && [ "$yn" != "Y" ]
                    then
                        show_menu
                    fi
                    
                    hostnamectl set-hostname $hst
                    update_package
                    install_package
            else
                read -n 1 -p "This will be your current hostname (dc1). Are you sure about that? (Y/N): " yn
                    if [ "$yn" != "y" ] && [ "$yn" != "Y" ]
                    then
                        show_menu
                    fi
                        
                    hostnamectl set-hostname dc1
                    update_package
                    install_package
            fi
            
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
            exit_ln
            ;;
        *)
        show_menu
        ;;
    esac

}

show_menu
