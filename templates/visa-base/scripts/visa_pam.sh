#!/bin/bash

apt -yy install libpam-dev libcurl4-gnutls-dev libssl-dev check build-essential

cd /tmp

# Build VISA PAM
git clone https://github.com/ILLGrenoble/visa-pam.git
cd visa-pam

cmake .
make
make install


