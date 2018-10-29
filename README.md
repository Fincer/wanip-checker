# WAN IP checker

WAN IPv4 checker & email notifier for server environments behind dynamic DHCP.

## About

This repository contains a systemd service file & a simple bash script to refresh current WAN IPv4 of a server, and notify server admin for any changes in the server WAN (Internet) address. This helps in several issues:

- Server admin is always aware of the current server IPv4 address, whether the address is dynamic or not.

- Server admin is able to remotely connect to the server environment although the server IP may have been changed. This is possible because the admin is notified about any WAN IPv4 address changes via email by the server itself, automatically.

In many home networks, WAN (Wide Area Network) IP addresses are dynamically allocated by a local ISP. Usually this is okay in common household/home use, but not in server use. 

In most server environments, static DHCP lease/static IP address is a mandatory requirement. However, static IPs are usually offered only for corporate environments, and not everyone wants to pay extra for such in order to establish a simple server environment in home.

## Requirements

- A server computer of any kind

- Linux OS

    - systemd - service file

    - [SSMTP](https://wiki.archlinux.org/index.php/SSMTP) - email client

    - bash

    - awk

## Contents

- systemd **user** service file: `wanip-checker@.service`

- bash script: `wanip-checker.sh`

## Installation

**1)** Insert `wanip-checker@.service` into `/usr/lib/systemd/user/` folder

- WAN IP check interval is customizable in systemd service file. Default value is `60` (1 min)

**2)** Insert `wanip-checker.sh` into your `/home/myuser/` folder

**3)** Configure your email address and message form in `wanip-checker.sh` file

**3)** Install `ssmtp`, and configure files `/etc/ssmtp/revaliases` and `/etc/ssmtp/ssmtp.conf` as described on [SSMTP Arch Wiki site](https://wiki.archlinux.org/index.php/SSMTP).

**4)** Run

```
systemctl --user enable wanip-checker@myusername.service && \
systemctl --user start wanip-checker@myusername.service && \
systemctl --user daemon-reload

```

**NOTE:** If you change the script contents, make sure to run `systemctl --user restart wanip-checker@myusername.service` afterwards.

## Images

When server computer discovers changes in WAN IPv4, it automatically sends an email notification for system administrators:

![](images/wanip_email.png)

Additionally, server computer keeps a log file which include WAN IPv4 changes and corresponding timestamps:

![](images/wanip_log.png)
