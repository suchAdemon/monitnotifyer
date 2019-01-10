#!/bin/bash
scrpa="$(/usr/bin/dirname ${0})"
monitnotifymbox="/var/mail/monitnotify"
monitgrep='^Subject..Monit-Message|^Monit-(Date|Action|Host|Description)'

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

/usr/bin/inotifywait -q -m -e close_write ${monitnotifymbox} |
while read -r filename events
do
    if [ "${filename}" == "${monitnotifymbox}" ] ; then trignotification ; fi
done
