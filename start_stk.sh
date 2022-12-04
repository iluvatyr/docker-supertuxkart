#!/bin/bash
set -em
echo_green(){
    echo -e "${green}$1${reset}"
}
echo_red(){
    echo -e "${red}$1${reset}"
}

stk_install_addons(){
    #Add support for installing all addons after server startup
    if ( /stk/install-all-addons.sh )
    then
        echo_green "Success: Installed addon tracks"
    else
        echo_red "Error: Could not install addon tracks"
    fi
}

stk_add_update_cronjob() {
    #Add support for automated daily updating of all addons after server startup within the container
    echo -e "${green}Adding cronjob for updating addon tracks daily @4:00am in the Timezone:${TZ}"
    crontabfile="/stk/crontab.txt"
    echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > $crontabfile
    echo "0 4 * * * /stk/update-addons.sh" >> $crontabfile
    crontab $crontabfile
}

stk_login(){
    # Log in with username and password if provided
    if ( supertuxkart --init-user --login=${STK_USERNAME} --password=${STK_PASSWORD} )
    then
        echo_green "Success: Logged in ${STK_USERNAME} into SuperTuxKart"
    else
        echo_red "Error: Could not log in, check password/Username"
        exit 1
    fi
}

stk_change_server_config(){
    # Change stk port
    if [ -z "$(cat "/stk/${STK_SERVER_CONF}" | grep -e "server-port value\=\"[0-9]*\"" | grep ${STK_PORT})" ]
    then
        echo_green "Changing port to ${STK_PORT}"
        cp "/stk/${STK_SERVER_CONF}" "/stk/tmp.xml"
        sed -i "s/server-port value\=\"[0-9]*\"/server-port value\=\"${STK_PORT}\"/" "/stk/tmp.xml"
        cp "/stk/tmp.xml" "/stk/${STK_SERVER_CONF}" && rm "/stk/tmp.xml"
    fi
    # Change firewall status
    if [ -z "$(cat "/stk/${STK_SERVER_CONF}" | grep -e "firewalled-server value\=\".*\"" | grep ${STK_FIREWALLED})" ]
    then
        echo_green "Changing Firewall status to ${STK_FIREWALLED}"
        cp "/stk/${STK_SERVER_CONF}" "/stk/tmp.xml"
        sed -i "s/firewalled-server value\=\".*\"/firewalled-server value\=\"${STK_FIREWALLED}\"/" "/stk/tmp.xml"
        cp "/stk/tmp.xml" "/stk/${STK_SERVER_CONF}" && rm "/stk/tmp.xml"
    fi
    # Change server name
    if [ -n "${STK_SERVER_NAME}" ]
    then
        echo "Changing ServerName to \"${STK_SERVER_NAME}\""
        cp "/stk/${STK_SERVER_CONF}" "/stk/tmp.xml"
        sed -i "s/server-name value\=\".*\"/server-name value\=\"${STK_SERVER_NAME}\"/" "/stk/tmp.xml"
        cp "/stk/tmp.xml" "/stk/${STK_SERVER_CONF}" && rm "/stk/tmp.xml"
    fi
}

stk_start_server(){
    # Start stk server in background
    exec supertuxkart --server-config=${STK_SERVER_CONF} 2>&1 & "$@"
    if [ $? -eq 0 ]
    then
        echo_green "Success: Started server"
    else
        echo_red "Error: Could not start server"
        exit 1
    fi
}

stk_add_ai(){
    # Add ai kart background process when AI-Karts are specified
    SERVER_PASSWORD=$(cat ${STK_SERVER_CONF} | grep private-server-password | awk -F '"' '{print $2}')
    exec supertuxkart --connect-now=127.0.0.1:${STK_PORT} --server-password=$SERVER_PASSWORD --network-ai=${STK_AI_KARTS} & "$@"
    if [ $? -eq 0 ]
    then
        echo_green "Success:Added ${STK_AI_KARTS} AI-Karts"
    else
        echo_red "Error: could not add AI-Karts"
    fi
}

push_url(){
    # Run if UPTIME_PUSH_URL is set
    echo_green "UPTIME_PUSH_URL: ${UPTIME_PUSH_URL}" 
    echo_green "UPTIME_PUSH_PERIOD: ${UPTIME_PUSH_PERIOD} seconds between each ping"
    while true; do info=$(curl -s --connect-timeout 1 --max-time 2 -I "${UPTIME_PUSH_URL}") && sleep "${UPTIME_PUSH_PERIOD}"; done &
}

## Run following startup sequence
if ( ${STK_INSTALL_ADDONS} ); then stk_install_addons; fi
if ( ${STK_UPDATE_ADDONS} ); then stk_add_update_cronjob; fi
if [ -n "${STK_USERNAME}" ] && [ -n "${STK_PASSWORD}" ]
then stk_login
else
    echo_red "Error: No Username and password set, please set the regarding environment variables USERNAME and PASSWORD and restart container"
    sleep infinity
fi
stk_change_server_config
stk_start_server
if [ ! "${STK_AI_KARTS}" -eq "0" ];then stk_add_ai; fi
if [ -n "${UPTIME_PUSH_URL}" ]; then push_url; fi
# Bring server process back into foreground
fg %1
