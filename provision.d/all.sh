#!/bin/bash

# where to install Weave to
WEAVE_EXE=/usr/local/bin/weave

# where do we get Weave from
WEAVE_ORIGIN_URL=https://raw.githubusercontent.com/zettio/weave/master/weave

# basic debs to install
DEBS_BASIC="apparmor \
curl \
bridge-utils \
mininet \
golang-go \
golang-go.net-dev \
golang-go.tools \
golang-go.tools-dev \
conntrack \
ethtool"

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

sudo apt-get update

# Check that HTTPS transport is available to APT
if [ ! -e /usr/lib/apt/methods/https ]; then
  echo "[provision] Getting HTTPS transport for APT"
  sudo apt-get install -y apt-transport-https
  sudo apt-get update
fi

sudo apt-get install -y $DEBS_BASIC

if [ ! -f "/etc/apt/sources.list.d/docker.list" ]; then
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

echo "[provision] Installing Weave..."
if [[ "$(sudo curl $WEAVE_ORIGIN_URL -z $WEAVE_EXE -o $WEAVE_EXE -s -L -w %{http_code})" == "200" ]]; then
  echo "[provision] Weave has been updated"
  sudo chmod a+x $WEAVE_EXE
fi


