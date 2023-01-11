# Crownstone cloud installer

This repository maintains scripts to install your own instance of Crownstone cloud on a local machine such as a Raspberry Pi (3/4/400).

The scripts install the complete Crownstone cloud, and updates it as well.

The Crownstone cloud uses MongoDB to store data. This script can install MongoDB as well. However, authorization will not be set up, though it will not be accessible via network.

## Security

As with every server, you should make sure to keep the system up to date and reduce the attack surface.
Security is not set up by this installer script, you will have to do this yourself.

Think about:
- Installing *unattended-upgrades* configured with automatic reboot.
- Configuring ssh: disable password logins, use a different port, etc.
- Setting up a firewall.
- Installing (and configuring) *fail2ban*.
- Etc.

## Preparation

In the middle of the install script you will be asked for keys to be able to send push notifications from your local cloud instance towards the Android or iOS app. These keys can be provided by the maintainers. You can reach the maintainers for these keys at the [Crownstone Community discord server](https://discord.gg/TPYfMvV7bD).

Make sure to configure your server (the Rasperry Pi) to have a static local ip address. Usually this can be done by logging in on your router.

## Installing

Most requirements come from the installation of [MongoDB](https://www.mongodb.com/docs/v4.4/administration/production-notes). When installing on a Raspberry Pi, ensure to use the 64-bit OS, as MongoDB requires an 64-bit OS. In case you want to install MongoDB manually or on another location, you can skip installing MongoDB during the installation process. This may require you to change the environment variables after installation, but it allows you to run this installer on a user without sudo rights, and configure authentication on MongoDB.

The installation has been tested on a Raspberry Pi 4 with Raspberry Pi OS Lite 64-bit. Download the dedicated [Raspberry PI Imager](https://www.raspberrypi.com/software/) to graphically choose this image, directly configure WiFi, enable SSH key access, etc.

Use the following commands to get this repository:
```
sudo apt update
sudo apt install -y git
git clone https://github.com/Crownstone-Community/cloud-installer.git
cd cloud-installer
git checkout $(git describe --tags `git rev-list --tags --max-count=1`)
```

MongoDB will be initialized with data by running `mongo mongo-init.js` with arguments from `mongo-args.txt`. If you don't provide these 2 files yourself, it will be copied from the template `mongo-init-template.js` and `mongo-args-template.txt` respectively.
At this moment, it is used to insert the keys that are used to send notifications to the phone app (see above at **preparation**). Feel free to ignore too, but in that case no push notifications will be sent to the Crownstone apps.

After that simply run the script (some confirmations may be asked during the installation process):
```
./install.sh ~/crownstone-cloud
```
You can check the status of the various services with `systemctl --user status`.

You can see logs with `journalctl --user`.

## Data import

Every user in your sphere will have to:
- Get their phone and log out from the Crownstone app (Settings -> Log Out).
- Download their data at [https://next.crownstone.rocks/user-data](https://next.crownstone.rocks/user-data).

Then, go to your own cloud v2 server [http://123.456.78.9:3050/import-data](http://123.456.78.9:3050/import-data) and the port configured for cloud v2. Make sure to replace `123.456.78.9` with the IP address of your server, you can find it with the command `hostname -I`.

Now upload the downloaded data. Note that this can take a while, wait until the page changes into "DONE".

## App settings

Every user in your sphere will have to perform this step.

Get your phone again and open the Crownstone app (where you logged out in the previous step).
Before loggin in, click on *Configure custom cloud*.

Now you can change the cloud address in the Crownstone app settings.
- Address of custom cloud v1: http://123.456.78.9:3000/api/
- Address of custom cloud v2: http://123.456.78.9:3050/api/
- Address of custom sse server: http://123.456.78.9:8000/sse/

Again, replace `123.456.78.9` with the IP address of your server, and use the ports as configured.

Now click *Validate and save*, and login.

Note: After a preliminary success message you may get a warning pop-up saying that the cloud endpoints are not stored. This is a known bug. As long as the preliminary message reported success, you're all good.


## Open-source license

This software is provided under a noncontagious open-source license towards the open-source community. It's available under three open-source licenses:
 
* License: LGPL v3+, Apache, MIT

<p align="center">
  <a href="http://www.gnu.org/licenses/lgpl-3.0">
    <img src="https://img.shields.io/badge/License-LGPL%20v3-blue.svg" alt="License: LGPL v3" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" />
  </a>
  <a href="https://opensource.org/licenses/Apache-2.0">
    <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License: Apache 2.0" />
  </a>
</p>

## Commercial license

This software can also be provided under a commercial license. If you are not an open-source developer or are not planning to release adaptations to the code under one or multiple of the mentioned licenses, contact us to obtain a commercial license.

* License: Crownstone commercial license

# Contact

For any question contact us at <https://crownstone.rocks/contact/> or on our discord server through <https://crownstone.rocks/forum/>.
