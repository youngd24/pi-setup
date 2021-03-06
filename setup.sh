#!/bin/bash
###############################################################################
#
# setup.sh
#
# Second stage setup script, modify as you see fit for local conditions.
# Meant to be got(ten) from an HTTP server.
#
###############################################################################
#
###############################################################################
#
# Copyright (C) 2018 Darren Young <darren@yhlsecurity.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
###############################################################################
#
# TODO/ISSUES:
#
#   * Localize variables more in functions, global namespace pollution angers
#     me to no end.
#   * Added my usual RedHat/CentOS/Raspbian detection.
#   * Variablize more things, especially command locations.
#
###############################################################################


###############################################################################
#                             V A R I A B L E S
###############################################################################

# Used by dpkg-reconfigure to not display a UI
DEBIAN_FRONTEND="noninteractive"; export DEBIAN_FRONTEND

# Should probably add getopt() stuff for this
DEBUG="true"                                # Produces copious messaging

# Locations
#LOGDIR="$DIRNAME/../log"
#LIBDIR="$DIRNAME/../lib"
#CRONTABDIR="/var/spool/cron/crontabs"
#TMPLDIR="$DIRNAME/../tmpl"
#BACKUPDIR="/backup"

LOGFILE="setup.log"
FIRSTBOOTFILE="/.firstboot"

# Host name setting locations
HOSTNAME=""
HOSTSFILE="/etc/hosts"
HOSTNAMEFILE="/etc/hostname"

# Time/date stuff
LOCALTIMEFILE="/etc/localtime"
TIMEZONEFILE="/etc/timezone"
TIMEZONE="America/Chicago"

###############################################################################
#                             F U N C T I O N S
###############################################################################

###############################################################################
# Print a log formatted message
# If LOGFILE is defined the output will go there otherwise it goes to STDOUT
###############################################################################
function logmsg() {
    if [[ -z "$1" ]]
    then
        errmsg "Usage: logmsg <message>"
        return 0
    else
        local MESSAGE=$1
        if [[ ! -z $LOGFILE ]]; then
            local NOW=`date +"%b %d %Y %T"`
            echo $NOW $1 >> $LOGFILE
        else
            local NOW=`date +"%b %d %Y %T"`
            msg "$NOW $MESSAGE"
            return 0
        fi
    fi
}


###############################################################################
# Print a message to stderr so it doens't become part of a function return
###############################################################################
function errmsg() {
    if [[ -z "$1" ]]; then
        logmsg "Usage: errmsg <message>"
        return 0
    else
        logmsg "ERROR: $1"
        return 1
    fi
}


###############################################################################
# Print a message if global $DEBUG is set to true
###############################################################################
function debug() {
    if [[ -z "$1" ]]
    then
        errmsg "Usage: debug <message>"
        return 0
    else
        if [ "$DEBUG" == "true" ]
        then
            local message="$1"
            logmsg "DEBUG: $message"
            return 1
        else
            return 1
        fi
    fi
}


###############################################################################
# Run a command (relatively safely)
# If you want to add additional security for stuff, add it here
###############################################################################
function run_command() {
    debug "${FUNCNAME[0]}: entering"

    if [[ -z "$1" ]]
    then
        errmsg "Usage: run_command <command>"
        return 0
    else
        local CMD="$1"
        debug "CMD: $CMD"
        RET=$($CMD >> $LOGFILE 2>>$LOGFILE)
        RETVAL=$?

        debug "return: $RET"
        debug "retval: $RETVAL"

        if [[ $RETVAL != 0 ]]; then
            logmsg "Failed to run command"
            return 0
        else
            debug "SUCCESS"
            return 1
    fi
        return 1
    fi
}


###############################################################################
# Update apt
###############################################################################
function apt_update() {
    debug "${FUNCNAME[0]}(): entering"
    logmsg "Updating apt"
    local CMD="apt-get -q -y update"
    logmsg "Running command $CMD"
    run_command "$CMD"
}


