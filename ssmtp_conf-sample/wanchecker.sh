#!/bin/env bash

#    WAN IP Checker - Whenever server WAN IP address changes, inform admins via email
#    Copyright (C) 2018  Pekka Helenius
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

###########################################################

# A script for remote server environments which are behind
# dynamic (non-static) DHCP. Usually these dynamic IPs are
# used in common household networks in non-corporate
# environments.

###########################################################

# Script requirements
#
# sSMTP

# https://wiki.archlinux.org/index.php/SSMTP
# Relevant conf files
# /etc/ssmtp/revaliases
# /etc/ssmtp/ssmtp.conf

# Because your email password is stored as cleartext in /etc/ssmtp/ssmtp.conf, it is important that this file
# is secure. By default, the entire /etc/ssmtp directory is accessible only by root and the mail group.
# The /usr/bin/ssmtp binary runs as the mail group and can read this file. There is no reason to add
# yourself or other users to the mail group.

###########################################################

# Some lines below are commented out because the timer is handled by systemd service file
# If you don't use provided systemd service file, re-enable the relevant lines below

function checkWANIP {

  # Command to resolve the current IPv4 WAN address
  local WANIP_CURRENT="dig +short myip.opendns.com @resolver1.opendns.com"

  # Log file timestamp format
  local TIMESTAMP=$(date '+%d-%m-%Y, %X')

############################

  # Email sender
  local EMAIL_SENDER="mailsender@foo.com"

  # Emails to send notification to
  local EMAIL_RECIPIENTS=(
    "whogetsthemail_1@foo.com"
    "whogetsthemail_2@bar.com"
  )

############################

  # Email send function
  function mailSend {
    echo -e "To: ${1}\nFrom: ${EMAIL_SENDER}\nSubject: ${SUBJECT_EMAIL}\n\n${MESSAGE_EMAIL}" | sendmail -v "${1}"
  }

############################

  # If we are connected to internet...
  # There's no point to do WAN IP check if we can't establish connection to WAN/Internet at all
  # In addition, do not generate any network related variables if the connection
  # can't be established. Therefore, include variable defitions inside this if statement.
  if [[ $(printf $(eval "${WANIP_CURRENT}" &> /dev/null)$?) -eq 0 ]]; then

############################

    # Cache/Log directory of the script
    local WANIP_DIR="/var/spool/mail"

    # Log file for checked/resolved IPv4 WAN addresses
    local WANIP_LOG="$WANIP_DIR/ip_wan.log"

    if [[ ! -d "${WANIP_DIR}" ]]; then
      mkdir -p "${WANIP_DIR}"
    fi

    if [[ ! -f "${WANIP_LOG}" ]]; then
      printf 'Time\t\t\t\tWAN IPv4\n' > "${WANIP_LOG}"
    fi

    # Email subject/title
    local SUBJECT_EMAIL="WAN IP address changed (Helsinki, $(tail -1 ${WANIP_LOG} | awk '{print $NF}') -> $(eval ${WANIP_CURRENT}))"

    # Email message/body contents
    local MESSAGE_EMAIL="${TIMESTAMP}: WAN address of location (Helsinki) has been changed from $(tail -1 ${WANIP_LOG} | awk '{print $NF}') to $(eval ${WANIP_CURRENT})"

    # Message to server stdout
    local MESSAGE_STDOUT="$(echo ${TIMESTAMP}) - WAN address of this server has been changed from $(tail -1 ${WANIP_LOG} | awk '{print $NF}') to $(eval ${WANIP_CURRENT})"

############################

    # Log write command
    local LOG_WRITE=$(printf '%s %s\t\t%s\n' $(echo "${TIMESTAMP}") $(eval "${WANIP_CURRENT}") >> "${WANIP_LOG}")

############################

    if [[ $(tail -1 "${WANIP_LOG}" | awk '{print $NF}') != $(printf '%s' $(eval "${WANIP_CURRENT}")) ]] || \
    [[ $(cat "${WANIP_LOG}" | wc -l) -le 2 ]] ; then

      echo -e "${MESSAGE_STDOUT}"

      for i in "${EMAIL_RECIPIENTS[@]}"; do
        mailSend "${i}"
        $LOG_WRITE
      done

    fi

  fi

}

############################

checkWANIP
