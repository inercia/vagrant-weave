#!/bin/bash
# execute on vm1

# external, host-accessible IP
EXT_IP=192.168.40.11

# Docker port
PORT=2375

# every container launched on this VM will get an IP address 
# from range 172.17.51.2 – 172.17.51.255
IP=172.17.51.1
MASK=255.255.255.0

# the bridge device
BRIDGE=bridge0

# certificates (if using TLS)
CA=/etc/docker/certs/ca.pem
CERT=/etc/docker/certs/cert.pem
KEY=/etc/docker/certs/key.pem

# Docker daemon defaults file
DEFAULTS=/etc/default/docker

################################################

brctl show | grep $BRIDGE >/dev/null 2>/dev/null
if [ $? -eq 1 ] ; then
	echo "[provision] Setting up $BRIDGE"
	sudo brctl addbr $BRIDGE
fi
sudo ifconfig $BRIDGE $IP netmask $MASK

grep "DOCKER_OPTS" "$DEFAULTS" | grep "$BRIDGE" >/dev/null 2>/dev/null
if [ $? -eq 1 ] ; then
	echo "[provision] Setting Docker daemon flags..."
	echo "DOCKER_OPTS=\"-b=$BRIDGE -H tcp://0.0.0.0:$PORT -H unix:///var/run/docker.sock --tlsverify=false\"" >> $DEFAULTS
fi

echo "[provision] Restarting Docker"
sudo service docker restart

echo "[provision] Check VM is reachable with:"
echo "[provision]"
echo "[provision] $ DOCKER_HOST=tcp://$EXT_IP:$PORT docker info"
echo "[provision]"


