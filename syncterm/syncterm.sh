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
# SyncTERM auto-compile/install script
# ------------------------------------

printf "\e[92m"; echo '
 ____                  _____ _____ ____  __  __ 
/ ___| _   _ _ __   __|_   _| ____|  _ \|  \/  |
\___ \| | | |  _ \ / __|| | |  _| | |_) | |\/| |
 ___) | |_| | | | | (__ | | | |___|  _ <| |  | |
|____/ \__, |_| |_|\___||_| |_____|_| \_\_|  |_|
       |___/                                    
'; printf "\e[0m"; sleep 2
source ../assets/func.sh
updateinfo

Base_dir
Src_dir

sudo apt install -y libncurses5-dev libsdl1.2-dev build-essential libsdl2-dev
[ $? -ne 0 ] && net_error "SyncTERM apt packages"

wget ${SYNCTERM_SOURCE} -O ${SRC_DIR}/syncterm.tgz

[ $? -ne 0 ] && net_error "SyncTERM sources"

cd ${SRC_DIR}

tar -xf syncterm.tgz
cd syncterm-${SYNCTERM_VERSION}/src/syncterm
sudo make USE_SDL=1 NO_X=1
sudo make install

Cleanup

printf "\e[92m";
echo *** all done ***
printf "\e[0m";