###############################################################################
# Apt cleanup
###############################################################################
function apt_cleanup() {
    debug "${FUNCNAME[0]}(): entering"
    logmsg "Cleaning up apt"
    local CMD="apt autoremove"
    logmsg "Running command $CMD"
    run_command "$CMD"
}


###############################################################################
# Install a package using apt
###############################################################################
function apt_install() {
    debug "${FUNCNAME[0]}(): entering"
    if [[ -z "$1" ]]
    then
        errmsg "Usage: apt_install <package>"
        return 0
    else
        local PKG="$1"
        debug "PKG: $PKG"
        logmsg "Installing system package: $PKG"
        local CMD="apt-get -q -y install $PKG"
        logmsg "Running command '$CMD'"
        run_command "$CMD"
        return 1
    fi
}


###############################################################################
# Set the local hostname based off the mac address. Do this in the hostname
# and hosts file
###############################################################################
function set_hostname() {
    debug "${FUNCNAME[0]}(): entering"
    local MAC=`ifconfig eth0 | grep ether | awk '{print $2}' | awk -F: '{print $5$6}'`
    local HOSTNAME="pi-$MAC"

    # Forcibly set the hostname in the file, who cares if it's already there
    logmsg "Setting hostname => $HOSTNAME"
    echo $HOSTNAME > $HOSTNAMEFILE

    RET=$(grep kali $HOSTSFILE)
    RETVAL=$?
    if [[ $RETVAL = 0 ]]; then
        logmsg "Modifying $HOSTSFILE"
        echo "127.0.0.1       $HOSTNAME   localhost" > /tmp/hosts.tmp
        cat $HOSTSFILE | grep -v kali >> /tmp/hosts.tmp
        run_command "mv /tmp/hosts.tmp $HOSTSFILE"
        logmsg "Done with $HOSTSFILE"
    else
        logmsg "$HOSTSFILE already set for this hostname"
    fi

    return 1
}


###############################################################################
# Set the timezone of the machine
###############################################################################
function set_timezone() {
    debug "${FUNCNAME[0]}(): entering"

    if [[ -z "$1" ]]; then
        logmsg "You have to pass me a timezone like America/Chicago"
        return 0
    else
        local TZ="$1"
        logmsg "Setting timezone to $TZ in $TIMEZONEFILE"
        echo $TZ > $TIMEZONEFILE

        logmsg "Removing localtime file $LOCALTIMEFILE"
        run_command "rm -f $LOCALTIMEFILE"

        logmsg "Reconfiguring tzdata package"
        run_command "dpkg-reconfigure -f noninteractive tzdata"

        logmsg "Setting date/time via NTP"
        run_command "ntpdate pool.ntp.org"

        logmsg "Done setting timezone"
        return 1
    fi
}


###############################################################################
#
###############################################################################
#sudo apt-get update
#sudo apt-get -y install uucp ntpdate
#sudo apt-get -y upgrade


#Set the hostname
#    cat /etc/hosts | sed -e "s/raspberrypi/pi-$MAC/g" > /tmp/hosts && mv /tmp/hosts /etc/hosts

#Set keyboard language
#    cat /etc/default/keyboard | sed -e 's/XKBLAYOUT="gb"/XKBLAYOUT="us"/g' > /tmp/keyboard && mv /tmp/keyboard /etc/default/keyboard
#    sudo dpkg-reconfigure keyboard-configuration --frontend=noninteractive

#Set timezone
#    echo "America/Chicago" > /etc/timezone
#    rm -f /etc/localtime
#    dpkg-reconfigure -f noninteractive tzdata
#    ntpdate pool.ntp.org

#Set wifi region
#    echo "country=US" >> /etc/wpa_supplicant/wpa_supplicant.conf

#set up log forwarding
#    echo "*.*   @@xlog01:514" > /etc/rsyslog.d/loghost.conf

#Create the sysadmin account
#    useradd -c "System Admin" \
#            -d /home/sysadmin \
#            -G dialout,sudo,users,netdev \
#            -u 2323 \
#            -s /bin/bash \
#            --create-home \
#            sysadmin
#    echo "sysadmin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_sysadmin-nopasswd

