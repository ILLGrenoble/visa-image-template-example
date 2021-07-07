#!/bin/bash

cat /etc/resolv.conf

apt-get -y update
apt-get -yy upgrade

apt-get -yy install \
    apt-utils \
    autoconf \
    bison \
    build-essential \
    ca-certificates \
    cloud-init \
    curl \
    cmake \
    csh \
    dpkg-dev \
    firefox \
    gedit \
    flex \
    git \
    gnuplot \
    libxm4 \
    jq \
    less \
    libcap-dev \
    libpam0g-dev \
    libssl-dev \
    libtool \
    libx11-dev \
    libxfixes-dev \
    libxml2-dev \
    libxrandr-dev \
    libcurl4-openssl-dev \
    libgfortran3 \
    libpam-dev \
    locales \
    libossp-uuid-dev \
    freerdp2-dev \
    nano \
    ntp \
    openssh-server \
    pkg-config \
    software-properties-common \
    sed \
    sudo \
    supervisor \
    tcsh \
    uuid-runtime \
    vim \
    wget \
    xauth \
    xautolock \
    xfce4 \
    xprintidle \
    xsltproc \
    zip \
    unzip \
    terminator \
    xterm \
    python \
    python-pip \
    python-virtualenv \
    python-pandas \
    python-pyqt5 \
    rsyslog \
    python3 \
    python3-pip \
    python3-venv \
    python3-pandas \
    wget \
    mesa-utils \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    zenity \
    nedit \
    eog \
    libcairo2-dev \
    libjpeg-turbo8-dev \
    libpng-dev \
    libossp-uuid-dev \
    libavcodec-dev \
    libavutil-dev \
    libswscale-dev \
    libfreerdp-dev \
    libpango1.0-dev \
    libssh2-1-dev \
    libvncserver-dev \
    libssl-dev \
    libvorbis-dev \
    libwebp-dev \
    okular \
    qalculate \
    thunar-archive-plugin \
    gnumeric \
    htop \
    gv \
    grace \
    gimp \
    gawk \
    screen \
    liblz4-tool \
    meld \
    bmon \
    ethtool \
    iotop \
    net-tools \
    nmap \
    mc \
    bc \
    shutter


# Import keys for custom repositories
wget -qO - https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

# Custom repositories
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list

# Node.js (version > 8)
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
apt install -yy nodejs

apt-get -y update
apt-get install -yy \
    code

# Remove xscreensaver
apt-get remove -yy xscreensaver

# Clean up packages...
apt clean

# make supervisor conf directory
mkdir -p /etc/supervisor/conf.d
