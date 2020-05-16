## sSMTP system pre-configuration

Once you have installed sSMTP on your Linux system, make sure the following applies. Run these configuration commands as root or with `sudo`.

----------

**1)** Check that symbolic link from `/usr/bin/ssmtp` to `/usr/bin/sendmail` exists:

```
ln -s /usr/bin/ssmtp /usr/bin/sendmail
```

Test:

```
> stat -c "%A %a %U:%G %N" /usr/bin/sendmail

    lrwxrwxrwx 777 root:root /usr/bin/sendmail -> ssmtp
```

----------

**NOTE:** User & group `mail` are defined on Arch Linux by default, preinstalled with `filesystem` package. If they do not exist, then do the following.

**2)** Make sure user & group `mail` exists, and directory /`var/spool/mail` exists with proper permissions:

```
mkdir -p /var/spool/mail
chmod 1777 /var/spool/mail

groupadd -g 12 mail
useradd -r -d /var/spool/mail -s /sbin/nologin -u 12 -g 12 mail
```

Test:

```

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

Once you have sSMTP installed on your Linux system, configure [ssmtp.conf](ssmtp.conf) and [revaliases](revaliases) in `/etc/ssmtp/` folder.

## Mail message formatting & email address

Configure your message defined in [wanchecker.sh](wanchecker.sh) file.

`wanchecker.sh` variables:

|     Variable     |                                    Value                                    |    Type    |
|------------------|-----------------------------------------------------------------------------|------------|
| SUBJECT_EMAIL    | Email title                                                                 | String     |
| MESSAGE_EMAIL    | Email message contents                                                      | String     |
| MESSAGE_STDOUT   | Internal Linux system message about sent email message                      | String     |
| WANIP_DIR        | Log file directory path. User `mail` must have write access to this folder. | String     |
| WANIP_LOG        | Log file name                                                               | String     |

## Mail sender and recipients

These are found in `/etc/ssmtp/wanchecker.conf` which is a bash `source` file.
The conf file has three variables: `ENABLE_FALLBACK_DNS`, `EMAIL_SENDER` and `EMAIL_RECIPIENTS` which **must be** configured. `EMAIL_SENDER` takes same value as defined in `/etc/ssmtp/ssmtp.conf` ([sample](ssmtp.conf)) and `/etc/ssmtp/revaliases` ([sample](revaliases)) files.

## Folder & file permissions

Permissions for `/etc/ssmtp` folder should be:

```
> stat -c "%A %a %U:%G %n" /etc/ssmtp

    drwxr-x--- 750 root:mail /etc/ssmtp
```

Contents of `/etc/ssmtp/` folder should contain the following files & permissions:

```
> stat -c "%A %a %U:%G %n" /etc/ssmtp/*

    -rw-r----- 640 root:mail /etc/ssmtp/revaliases
    -rw-r----- 640 root:mail /etc/ssmtp/ssmtp.conf
    -rwxr-x--- 750 root:mail /etc/ssmtp/wanchecker.sh
    -rwxr-x--- 640 root:mail /etc/ssmtp/wanchecker.conf
```

**NOTE:** As `/etc/ssmtp/ssmtp.conf` contains a _clear-text email password_, the file must be protected from any eavesdropping with correct permission policy! The file must not be readable to any other than `mail` user, and `mail` user must not be available for normal usage. Still, any `sudo` group member can access the file, so make sure `sudo` group does not contain hostile or unwanted members, and configure your `/etc/sudoers` file properly.
