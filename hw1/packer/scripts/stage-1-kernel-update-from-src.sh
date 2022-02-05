#!/bin/bash

set -e

kver=5.5.1

echo "Installing dependencies"
yum install -y wget gcc flex bison ncurses-devel openssl-devel bc elfutils-libelf-devel perl

echo "Downloading and extracting kernel"
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${kver}.tar.xz
tar xf linux-${kver}.tar.xz
rm linux-${kver}.tar.xz
cd linux-${kver}

echo "Makin'"
cp /boot/config-3* /home/vagrant/linux-${kver}/config
yes "" | make oldconfig -j$(nproc)
make -j$(nproc)
make modules -j$(nproc)
make modules_install -j$(nproc)
make install -j$(nproc)

echo "Updating GRUB conf"
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0

echo "Done. Shutting down. Have fun with your buggy new kernel!"
shutdown -r now
