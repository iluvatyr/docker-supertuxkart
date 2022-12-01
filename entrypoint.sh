#!/bin/bash
set -em
set -a
## Colors
export red="\e[0;91m"
export green="\e[0;92m"
export reset="\e[0m"

echo_green(){
    echo -e "${green}$1${reset}"
}
echo_red(){
    echo -e "${red}$1${reset}"
}

#Defaults of environment variables
export UPTIME_PUSH_PERIOD="${UPTIME_PUSH_PERIOD:-60}"
export UPTIME_PUSH_URL="${UPTIME_PUSH_URL:-}"
export STK_USERNAME="${STK_USERNAME:-}"
export STK_PASSWORD="${STK_PASSWORD:-}"
export STK_PORT="${STK_PORT:-2759}"
export STK_SERVER_CONF="${STK_SERVER_CONF:-"server-config.xml"}"
export STK_INSTALL_ADDONS="${STK_INSTALL_ADDONS:-"false"}"
export STK_AI_KARTS="${STK_AI_KARTS:-0}"
export STK_FIREWALLED="${STK_FIREWALLED:-"false"}"
#PGID, PUID

change_userid(){
    echo_green "Cleaning up user and group"
	deluser supertuxkart || true
	delgroup supertuxkart || true
    echo_green "Creating supertuxkart group with custom PGID"
    addgroup --gid "${PGID}" "${CGROUPNAME}"
    echo_green "Creating supertuxkart user with custom PUID"
    useradd -m -u "${PUID}" -s /bin/bash -k /etc/skell -g "${CGROUPNAME}" "${CUSERNAME}" || exit 3
    echo_green "Changing ownership of files so that stk can run under new user"
    chown -R "${CUSERNAME}:${CGROUPNAME}" /stk /usr/local/bin /usr/local/share/supertuxkart "/home/${CUSERNAME}"
}

revert_userid(){
    echo_green 'Reverting ownership of stk-files back to default PUID, PGID: 1337'
    chown -R "${CUSERNAME}:${CGROUPNAME}" /stk /usr/local/bin /usr/local/share/supertuxkart "/home/${CUSERNAME}"
}

## End of definitions

#RUN
# Write correct DNSentry to hosts file
STK_DNS_LOOKUP=$(dig +short online.supertuxkart.net)
echo "$STK_DNS_LOOKUP online.supertuxkart.net" >> /etc/hosts

if [ -n "${PUID}" ] && [ -n "${PGID}" ]
then
    change_userid
    exec runuser -u "${CUSERNAME}" -g "${CGROUPNAME}" /stk/start_stk.sh "$@"
else
    revert_userid
    exec runuser -u "${CUSERNAME}" -g "${CGROUPNAME}" /stk/start_stk.sh "$@"
fi


