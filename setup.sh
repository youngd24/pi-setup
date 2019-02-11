#!/bin/bash


sudo apt-get update
sudo apt-get -y install uucp ntpdate
sudo apt-get -y upgrade
reboot


Set the hostname
    MAC=`ifconfig eth0 | grep ether | awk '{print $2}' | awk -F: '{print $5$6}'`
    echo "pi-$MAC" > /etc/hostname
    cat /etc/hosts | sed -e "s/raspberrypi/pi-$MAC/g" > /tmp/hosts && mv /tmp/hosts /etc/hosts

Set keyboard language
    cat /etc/default/keyboard | sed -e 's/XKBLAYOUT="gb"/XKBLAYOUT="us"/g' > /tmp/keyboard && mv /tmp/keyboard /etc/default/keyboard
    sudo dpkg-reconfigure keyboard-configuration --frontend=noninteractive

Set timezone
    echo "America/Chicago" > /etc/timezone
    rm -f /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata
    ntpdate pool.ntp.org

Set wifi region
    echo "country=US" >> /etc/wpa_supplicant/wpa_supplicant.conf

set up log forwarding
    echo "*.*   @@xlog01:514" > /etc/rsyslog.d/loghost.conf

Create the sysadmin account
    useradd -c "System Admin" \
            -d /home/sysadmin \
            -G dialout,sudo,users,netdev \
            -u 2323 \
            -s /bin/bash \
            --create-home \
            sysadmin
    echo "sysadmin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_sysadmin-nopasswd

