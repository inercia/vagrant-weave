#!/bin/bash

# where to install Weave to
WEAVE_EXE=/usr/local/bin/weave

# where do we get Weave from
WEAVE_ORIGIN_URL=/weave/src/src/github.com/zettio/weave/weave

# basic debs to install
DEBS_BASIC="apparmor \
curl \
bridge-utils \
conntrack \
ethtool"

# external, host-accessible IP
EXT_IP=$1

# Docker port
PORT=2375

# every container launched on this VM will get an IP address 
# from range 172.17.51.2 – 172.17.51.255
IP=$2
MASK=255.255.255.0

# the bridge device
BRIDGE=bridge0

# certificates (if using TLS with docker)
CA=/etc/docker/certs/ca.pem
CERT=/etc/docker/certs/cert.pem
KEY=/etc/docker/certs/key.pem

# Docker daemon defaults file
DEFAULTS=/etc/default/docker

###################################################################################

if [ ! -f "/var/ssh_setup" ]; then
  echo "[provision] Setting up ssh..."
  mkdir -p /root/.ssh
  cp /vagrant/ssh.d/insecure_rsa  /root/.ssh/id_rsa
  cp /vagrant/ssh.d/ssh_config    /root/.ssh/config
  cat /vagrant/ssh.d/insecure_rsa.pub >> /root/.ssh/authorized_keys
  sudo chmod 700 /root/.ssh
  sudo chmod 600 /root/.ssh/*

  echo -e "\nPermitTunnel yes" >> /etc/ssh/sshd_config
  sudo service ssh restart

  sudo touch /var/ssh_setup
fi

if [ -d /vagrant/certs ] ; then
  echo "[provision] Copying certificates..."
  rm -rf /etc/docker/certs
  cp -R /vagrant/certs /etc/docker/certs
fi

[ ! -f /var/cache/apt/pkgcache.bin ] || \
    /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null
if [ $? -eq 0 ] ; then
  echo "[provision] Needs to apt-get update"
  sudo apt-get update
fi

# Check that HTTPS transport is available to APT
if [ ! -e /usr/lib/apt/methods/https ]; then
  echo "[provision] Getting HTTPS transport for APT"
  sudo apt-get install -y apt-transport-https
  sudo apt-get update
fi

sudo apt-get install -y $DEBS_BASIC

if [ ! -f "/etc/apt/sources.list.d/docker.list" ] ; then
  echo "[provision] Adding the repository to your APT sources..."
  echo "deb https://get.docker.com/ubuntu docker main" > /etc/apt/sources.list.d/docker.list

  echo "[provision] Importing the repository key..."
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
  sudo apt-get update
fi

echo "[provision] Installing Docker..."
sudo apt-get install -y lxc-docker

# echo "[provision] Getting Ubuntu base..."
# sudo docker pull ubuntu

echo "[provision] Installing Weave script..."
sudo cp -f $WEAVE_ORIGIN_URL $WEAVE_EXE
sudo chmod a+x $WEAVE_EXE

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
sleep 1

ORPHANS=`sudo docker images | grep \<none\> | awk '{ print $3 }'` 
for IMAGE in $ORPHANS ; do
  echo "[provision] Removing image $IMAGE..."
  sudo docker rmi $IMAGE
done

if [ -f /weave/images/weave.tar ] ; then
  echo "[provision] Removing old Weave image..."
  sudo docker rm --force weave 2>/dev/null
  sudo docker images zettio/weave | grep zettio/weave && sudo docker rmi -f zettio/weave

  echo "[provision] Importing Weave image..."
  sudo docker load --input /weave/images/weave.tar
fi

if [ -f /weave/images/weavedns.tar ] ; then
  echo "[provision] Removing old Weave-DNS image..."
  sudo docker rm --force weavedns 2>/dev/null
  sudo docker images zettio/weavedns | grep zettio/weavedns && sudo docker rmi -f zettio/weavedns

  echo "[provision] Importing Weave-DNS image..."
  sudo docker load --input /weave/images/weavedns.tar
fi

echo "[provision]"
echo "[provision] ------------------------------------------------"
echo "[provision] Check the Docker in this machine is usable with:"
echo "[provision]"
echo "[provision] $ DOCKER_HOST=tcp://$EXT_IP:$PORT docker info"
echo "[provision]"
echo "[provision] ------------------------------------------------"
