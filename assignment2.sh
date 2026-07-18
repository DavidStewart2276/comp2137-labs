#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "error: run this with sudo"
    exit 1
fi

echo "starting assignment 2."

# netplan ip fix
grep -q "192.168.16.21/24" /etc/netplan/*.yaml
if [ $? -ne 0 ]; then
    echo "updating netplan ip"
    sed -i 's/192.168.16.[0-9]\{1,3\}\/24/192.168.16.21\/24/g' /etc/netplan/*.yaml
    netplan apply
else
    echo "netplan is already set"
fi

grep -q "192.168.16.21 server1" /etc/hosts
if [ $? -ne 0 ]; then
    echo "updating file"
    sed -i 's/.* server1$/192.168.16.21 server1/' /etc/hosts
fi

echo "doing software updates."
apt-get update -qq

# install apache
dpkg -l | grep -qw apache2
if [ $? -ne 0 ]; then
    echo "installing apache2"
    apt-get install -y apache2 > /dev/null
else
    echo "apache2 is already there"
fi

# install squid
dpkg -l | grep -qw squid
if [ $? -ne 0 ]; then
    echo "installing squid"
    apt-get install -y squid > /dev/null
else
    echo "squid is already there"
fi

echo "adding users..."
users="dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda"

for usr in $users; do
    echo "-> working on $usr"
    
    grep -q "^$usr:" /etc/passwd
    if [ $? -ne 0 ]; then
        useradd -m -s /bin/bash $usr
    fi

    # make ssh dir
    if [ ! -d /home/$usr/.ssh ]; then
        mkdir /home/$usr/.ssh
        chmod 700 /home/$usr/.ssh
        chown $usr:$usr /home/$usr/.ssh
    fi

    if [ ! -f /home/$usr/.ssh/id_rsa ]; then
        su - $usr -c "ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N '' -q"
    fi

    if [ ! -f /home/$usr/.ssh/id_ed25519 ]; then
        su - $usr -c "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -q"
    fi

    touch /home/$usr/.ssh/authorized_keys
    chmod 600 /home/$usr/.ssh/authorized_keys
    chown $usr:$usr /home/$usr/.ssh/authorized_keys
    # dump keys in
    cat /home/$usr/.ssh/id_rsa.pub >> /home/$usr/.ssh/authorized_keys
    cat /home/$usr/.ssh/id_ed25519.pub >> /home/$usr/.ssh/authorized_keys
    
    # clear duplicates
    sort -u /home/$usr/.ssh/authorized_keys -o /home/$usr/.ssh/authorized_keys
done

echo "setting dennis up."
groups dennis | grep -q '\bsudo\b'
if [ $? -ne 0 ]; then
    usermod -aG sudo dennis
fi

specialkey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
grep -q "$specialkey" /home/dennis/.ssh/authorized_keys
if [ $? -ne 0 ]; then
    echo "$specialkey" >> /home/dennis/.ssh/authorized_keys
fi

echo "done."
