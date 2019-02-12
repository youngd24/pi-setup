#!/bin/bash
################################################################################
#
# firstboot.sh
#
# Script called from rc.local to wait for the network then download and run
# a second stage installer.
#
################################################################################
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
################################################################################
#
# TODO/ISSUES:
#
#   * Should probably fall back to curl if wget fails.
#   * Deal with logging messags a bit more cleanly.
#   * Variablize things more (is that a word?).
#   * Move more to functions and scope variables better.
#
################################################################################


################################################################################
#                              V A R I A B L E S
################################################################################
x=0
maxNetRetries=60
netChkSleepTime=1
ghHost="htts://raw.githubusercontent.com"
setupUrl="$ghHost/youngd24/LabInstall/master/scripts/setup.sh"
dhcpInterface="eth0"
dhcpNet="192.168"


################################################################################
#                              F U N C T I O N S
################################################################################

################################################################################
# Function to check if eth0 is on the correct internal subnet
# This means DHCP worked and we're off the 169.254 net
# This seems to take an average of around 40 seconds on a Pi-3B+
################################################################################
hfNetChk () {
    echo "hfChkNet: checking network"
    ifconfig $dhcpInterface | grep inet | grep -v inet6 | awk '{print $2}'
    local IP=`ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}' | grep -q -F "$dhcpNet"`
    local ret=$?
    return $ret
}



################################################################################
#                                  M A I N
################################################################################

# See if we're on RedHat/CentOS
if [ -f /etc/redhat-release ]; then
    echo "You are on RedHat/Centos, this script is for Raspbian"
    exit 1
else 
    echo "NOT running on RedHat/CentOS, good"
fi

# Make sure we're on Raspbian
DIST=`/usr/bin/lsb_release -i | awk '{print $3}'`
if [ ! $DIST == "Raspbian" ]; then
    echo "While you appear to be on a Deb dist, it's not Raspbian, sorry"
    exit 1
else 
    echo "Running on Raspbian, good"
fi


# Check for successful DHCP on the 192.168 net
# If so move on, else try again up to some number of times
# Why exit 47? Becuase I can. It's not 0.
while ! hfNetChk
do
    if [ "$x" -ge $maxNetRetries ]; then
        echo "timed out"
        exit 47
    else
        x=$((x+1))
        echo "Retry #: $x"
        echo "Sleeping for network for $netChkSleepTime seconds"
        sleep $netChkSleepTime
    fi
done

echo "Got an IP from DHCP after $x seconds, moving on"
echo "Getting stage 2 setup"

# Pull down the setup script
if [ -x "/usr/bin/wget" ]; then
    echo "Retrieving setup script using wget: $setupUrl"
    wget $setupUrl
else
    echo "wget not found, exiting"
fi

# exiter
exit 0
