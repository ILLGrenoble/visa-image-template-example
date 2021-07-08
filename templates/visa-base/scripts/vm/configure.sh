#!/bin/bash

cp /etc/X11/xrdp/xorg.conf /etc/X11
sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config
sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini

locale-gen en_US.UTF-8
echo "xfce4-session" > /etc/skel/.Xclients

echo "Europe/Paris" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Change the default xfce configuration directory
echo 'export XDG_CONFIG_HOME="$HOME/.visa"' >> /etc/profile

# set keyboard for all sh users
echo "export QT_XKB_CONFIG_ROOT=/usr/share/X11/locale" >> /etc/profile

# Don't ask the user to use default settings ... just use it
echo 'export XFCE_PANEL_MIGRATE_DEFAULT=true' >> /etc/profile

# VISA configuration 

mkdir /etc/visa
chmod -R 644 /etc/visa

# This file is accessible only by the owner and owned by root.root
chmod 600 /etc/visa/public.pem

# Not sure if necessary ?
pam-auth-update --enable mkhomedir

# Put this into separate file
cd /tmp 

wget https://github.com/apache/guacamole-server/archive/1.2.0.tar.gz

tar -xvvf 1.2.0.tar.gz

cd guacamole-server-1.2.0/

autoreconf -fi

./configure --with-init-dir=/etc/init.d --with-rdp

make

make install

ldconfig

systemctl enable guacd


# Disable suspend, hibernate etc.
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

