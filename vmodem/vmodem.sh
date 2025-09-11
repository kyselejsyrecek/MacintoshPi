#!/bin/bash
# --------------------------------------------------------
# MacintoshPi
# --------------------------------------------------------
# It is a small project that allows running full-screen
# versions of Apple's Mac OS 7, 8 and 9 with audio,
# active online connection and modem emulation under
# Raspberry Pi. All that without the window manager,
# and entirely from the CLI / Raspberry Pi OS Lite level.
# --------------------------------------------------------
# Author: Jaroslaw Mazurkiewicz  /  jaromaz
# www: https://jm.iq.pl  e-mail: jm at iq.pl
# --------------------------------------------------------
# Virtual Modem - auto-compile/install script
# -------------------------------------------

printf "\e[92m"; echo '
** MacintoshPi
__     ___      _               _    __  __           _                
\ \   / (_)_ __| |_ _   _  __ _| |  |  \/  | ___   __| | ___ _ __ ___  
 \ \ / /| |  __| __| | | |/ _` | |  | |\/| |/ _ \ / _` |/ _ \  _ ` _ \ 
  \ V / | | |  | |_| |_| | (_| | |  | |  | | (_) | (_| |  __/ | | | | |
   \_/  |_|_|   \__|\__,_|\__,_|_|  |_|  |_|\___/ \__,_|\___|_| |_| |_|
                                                                          
'; printf "\e[0m"; sleep 2
source ../assets/func.sh
updateinfo
sudo apt install -y raspberrypi-kernel-headers build-essential
[ $? -ne 0 ] && net_error "Virutal Modem apt packages"
Base_dir
Src_dir

# Installation of tcpser.
wget ${TCPSER_SOURCE} -O ${SRC_DIR}/tcpser-${TCPSER_VERSION}.tar.gz
[ $? -ne 0 ] && net_error "tcpser sources"
cd ${SRC_DIR}
tar zxf tcpser-${TCPSER_VERSION}.tar.gz
cd tcpser-${TCPSER_VERSION}
make
sudo cp tcpser /usr/local/bin/
sudo chmod 655 /usr/local/bin/tcpser

# Installation of tty0tty.
wget ${TTY0TTY_SOURCE} -O ${SRC_DIR}/tty0tty-${TTY0TTY_VERSION}.tar.gz
[ $? -ne 0 ] && net_error "tty0tty sources"
cd ${SRC_DIR}
tar zxf tty0tty-${TTY0TTY_VERSION}.tar.gz
cd tty0tty-${TTY0TTY_VERSION}/module
make
sudo cp tty0tty.ko /lib/modules/$(uname -r)/kernel/drivers/misc/
sudo depmod
sudo modprobe tty0tty
sudo chmod 666 /dev/tnt*
echo tty0tty | sudo tee -a /etc/modules

sudo touch /var/log/vmodem.log
sudo chmod 666 /var/log/vmodem.log

# Virtual Modem configuration file: /etc/vmodem.conf
cat << EOF > vmodem.conf
# Default settings for MacintoshPi Virtual Modem.

# Valid BPS values: 300, 1200, 2400 (default), 9600, 19200, 38400
BPS=2400

# Log level 0-7
LOG_LEVEL=7

# Log file location
LOG_FILE=/var/log/vmodem.log
EOF

# Virtual Modem systemd service
cat << EOF > vmodem.service
[Unit]

Description=Virtual Modem MacintoshPi
After=network.target

[Service]
EnvironmentFile=-/etc/vmodem.conf
ExecStart=/usr/local/bin/tcpser -d /dev/tnt0 -S \$BPS -l \$LOG_LEVEL -L \$LOG_FILE
ExecStartPre=/usr/bin/chmod 666 /dev/tnt0
ExecStartPre=/usr/bin/chmod 666 /dev/tnt1
ExecStartPost=/bin/sleep 1
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo mv vmodem.service /lib/systemd/system
sudo mv vmodem.conf /etc
sudo chmod 666 /etc/vmodem.conf

Cleanup

sudo systemctl enable --now vmodem.service

echo "** vmodem ready **"
echo "** You must repeat this proces every kernel update **"
echo "** Run: sudo systemctl [ start | stop | reset ] vmodem **"
echo "** You can change modem speed at: /etc/vmodem.conf **"


