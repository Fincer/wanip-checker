#!/bin/env bash

#    WAN IP Checker - Whenever server WAN IP address changes, inform admins via email
#    Copyright (C) 2020  Pekka Helenius
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
# /etc/ssmtp/revaliases (email conf)
# /etc/ssmtp/ssmtp.conf (email conf)
# /etc/ssmtp/wanchecker.conf (env vars, email conf)

# Because your email password is stored as clear text in /etc/ssmtp/ssmtp.conf, it is important that this file
# is secure. By default, the entire /etc/ssmtp directory is accessible only by root and the mail group.
# The /usr/bin/ssmtp binary runs as the mail group and can read this file. There is no reason to add
# yourself or other users to the mail group.

###########################################################

############################
# Fallback DNS

# This service must work even if our system-wide DNS configuration fails
# NOTE: If your WAN firewall blocks external DNS servers, this fallback method fails.
#
# List of overriding fallback DNS servers
#
# CURL:
# Optionally requires curl built with '--enable-dnsshuffle' and '--enable-ares' configure options
#
# Other applications:
# Requires shell preload library '/usr/lib/libresolvconf-override.so' (https://github.com/hadess/resolvconf-override)
#
FALLBACK_DNS=(
  # OpenDNS
  208.67.220.222
  208.67.220.220
  # Google DNS
  8.8.8.8
  8.8.4.4
  # OpenNIC DNS
  58.6.115.42
  58.6.115.43
  119.31.230.42
  200.252.98.162
  217.79.186.148
  81.89.98.6
  78.159.101.37
  203.167.220.153
  82.229.244.191
  216.87.84.211
  66.244.95.20
  207.192.69.155
  72.14.189.120
  # Alternate DNS
  198.101.242.72
  23.253.163.53
  # FreeDNS
  37.235.1.174
  37.235.1.177
)

############################

source /etc/ssmtp/wanchecker.conf

############################

