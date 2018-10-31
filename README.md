# WAN IP checker

WAN IPv4 checker & email notifier for server environments behind dynamic DHCP.

## About

In many home networks, WAN (Wide Area Network) IP addresses are dynamically allocated by a local ISP. Usually this is acceptable in common household/home use, but not in server use where static DHCP lease/static IP address is very much a mandatory requirement.

However, static IPs are usually offered only to corporate environments, and not everyone wants to pay extra for such in order to establish a simple server environment in home.

This repository contains a systemd service file & a simple bash script to refresh current WAN IPv4 of a Linux server, and notify server admins for any changes in the server WAN IPv4 (Internet) address. This helps in several issues:

- Server admins are always aware of the current server IPv4 address, whether the address is dynamic or not.

- Server admins are able to remotely connect to the server environment although the server IP has been changed. This is possible because admins are notified about any WAN IPv4 address changes via email by the server itself, automatically.

## Requirements

- A server computer of any kind

- Linux OS

    - systemd - service file

    - [SSMTP](https://wiki.archlinux.org/index.php/SSMTP) - (SMTP) email client (package: `ssmtp` (Arch Linux), `ssmtp` (Ubuntu))
    
    - dig (package: `bind-tools` (Arch Linux), `dnsutils` (Ubuntu))

    - bash

    - awk

## Contents

- systemd **user** service file: `wanip-checker@.service`

- bash script: `wanip-checker.sh`

## Installation

**1)** Insert `wanip-checker@.service` into `/usr/lib/systemd/user/` folder

- WAN IP check interval is customizable in systemd service file. Default value is `1200` (20 min)

**2)** Insert `wanip-checker.sh` into your `/home/myuser/` folder

**3)** Configure your email address and message form in `wanip-checker.sh` file. In addition, configure WAN IPv4 log file location (default is `$HOME`)

    - log file is updated only when WAN IPv4 changes have been detected

**3)** Install `ssmtp`, and configure files `/etc/ssmtp/revaliases` and `/etc/ssmtp/ssmtp.conf` as described on [SSMTP Arch Wiki site](https://wiki.archlinux.org/index.php/SSMTP).

**4)** Run

```
systemctl --user enable wanip-checker@myusername.service && \
systemctl --user start wanip-checker@myusername.service && \
systemctl --user daemon-reload

```

**NOTE:** If you change the script contents, make sure to run `systemctl --user restart wanip-checker@myusername.service` afterwards.

## Images

When server computer discovers a change in its WAN IPv4, it automatically sends an email notification to system administrators:

![](images/wanip_email.png)

Additionally, server computer keeps a log file which include WAN IPv4 changes and corresponding timestamps:

![](images/wanip_log.png)
