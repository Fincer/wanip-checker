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

- systemd **user** service file: `wanchecker@.service`

- systemd **user** timer file: `wanchecker@.timer`

- bash script: `wanchecker.sh`

## Installation

**1)** Insert `wanchecker@.service` and `wanchecker@.timer` into `/usr/lib/systemd/user/` folder

- WAN IP check interval is customizable in systemd timer file. Default value is `20min`

**2)** Insert `wanchecker.sh` into your `/home/myuser/` folder (where `myuser` is your real username on your Linux system)

**3)** Configure your email address and message form in `wanchecker.sh` file. In addition, configure WAN IPv4 log file location (default is `$HOME`)

- log file is updated only when WAN IPv4 changes have been detected

**3)** Install `ssmtp`, and configure files `/etc/ssmtp/revaliases` and `/etc/ssmtp/ssmtp.conf` as described on [SSMTP Arch Wiki site](https://wiki.archlinux.org/index.php/SSMTP).

**4)** Run

```
systemctl --user enable wanchecker@myusername.timer && \
systemctl --user start wanchecker@myusername.timer

```

**NOTE:** If you change the shell script contents, make sure to run `systemctl --user restart wanchecker@myusername.timer` afterwards.

Obviously, `myusername` above refers to your true username on your Linux system.

## Images

When server computer discovers a change in its WAN IPv4, it automatically sends an email notification to system administrator(s):

![](images/wanip_email.png)

Additionally, server computer keeps a log file which include WAN IPv4 changes and corresponding timestamps:

![](images/wanip_log.png)

## Useful commands

- `systemctl --user --all list-timers` = list all user-specific timers on Linux system, including `wanchecker`

- `systemctl --user is-active wanchecker@myusername.timer` = tells whether wanchecker is running or not

- `systemctl --user status wanchecker@myusername.timer` = more compherensive output about the status of `wanchecker`

etc.

## License

This repository uses GPLv3 license. See [LICENSE](./LICENSE) file for details.
