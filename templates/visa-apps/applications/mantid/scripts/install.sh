#!/bin/bash
echo "Installing mantid..."

wget -O - http://apt.isis.rl.ac.uk/2E10C193726B7213.asc | apt-key add -
apt-add-repository "deb [arch=amd64] http://apt.isis.rl.ac.uk $(lsb_release -c | cut -f 2) main"
apt-add-repository "deb [arch=amd64] http://apt.isis.rl.ac.uk $(lsb_release -c | cut -f 2)-testing main"
apt-add-repository ppa:mantid/mantid

apt-get -y update
apt-get -yy install mantid

echo "Finished installing mantid"
