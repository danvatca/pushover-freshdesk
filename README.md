pushover-freshdesk
==================

Since Freshdesk's iOS application can not (yet) send push notification, I
decided to build my own little man in the middle that connects the freshdesk API
with the push notification service provided by Pushover.

h1. Installation
```
make install
```

h1. Configuration
Edit the configuration file (by default in /usr/bin/pushover-freshdesk-config.php).

h1. Start/Stop
It uses the /etc/init.d/pushover-freshdesk LSB style initscript.
