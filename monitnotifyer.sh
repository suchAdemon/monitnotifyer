#!/bin/bash
scrpa="$(/usr/bin/dirname ${0})"
monitnotifymbox="/var/mail/monitnotify"
monitgrep='^Subject..Monit-Message|^Monit-(Date|Action|Host|Description)'
actionscript="start"
enabledebug=false

trignotification() {
    mailmsg="$(cat ${monitnotifymbox} | grep -E "${monitgrep}")"
    if [ -n "${mailmsg}" ]
    then
        echo "Monitmail detected"
        if [ $(/bin/echo ${mailmsg} | /usr/bin/wc -l) -gt 5 ]; then
            multymsg=true
            echo "Detected multy mail"
        else
            echo "Detected single mail"
            /bin/echo "d*" | /usr/bin/mail
            mservicename="$(/bin/echo "${mailmsg}" | /bin/grep -E '^Subject. Monit-Message' | /usr/bin/cut -f4 -d\:)"
            mservicestatus="$(/bin/echo "${mailmsg}" | /bin/grep -E '^Subject. Monit-Message' | /usr/bin/cut -f3 -d\:)"
            mserviceaction="$(/bin/echo "${mailmsg}" | /bin/grep -E '^Monit-Action' | /usr/bin/cut -f2 -d\:)"
            mservicehost="$(/bin/echo "${mailmsg}"  | /bin/grep -E '^Monit-Host.' | /usr/bin/cut -f2 -d\:)"
            mservicedesc="$(/bin/echo "${mailmsg}" | /bin/grep -E '^Monit-Description.' | /bin/sed -e 's/^Monit-Description.//g')"

            ${scrpa}/pretrigger_notification.sh "${mservicename}" "${mserviceaction}" "${mservicestatus}" "${mservicedesc}" "${mservicehost}" &
        fi
    else
        /bin/echo "Not a monit message, ignore it"
        return
    fi
}

usage() {
	echo "==================== [  HELP for $(/usr/bin/basename ${0})  ] ===================="
	echo "    -h               > Will show you shit help"
	echo "    -d               > Will enable the debug mode"
	echo "    -a               > (default start) Can be set manually only to start or stop"
	echo "                       for starting or stopping the script"
	exit 0
}

optstring="a:d?h"

actr10kbranch="$(git -C ${r10kpwd} branch 2>&1 | grep -E '^\*' | /usr/bin/awk '{print $2}')"

while getopts ${optstring} c; do
    case ${c} in
        a)
            actionscript="${OPTARG}"
            ;;
        d)
            enabledebug=true
            ;;
        *)  usage ;;
        [h\?]) usage ;;
    esac
done

actionscript="$(echo ${actionscript} | /usr/bin/tr '[:upper:]' '[:lower:]')"

if [ "${actionscript}" == "start" ]; then
	if [ -z "$(/usr/bin/pgrep -l inotify -u $(/usr/bin/id monitnotify -u))" ]; then
		/usr/bin/inotifywait -q -m -e close_write ${monitnotifymbox} |
		while read -r filename events
		do
			if [ "${filename}" == "${monitnotifymbox}" ] ; then trignotification ; fi
		done
	else
		echo "monitnotifyer is already running with pid $(/usr/bin/pgrep -l inotify -u $(/usr/bin/id monitnotify -u) | /usr/bin/awk 'print {$1}')"
	fi
elif [ "${actionscript}" == "stop" ]; then
    kill -9 $(echo $(/usr/bin/pgrep -l inotify -u $(/usr/bin/id monitnotify -u)) | /usr/bin/cut -f1 -d\ ) > /dev/null 2>&1
	exit 0
else
	usage
fi
