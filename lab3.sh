#!/bin/bash

# check for verbose
verb=""
if [ "$1" == "-verbose" ]; then
    verb="-verbose"
fi

echo "doing server1."
scp configure-host.sh remoteadmin@server1-mgmt:/root
if [ $? -ne 0 ]; then
    echo "failed to copy to server1"
else
    ssh remoteadmin@server1-mgmt -- /root/configure-host.sh $verb -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4
fi

# server 2
echo "doing server2."
scp configure-host.sh remoteadmin@server2-mgmt:/root
if [ $? -eq 0 ]; then
    ssh remoteadmin@server2-mgmt -- /root/configure-host.sh $verb -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3
else
    echo "scp failed for server 2"
fi

# fix local hosts
echo "updating local machine"
sudo ./configure-host.sh $verb -hostentry loghost 192.168.16.3
sudo ./configure-host.sh $verb -hostentry webhost 192.168.16.4
