## sSMTP system pre-configuration

Once you have installed sSMTP on your Linux system, make sure the following applies. Run the configuration commands as root or with `sudo` prefix.

----------

Symbolic link from `/usr/bin/ssmtp` to `/usr/bin/sendmail`:

```
ln -s /usr/bin/ssmtp /usr/bin/sendmail
```

```
Test:

    > stat -c "%A %a %U:%G %N" /usr/bin/sendmail

        lrwxrwxrwx 777 root:root /usr/bin/sendmail -> ssmtp
```

----------

User & group mail exists, directory /`var/spool/mail` exists:

```
mkdir -p /var/spool/mail
chmod 1777 /var/spool/mail

groupadd -g 12 mail
useradd -r -d /var/spool/mail -s /sbin/nologin -u 12 -g 12 mail
```

```
Test:

-----
    > sudo stat -c "%A %a %U:%G %n" /var/spool/mail

        drwxrwxrwt 1777 root:root /var/spool/mail

-----
    > grep mail /etc/passwd

        mail:x:12:12::/var/spool/mail:/sbin/nologin

-----
    > grep mail /etc/group

        mail:x:12:
```

## sSMTP configuration files

Once you have sSMTP installed on your Linux system, insert [ssmtp.conf](ssmtp.conf), [revaliases](revaliases) and [wanchecker.sh](wanchecker.sh) into `/etc/ssmtp/` folder. These files should have following permissions:

```
> stat -c "%A %a %U:%G %n" /etc/ssmtp/*

-rw-r----- 640 root:mail /etc/ssmtp/revaliases
-rw-r----- 640 root:mail /etc/ssmtp/ssmtp.conf
-rwxr-x--- 750 root:mail /etc/ssmtp/wanchecker.sh

```

where group `mail` refers to Arch Linux mail group, preinstalled with `filesystem` package.