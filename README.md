# monitnotifyer

Monit as we all know, is sending by default messages via mail. Somtimes it enough to have that as alerting, but sometimes not.

Of course you can run a script with 'if failed something-service1 then exec /data/monit/script/service1.sh', but the problem is that you get no data from the script call, meaning not if it went down/up/or what else or any other details and normally you dont want to specify for every monitored object a script, which is than again checking your service/script/output/stat/... to have the right information for sending a notification.

As I use a different notification service for alert/recoveryie messages, it did not fit for me a 100%.

Now there comes monitnotifyer. This script is listening with inotifywait on a local mailbox directly on the server which is getting monitored and everytime when monit triggers an alert, the mail arrivers in that local mailbox.

It parses out the needed informaionts given from the mail and brings them in a structured way so that they can be handed over to a different script as parameters and than its up to your script to do with the information what ever you want to do.

For example, you can than forwarding an alert to a pushservice provider, sms service provider and via mail to get notify everyone who needs to get notified.

Long story short:
monitnotifyer is a wrapper which allows you to parse the monit mail notifications and forwards them to any application you want

## Installation

### Requirements
Install [git](https://git-scm.com/) with your choosen package manager like [apt](https://wiki.debian.org/Apt) for [debian](https://www.debian.org/)
```bash
apt install git
```
Create a local account which will be used to converte the mails coming from monit
```bash
useradd -d /home/monit monitnotify
```

### Configure monit mail
For that you have to modify the /etc/monitrc, or some other file depends on where you have specified the mail setup for monit, like this:
```bash
 set mailserver localhost

 set mail-format {
   from:    Monit <monit@localhost|or_real_hostname>
   subject:Monit-Message:$EVENT:$SERVICE
   message: Monit-Date:$DATE
Monit-Action:$ACTION
Monit-Host:$HOST
Monit-Description:$DESCRIPTION
 }

 set alert monitnotify@<localhost|or_real_hostname> not on { instance, action }
```

### Clone reposiroty
As the new user, clone the repository using git
```bash
su - monitnotify -s /bin/bash
git clone https://gitea.sons-of-sparda.at/oliver.schraml/monitnotifyer.git
```

### Setup service in systemd
As we want to run this as a service, you can use the monitnotify.service_sample file to create unitfile for systemd.
```bash
cp monitnotify.service_sample /etc/systemd/system/monitnotify.service
```
Modify the service file as you need it and afterwards run it for testing
```bash
systemctl start monitnotify.service
systemctl status monitnotify.service
```
If everything is fine, you can just enable it
```bash
systemctl enable monitnotify.service
```


## Usage

### Help
```bash
monitnotifyer.sh [-h] [-(d|D)] [-a (start|stop)]
  -h        will show you this help message
  -d        will run the script in debug mode (output to stdout)
  -D        will disable the debug mode
  -a        (default start) Can be set manually only to start or stop
            for starting or stopping the script
```

### Debuging
There is no need to directly execute it, as the service is configured in systemd to ensures that it is getting started and restarted if it fails.
If you still want to execute it manually, for example to debug some behavier you can run it like that:
```bash
su - monitnotify -s /bin/bash
cd /path/to/repo/monitnotifyer
./monitnotifyer.sh -d
```

## .gitignore
```bash
cat .gitignore
*~
.*.sw?
.sw?
\#*\#
DEADJOE

/pretrigger_notification.sh
/monitnotify.service
/test*
/*.log
```


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.


## License
[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)
