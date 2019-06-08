# WAN IP checker

WAN IPv4 checker & email notifier for server environments behind dynamic IP address.

## About

In many home networks, WAN (Wide Area Network) IP addresses are dynamically allocated by a local ISP. Usually this is acceptable in common household/home use, but not in server use where static DHCP lease/static IP address is very much a mandatory requirement.

However, static IPs are usually offered only to corporate environments, and not everyone wants to pay extra for such in order to establish a simple server environment in home.

This repository contains a systemd service file & a simple bash script to refresh current WAN IPv4 of a Linux server, and notify server admins for any changes in the server WAN IPv4 (Internet) address. This helps in several issues:

- Server admins are always aware of the current server IPv4 address, whether the address is dynamic or not.

- Server admins are able to remotely connect to the server environment although the server IP has been changed. This is possible because admins are notified about any WAN IPv4 address changes via email by the server itself, automatically.

## Requirements

- A server computer of any kind

- Linux OS

    - systemd

    - [sSMTP](https://wiki.archlinux.org/index.php/SSMTP) - (SMTP) email client (package: `ssmtp` (Arch Linux), `ssmtp` (Ubuntu))

    - dig (package: `bind-tools` (Arch Linux), `dnsutils` (Ubuntu))

    - bash

    - awk

## Contents

- systemd **system** service file: [wanchecker.service](wanchecker.service)

- systemd **system** timer file: [wanchecker.timer](wanchecker.timer)

- [sSMTP sample configuration files](ssmtp_conf-sample)

    - [ssmtp.conf](ssmtp_conf-sample/ssmtp.conf)
    
    - [revaliases](ssmtp_conf-sample/revaliases)
    
    - [wanchecker.sh](ssmtp_conf-sample/wanchecker.sh)

## Installation & configuration

**1)** Install `ssmtp` package

**2)** Configure files `/etc/ssmtp/revaliases` ([sample](ssmtp_conf-sample/revaliases)) and `/etc/ssmtp/ssmtp.conf` ([sample](ssmtp_conf-sample/ssmtp.conf)). More information about these files on [sSMTP Arch Wiki site](https://wiki.archlinux.org/index.php/SSMTP).

**3)** Insert [wanchecker.sh](ssmtp_conf-sample/wanchecker.sh) into `/etc/ssmtp/` folder.

**4)** Configure sSMTP as described in [sSMTP Readme file](ssmtp_conf-sample/README.md).

**5)** Insert `wanchecker.service` and `wanchecker.timer` into `/usr/lib/systemd/system/` folder

- WAN IP check interval is customizable in systemd timer file. Default value is `20min`

- This log file is updated only when WAN IPv4 changes have been detected

**6)** Run (as root or with `sudo`)

```
systemctl enable wanchecker.timer && \
systemctl start wanchecker.timer

```

## Images

When server computer discovers a change in its WAN IPv4, it automatically sends an email notification to system administrator(s):

![](images/wanip_email.png)

Additionally, server computer keeps a log file which include WAN IPv4 changes and corresponding timestamps:

![](images/wanip_log.png)

## Useful commands

- `systemctl --all list-timers` = list all system timers on Linux system, including `wanchecker`

- `systemctl is-active wanchecker.timer` = tells whether `wanchecker` is running or not

- `systemctl status wanchecker.timer` = more compherensive output about the status of `wanchecker`

## License

This repository uses GPLv3 license. See [LICENSE](./LICENSE) file for details.
