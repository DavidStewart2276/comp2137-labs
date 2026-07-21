#!/bin/bash
trap '' TERM HUP INT

verbose=0
target_name=""
target_ip=""
host_name=""
host_ip=""

while [ "$1" != "" ]; do
    if [ "$1" == "-verbose" ]; then
        verbose=1
    elif [ "$1" == "-name" ]; then
        shift
        target_name=$1
    elif [ "$1" == "-ip" ]; then
        shift
        target_ip=$1
    elif [ "$1" == "-hostentry" ]; then
        shift
        host_name=$1
        shift
        host_ip=$1
    fi
    shift
done

# ---name stuff
if [ "$target_name" != "" ]; then
    myname=$(hostname)
    if [ "$myname" != "$target_name" ]; then
        sed -i "s/$myname/$target_name/g" /etc/hostname
        sed -i "s/$myname/$target_name/g" /etc/hosts
        hostnamectl set-hostname $target_name
        
        logger "hostname changed from $myname to $target_name"
        [ $verbose -eq 1 ] && echo "changed hostname to $target_name"
    else
        if [ $verbose -eq 1 ]; then echo "hostname is already $target_name"; fi
    fi
fi

# -- ip
if [ -n "$target_ip" ]; then
    ip a | grep -q "$target_ip"
    if [ $? -ne 0 ]; then
        sed -i "s/192.168.16.[0-9]\{1,3\}/$target_ip/g" /etc/netplan/*.yaml
        netplan apply
        
        curr=$(hostname)
        sed -i "s/.* $curr$/$target_ip $curr/g" /etc/hosts
        
        logger "changed ip address to $target_ip"
        if [ $verbose -eq 1 ]; then
            echo "changed ip address to $target_ip"
        fi
    else
        [ $verbose -eq 1 ] && echo "ip is already set to $target_ip"
    fi
fi

# ------------------ host entry
if [ "$host_name" != "" ] && [ "$host_ip" != "" ]; then
    grep -q "$host_ip $host_name" /etc/hosts
    if [ $? -ne 0 ]; then
        grep -q "$host_name" /etc/hosts
        if [ $? -eq 0 ]; then
            sed -i "s/.*$host_name.*/$host_ip $host_name/g" /etc/hosts
        else
            echo "$host_ip $host_name" >> /etc/hosts
        fi
        
        logger "updated host entry for $host_name with ip $host_ip"
        if [ $verbose -eq 1 ]; then
            echo "updated hosts file with $host_name $host_ip"
        fi
    else
        if [ $verbose -eq 1 ]; then
            echo "host entry for $host_name is already correct"
        fi
    fi
fi
