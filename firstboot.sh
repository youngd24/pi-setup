#!/bin/bash
################################################################################
#
# firstboot.sh
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


################################################################################
# VARIABLES
################################################################################
x=0
maxNetRetries=60
netChkSleepTime=1
setupUrl="https://raw.githubusercontent.com/youngd24/LabInstall/master/scripts/setup.sh"


################################################################################
# FUNCTIONS
################################################################################


################################################################################
# function to check if eth0 is on the correct internal subnet
# this means DHCP worked and we're off the 169.254 net
################################################################################
hfNetChk () {
    echo "hfChkNet: checking network"
    ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}'
    IP=`ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}' | grep -q -F "192.168"`
    ret=$?
    return $ret
}



################################################################################
# MAIN
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


# check for successful DHCP on the 192.168 net
# if so move on, else try again up to some number of times
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
    wget $setupUrl
else
    echo "wget not found, exiting"
fi

#
exit 0
