# monitnotifyer

monitnotifyer is a wrapper which allows you to parse the monit mail notifications and forwards them to any application you want

## Installation

### Requirements
Install [git](https://git-scm.com/) with your choosen package manager like [apt](https://wiki.debian.org/Apt) for [debian](https://www.debian.org/)
```bash
apt install git
```
Create a local account which will be used to converte the mails coming from monit
```bash
useradd -d /tmp/monit monitnotify
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
monitnotifyer.sh [-hd]
  -h        will show you this help message
  -d        will run the script in debug mode (output to stdout)
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
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)
