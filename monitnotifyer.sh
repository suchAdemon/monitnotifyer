#!/bin/bash
scrpa="$(/usr/bin/dirname ${0})"
monitnotifymbox="/var/mail/monitnotify"
mailfullmsg=""
monitgrepsubj='^Subject..Monit-Message'
monitgrep='^Monit-(Date|Action|Host|Description)'
actionscript="start"
enabledebug=false
debugenabledfile="/tmp/monitnotifyerdebugswitch"
debugfile="${scrpa}/debug.log"
dateformat="%d.%m.%Y %H:%M:%S"

monitnotifyeroutput() {
    if [ ${enabledebug} == true ]; then
        if ! [ -f "${debugfile}" ]; then
            /bin/touch "${debugfile}" > /dev/null 2>&1 &&
                /bin/chgrp "$(/usr/bin/id $(/usr/bin/whoami) | /bin/grep -E "groups.[0-9]+.[a-zA-Z0-9]+" | /usr/bin/cut -f1 -d\()" "${debugfile}" > /dev/null 2>&1 &&
                /bin/chmod g+w "${debugfile}" > /dev/null 2>&1 &&
                /bin/echo "$(date +"${dateformat}") - [MONITNOTIFYER] - ${1}" >> "${debugfile}" ||
            return
        fi
        /bin/echo "$(date +"${dateformat}") - [MONITNOTIFYER] - ${1}" >> "${debugfile}"
    fi
}

trignotification() {
    mailfullmsg="$(/bin/cat ${monitnotifymbox})"
    mailmsgsubj="$(/bin/echo "${mailfullmsg}" | grep -E "${monitgrepsubj}")"
    if [ -n "${mailmsgsubj}" ]
    then
        monitnotifyeroutput "Monitmail detected" &
        if [ $(/bin/echo ${mailmsgsubj} | /usr/bin/wc -l) -gt 1 ]; then
            multymsg=true
            monitnotifyeroutput "Detected multy mail" &
        else
            monitnotifyeroutput "Detected single mail" &
            /bin/echo "d*" | /usr/bin/mail
            monitnotifyeroutput "Generating data for notification" &
            mservicename="$(/bin/echo "${mailmsgsubj}" | /usr/bin/cut -f4 -d\:)"
            mservicestatus="$(/bin/echo "${mailfullmsg}" | /bin/grep -E '^Subject. Monit-Message' | /usr/bin/cut -f3 -d\:)"
            mserviceaction="$(/bin/echo "${mailfullmsg}" | /bin/grep -E '^Monit-Action' | /usr/bin/cut -f2 -d\:)"
            mservicehost="$(/bin/echo "${mailfullmsg}"  | /bin/grep -E '^Monit-Host.' | /usr/bin/cut -f2 -d\:)"
            mservicedesc="$(/bin/echo "${mailfullmsg}" | /bin/sed -n '/^Monit-Description./,/^$/p' | /bin/sed -e 's/^Monit-Description.//g;/^$/d')"

            monitnotifyeroutput "Running pretigger_notification script with parameters:
Parameter1: (debugswitch)         \"${enabledebug}\"
------------------
Parameter2: (logfile)             \"${debugfile}\"
------------------
Parameter3: (service name)        \"${mservicename}\"
------------------
Parameter4: (service action)      \"${mserviceaction}\"
------------------
Parameter5: (service status)      \"${mservicestatus}\"
------------------
Parameter6: (service description) \"${mservicedesc}\"
------------------
Parameter7: (service host)        \"${mservicehost}\"" &
            "${scrpa}/pretrigger_notification.sh" ${enabledebug} "${debugfile}" "${mservicename}" "${mserviceaction}" "${mservicestatus}" "${mservicedesc}" "${mservicehost}" &
        fi
    else
        monitnotifyeroutput "Not a monit message, ignore it" &
        return
    fi
}

usage() {
	echo "==================== [  HELP for $(/usr/bin/basename ${0})  ] ===================="
	echo "    -h               > Will show you shit help"
	echo "    -d               > Will enable the debug mode"
	echo "    -D               > Will disable the debug mode"
	echo "    -a               > (default start) Can be set manually only to start or stop"
	echo "                       for starting or stopping the script"
	exit 0
}


if [ -f "${debugenabledfile}" ]; then
    enabledebug=true
fi

optstring="a:d?h"

while getopts ${optstring} c; do
    case ${c} in
        a)
            actionscript="${OPTARG}"
            ;;
        d)
            /bin/touch "${debugenabledfile}" &&
                monitnotifyeroutput "Debug Mode enabled" &
            enabledebug=true
            ;;
        D)
            enabledebug=false
            ;;
        *)  usage ;;
        [h\?]) usage ;;
    esac
done

if [ -f "${debugenabledfile}" ] && [ ${enabledebug} == false ]; then
    rm -f "${debugenabledfile}" > /dev/null 2>&1 &
fi

actionscript="$(echo ${actionscript} | /usr/bin/tr '[:upper:]' '[:lower:]')"

monitnotifyeroutput "ACTION: ${actionscript}" &
if [ "${actionscript}" == "start" ]; then
	if [ -z "$(/usr/bin/pgrep -l inotify -u $(/usr/bin/id monitnotify -u))" ]; then
        monitnotifyeroutput "Opening inotifywait on ${monitnotifymbox}" &
		/usr/bin/inotifywait -q -m -e close_write ${monitnotifymbox} |
		while read -r filename events
		do
			if [ "${filename}" == "${monitnotifymbox}" ] ; then trignotification ; fi
		done
	else
		monitnotifyeroutput "monitnotifyer is already running with pid $(/usr/bin/pgrep -l inotify -u $(/usr/bin/id monitnotify -u) | /usr/bin/awk 'print {$1}')" &
	fi
elif [ "${actionscript}" == "stop" ]; then
    monitnotifyeroutput "Stopping monitnotify scripts" &
    kill -9 $(echo $(/usr/bin/pgrep -l inotify -u $(/usr/bin/id monitnotify -u)) | /usr/bin/cut -f1 -d\ ) > /dev/null 2>&1
	exit 0
else
	usage
fi