function resolvconfOverrideDNSList {
  local i=0
  local max_dns=4
  local dns_strlist=""
  while [[ $i -lt $(( ${#FALLBACK_DNS[@]} - 1)) ]]; do
    [[ ${i} == ${max_dns} ]] && break
    dns_strlist="${dns_strlist} NAMESERVER$((${i} + 1))=${FALLBACK_DNS[$i]}"
    let i++
  done
  echo "${dns_strlist}"
}

function curlFallBackDNS {

  fallback_dns=""
  preload_lib=""
  if [[ $(curl -V | sed -n '/AsynchDNS/p' | wc -l) -ne 0 ]] &&
  [[ $ENABLE_FALLBACK_DNS == 1 ]]; then
    # Fallback DNS servers can be used
    fallback_dns=$(echo ${FALLBACK_DNS[*]} | sed 's/ /,/g')
  elif [[ -f "/usr/lib/libresolvconf-override.so" ]] && [[ $ENABLE_FALLBACK_DNS == 1 ]]; then
    # Curl is built without '--enable-dnsshuffle' and fallback is enabled
    preload_lib="LD_PRELOAD=/usr/lib/libresolvconf-override.so $(resolvconfOverrideDNSList)"
  fi

  if [[ ${fallback_dns} != "" ]]; then
    fallback_dns="--dns-servers ${fallback_dns}"
  fi

  CURL_DNS_LIST=("${preload_lib}" "${fallback_dns}")
}

function getMyIP {

  RESOLVERS=(
    # Does not work anymore
    #"dig +short myip.opendns.com @resolver1.opendns.com"
    "${CURL_DNS_LIST[0]} curl -s ${CURL_DNS_LIST[1]} https://checkip.amazonaws.com"
    "${CURL_DNS_LIST[0]} curl -s ${CURL_DNS_LIST[1]} checkip.dyndns.org"
    "${CURL_DNS_LIST[0]} curl -s ${CURL_DNS_LIST[1]} ifconfig.me"
    "${CURL_DNS_LIST[0]} curl -s ${CURL_DNS_LIST[1]} ipecho.net/plain"
    "${CURL_DNS_LIST[0]} curl -s ${CURL_DNS_LIST[1]} bot.whatismyipaddress.com"
    "${CURL_DNS_LIST[0]} curl -s ${CURL_DNS_LIST[1]} icanhazip.com"
  )

  IFS=$'\n'
  response=""
  for resolver in ${RESOLVERS[@]}; do
    check=$(eval "${resolver}" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
    if [[ ${check} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      response=${check}
      break
    fi
  done
  IFS=' '

}

function getMyCity() {
  city=$(eval ${CURL_DNS_LIST[0]} curl -s ${CURL_DNS_LIST[1]} https://json.geoiplookup.io/${response} | awk -F '"' '/city/{ print $(NF-1); }')
}

function checkWANIP {

  # Log file timestamp format
  local TIMESTAMP=$(date '+%d-%m-%Y,%X')

  # Resolve the current IPv4 WAN address
  # Attempt with system common DNS resolvers
  getMyIP
  if [[ ${response} == "" ]]; then
    # Fallback to listed DNS resolvers
    curlFallBackDNS
    getMyIP
  fi

  local WANIP_CURRENT="${response}"

############################

  # If we are connected to internet...
  # There's no point to do WAN IP check if we can't establish connection to WAN/Internet at all
  # In addition, do not generate any network related variables if the connection
  # can't be established. Therefore, include variable defitions inside this if statement.
  if [[ ${response} != "" ]]; then

    # Get city information for email, based on fetched WAN IP address
    unset CURL_DNS_LIST
    # Attempt with system common DNS resolvers
    getMyCity
    if [[ ${city} == "" ]]; then
      # Fallback to listed DNS resolvers
      curlFallBackDNS
      getMyCity
      if [[ ${city} == "" ]]; then
        city="Default"
      fi
    fi

    local WANIP_CITY="${city}"

############################

    if [[ ! -d "${WANIP_DIR}" ]]; then
      mkdir -p "${WANIP_DIR}"
    fi

    if [[ ! -f "${WANIP_LOG}" ]] || [[ $(cat "${WANIP_LOG}" | wc -l) == 0 ]]; then
      printf "%-25s%-18s%-8s\n" "Time" "WAN IPv4" "Email sent" > "${WANIP_LOG}"
      chmod o-r "${WANIP_LOG}"
    fi

    if [[ $(cat "${WANIP_LOG}" | wc -l) -gt 1 ]] ; then
      local WANIP_OLD=$(tail -1 "${WANIP_LOG}" | awk '{print $2}')
    fi

    if [[ ${WANIP_OLD} == "" ]]; then

      # Email subject/title
      local SUBJECT_EMAIL="New WAN IP address registered (${WANIP_CITY}, ${WANIP_CURRENT})"

      # Email message/body contents
      local MESSAGE_EMAIL="${TIMESTAMP}: New WAN IP address ${WANIP_CURRENT} has been registered in location ${WANIP_CITY}. Notifier: $(cat /etc/hostname)"

      # Message to server stdout
      local MESSAGE_STDOUT="${TIMESTAMP} - New WAN IP address ${WANIP_CURRENT} has been registered for this computer"

    else

      # Email subject/title
      local SUBJECT_EMAIL="WAN IP address changed (${WANIP_CITY}, ${WANIP_OLD} -> ${WANIP_CURRENT})"

      # Email message/body contents
      local MESSAGE_EMAIL="${TIMESTAMP}: WAN IP address ${WANIP_OLD} has been changed to ${WANIP_CURRENT} in location ${WANIP_CITY}. Notifier: $(cat /etc/hostname)"

      # Message to server stdout
      local MESSAGE_STDOUT="${TIMESTAMP} - WAN IP address of this computer ($(cat /etc/hostname)) has been changed from ${WANIP_OLD} to ${WANIP_CURRENT}"

    fi

############################

  function mailSend {

    local EMAIL_FORM="To: ${1}\nFrom: ${EMAIL_SENDER}\nSubject: ${SUBJECT_EMAIL}\n\n${MESSAGE_EMAIL}"

    echo -e "${EMAIL_FORM}" | sendmail -v "${1}"
    if [[ $? -eq 0 ]]; then
      MAIL_SENT="OK"
    else
      if [[ -f "/usr/lib/libresolvconf-override.so" ]] && [[  $ENABLE_FALLBACK_DNS == 1 ]]; then
        SENDMAIL_PRELOAD="LD_PRELOAD=/usr/lib/libresolvconf-override.so $(resolvconfOverrideDNSList)"
        echo -e "${EMAIL_FORM}" | $(eval ${SENDMAIL_PRELOAD} sendmail -v "${1}")
        if [[ $? -eq 0 ]]; then
          MAIL_SENT="OK"
        fi
      fi
    fi

  }

############################

    typeset -A MAIL_SENT_STATUSES

    if [[ "${WANIP_OLD}" != "${WANIP_CURRENT}" ]] || \
    [[ $(cat "${WANIP_LOG}" | wc -l) -eq 1 ]] ; then

      echo -e "${MESSAGE_STDOUT}"

      IFS=$' '
      retry=4
      r=0
      for recipient in $EMAIL_RECIPIENTS; do
        MAIL_SENT="NOK"
        while [[ $r < $retry ]]; do
          mailSend "${recipient}"
          [[ "${MAIL_SENT}" == "OK" ]] && break
          sleep 5
          let r++
        done
        MAIL_SENT_STATUSES+=([${recipient}]="${MAIL_SENT}")
      done
      IFS=

      MAIL_SENT_STATUSES_STR=""
      for email in ${!MAIL_SENT_STATUSES[@]}; do
        MAIL_SENT_STATUSES_STR="${MAIL_SENT_STATUSES_STR}${email}:${MAIL_SENT_STATUSES[$email]},"
      done

      MAIL_SENT_STATUSES_STR=$(echo "${MAIL_SENT_STATUSES_STR}" | sed 's/,$//')

      printf "%-25s%-18s%s\n" "${TIMESTAMP}" "${WANIP_CURRENT}" "${MAIL_SENT_STATUSES_STR}" >> "${WANIP_LOG}"

    fi

  fi

}

############################

checkWANIP
