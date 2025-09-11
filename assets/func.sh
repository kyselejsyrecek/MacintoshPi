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
# MacintoshPi functions
# --------------------------------------------------------

VERSION="1.4.1"

# Dirs
ASSETS_DIR="$( realpath $( dirname "${BASH_SOURCE}" ) )"
BASE_DIR="/usr/share/macintoshpi"
CONF_DIR="/etc/macintoshpi"
WAV_DIR="${BASE_DIR}/sounds"
SRC_DIR="${BASE_DIR}/src"

# Basilisk II
BASILISK_REPO="https://github.com/kanjitalk755/macemu"
BASILISK_FILE="/usr/local/bin/BasiliskII"
BASILISK_REVISION="44bf57e79151d11af6f2c30997f507313e8751cf"

# SheepShaver
SHEEPSHAVER_REPO=${BASILISK_REPO}
SHEEPSHAVER_FILE="/usr/local/bin/SheepShaver"
SHEEPSHAVER_REVISION="44bf57e79151d11af6f2c30997f507313e8751cf"

# SDL2
SDL2_VERSION="2.32.10"
SDL2_SONAME="0.3200.10"
SDL2_SOURCE="https://www.libsdl.org/release/SDL2-${SDL2_VERSION}.tar.gz"
SDL2_FILE="/usr/local/lib/libSDL2-2.0.so.${SDL2_SONAME}"

# SDL2 Image
SDL2_IMAGE_VERSION="2.0.5"
SDL2_IMAGE_SONAME="0.5.0"
SDL2_IMAGE_SOURCE="https://www.libsdl.org/projects/SDL_image/release/SDL2_image-${SDL2_IMAGE_VERSION}.tar.gz"
SDL2_IMAGE_FILE="/usr/local/lib/libSDL2_image-2.0.so.${SDL2_IMAGE_SONAME}"

# VICE
VICE_VERSION="3.9"
VICE_SOURCE="https://downloads.sourceforge.net/project/vice-emu/releases/vice-${VICE_VERSION}.tar.gz"

# CDEmu
CDEMU_REPO="https://github.com/cdemu/cdemu.git"
CDEMU_REVISION="vhba-module-20250329"

# Vmodem
TCPSER_VERSION="1.1.4"
TCPSER_SOURCE="https://github.com/go4retro/tcpser/archive/refs/tags/v${TCPSER_VERSION}.tar.gz"
TTY0TTY_VERSION="1.3.0"
TTY0TTY_SOURCE="https://github.com/freemed/tty0tty/archive/refs/tags/${TTY0TTY_VERSION}.tar.gz"

# SyncTERM
SYNCTERM_VERSION="1.6"
SYNCTERM_SOURCE="https://sourceforge.net/projects/syncterm/files/syncterm/syncterm-${SYNCTERM_VERSION}/syncterm-${SYNCTERM_VERSION}-src.tgz/download"

# HDD images and ROMs
HDD_IMAGES="https://homer-retro.space/appfiles"
ASOFT="${HDD_IMAGES}/as/asoft.tar.gz"
ROM4OS[7]="https://github.com/macmade/Macintosh-ROMs/raw/18e1d0a9756f8ae3b9c005a976d292d7cf0a6f14/Performa-630.ROM"
ROM4OS[8]="https://github.com/macmade/Macintosh-ROMs/raw/main/Quadra-650.ROM"
ROM4OS[9]="https://smb4.s3.us-west-2.amazonaws.com/sheepshaver/apple_roms/newworld86.rom.zip"

# Parse command line arguments for debug mode.
for arg in "$@"; do
    case $arg in
        --debug)
            export DEBUG=1
            shift
            ;;
    esac
done

# Functions
function usercheck {
  return 0
  [ $USER != "pi" ] && echo 'Run this script as the "pi" user.' && exit
}

function updateinfo {
parent=$(cat /proc/$PPID/comm)
if [ "$parent" != "build_all.sh" ]; then
cat <<EOF

* WARNING: 
To install this software, you must first update and reboot your
system. If you want to perform these steps now, then press "y" key.
If your system is up to date and rebooted, then press any other
key or wait 30 seconds.

EOF

read -t 30 -n 1 -s updinfo
[ "$updinfo" = "y" ] && sudo apt update && sudo apt upgrade -y && sudo reboot && exit
fi
}


function mtimer {
for i in {10..1}; do printf "$i ... "; sleep 1; done
echo
}

function installinfo {
cat << EOF
* INFO: 
The build and installation process will take approximately two hours.

EOF
mtimer
}


function net_error {
    echo
    echo "***********"
    echo
    echo "Error - can't download: $1"
    echo "Check your Internet connection and try again later."
    echo
    echo "If you still feel its a bug, then please create an issue here:"
    echo "https://github.com/jaromaz/MacintoshPi/issues/new"
    echo
    parent=$(cat /proc/$PPID/comm)
    [ "$parent" == "build_all.sh" ] && killall -q build_all.sh
    exit
}




function Base_dir {
   [ -d ${BASE_DIR} ] || ( sudo mkdir -p ${BASE_DIR} && sudo chown $USER:$USER ${BASE_DIR} )
}


function Src_dir {
   [ -d ${SRC_DIR} ] || ( sudo mkdir -p ${SRC_DIR} && sudo chown $USER:$USER ${SRC_DIR} )
}

function Cleanup {
    # Only clean up sources and built files if DEBUG is not set to "1".
    if [ "${DEBUG:-0}" != "1" ]; then
        rm -rf ${SRC_DIR}
    else
        echo "DEBUG mode: Preserving source directory ${SRC_DIR}"
    fi
}

function Build_NetDriver {

printf "\e[95m"; echo '
 _   _      _   ____       _
| \ | | ___| |_|  _ \ _ __(_)_   _____ _ __
|  \| |/ _ \ __| | | |  __| \ \ / / _ \  __|
| |\  |  __/ |_| |_| | |  | |\ V /  __/ |
|_| \_|\___|\__|____/|_|  |_| \_/ \___|_|

'; printf "\e[0m"; sleep 2

cd Linux/NetDriver
make
sudo make dev
sudo chown $USER /dev/sheep_net
sudo make install
sudo modprobe sheep_net

}


function Build_SheepShaver {

printf "\e[95m"; echo '
 ____  _                    ____  _
/ ___|| |__   ___  ___ _ __/ ___|| |__   __ ___   _____ _ __
\___ \|  _ \ / _ \/ _ \  _ \___ \|  _ \ / _` \ \ / / _ \  __|
 ___) | | | |  __/  __/ |_) |__) | | | | (_| |\ V /  __/ |
|____/|_| |_|\___|\___| .__/____/|_| |_|\__,_| \_/ \___|_|
                      |_|
'; printf "\e[0m"; sleep 2

mkdir -p ${SRC_DIR} 2>/dev/null
cd ${SRC_DIR}
rm -rf macemu 2>/dev/null
git clone ${BASILISK_REPO}
cd ${SRC_DIR}/macemu
git checkout ${SHEEPSHAVER_REVISION}
cd ${SRC_DIR}/macemu/SheepShaver
make links
cd src/Unix

patch -p4 < "${ASSETS_DIR}/SheepShaver-RPi-fix-natmem-offset.patch"
NO_CONFIGURE=1 ./autogen.sh &&
./configure --enable-sdl-audio \
            --enable-sdl-video \
            --enable-sdl-framework \
            --without-gtk \
            --without-mon \
            --without-esd \
            --enable-addressing=direct,0x10000000

make -j3
sudo make install

modprobe --show sheep_net 2>/dev/null || Build_NetDriver

echo "no-sighandler" | sudo tee /etc/directfbrc
grep -q mmap_min_addr /etc/sysctl.conf || \
echo "vm.mmap_min_addr = 0" | sudo tee -a /etc/sysctl.conf

Cleanup

}



function Build_BasiliskII {

printf "\e[95m"; echo '
 ____            _ _ _     _      ___ ___
| __ )  __ _ ___(_) (_)___| | __ |_ _|_ _|
|  _ \ / _` / __| | | / __| |/ /  | | | |
| |_) | (_| \__ \ | | \__ \   <   | | | |
|____/ \__,_|___/_|_|_|___/_|\_\ |___|___|

'; printf "\e[0m"; sleep 2

sudo apt install -y libmpfr-dev
[ $? -ne 0 ] && net_error "Basilisk II apt packages"

mkdir -p ${SRC_DIR} 2>/dev/null

cd ${SRC_DIR}
git clone ${BASILISK_REPO}
cd ${SRC_DIR}/macemu
git checkout ${BASILISK_REVISION}
cd ${SRC_DIR}/macemu/BasiliskII/src/Unix/
NO_CONFIGURE=1 ./autogen.sh &&
./configure --enable-sdl-audio --enable-sdl-framework \
            --enable-sdl-video --disable-vosf \
            --without-mon --without-esd --without-gtk &&
make -j3
sudo make install

modprobe --show sheep_net 2>/dev/null || Build_NetDriver

Cleanup

}


function Build_SDL2 {

printf "\e[95m"; echo '
 ____  ____  _     ____
/ ___||  _ \| |   |___ \
\___ \| | | | |     __) |
 ___) | |_| | |___ / __/
|____/|____/|_____|_____|

'; printf "\e[0m"; sleep 2

sudo apt install -y automake gobjc libudev-dev xa65 build-essential byacc texi2html flex \
                    libreadline-dev libxaw7-dev texinfo libxaw7-dev libgtk2.0-cil-dev \
                    libgtkglext1-dev libpulse-dev bison libnet1 libnet1-dev libpcap0.8 \
                    libpcap0.8-dev libvte-dev libasound2-dev raspberrypi-kernel-headers

[ $? -ne 0 ] && net_error "SDL2 apt packages"

Base_dir
mkdir -p ${SRC_DIR}

[ -d "/home/$USER/Downloads" ] || mkdir /home/$USER/Downloads

wget ${SDL2_SOURCE} -O - | tar -xz -C ${SRC_DIR}
[ $? -ne 0 ] && net_error "SDL2 sources"

cd ${SRC_DIR}/SDL2-${SDL2_VERSION} && 
./configure --host=arm-raspberry-linux-gnueabihf \
            --disable-video-opengl \
            --disable-video-x11 \
            --disable-pulseaudio \
            --disable-esd \
            --disable-video-wayland \
            --enable-video-kmsdrm \
            --enable-alsa \
            --enable-audio &&
make -j3
sudo make install

Cleanup

}


function Build_SDL2_image {

printf "\e[95m"; echo '
 ____  ____  _     ____      _
/ ___||  _ \| |   |___ \    (_)_ __ ___   __ _  __ _  ___
\___ \| | | | |     __) |   | | `_ ` _ \ / _` |/ _` |/ _ \
 ___) | |_| | |___ / __/    | | | | | | | (_| | (_| |  __/
|____/|____/|_____|_____|   |_|_| |_| |_|\__,_|\__, |\___|
                                              |___/

'; printf "\e[0m"; sleep 2

sudo apt install -y libjpeg-dev libpng-dev libtiff-dev libwebp-dev

[ $? -ne 0 ] && net_error "SDL2_image apt packages"

Base_dir
mkdir -p ${SRC_DIR}

wget ${SDL2_IMAGE_SOURCE} -O - | tar -xz -C ${SRC_DIR}
[ $? -ne 0 ] && net_error "SDL2_image sources"

cd ${SRC_DIR}/SDL2_image-${SDL2_IMAGE_VERSION} && 
./configure --host=arm-raspberry-linux-gnueabihf &&
make -j3
sudo make install

Cleanup

}


function Launcher {
    if ! [ -d ${CONF_DIR} ]; then
        mkdir -p ${SRC_DIR} 2>/dev/null
        cd ../launcher
        sudo mkdir ${CONF_DIR}
        sudo cp -r config/* ${CONF_DIR}
        sudo cp mac /usr/bin
        # Chimes wav files
        wget -O ${SRC_DIR}/chimes.zip ${HDD_IMAGES}/chimes.zip
        unzip -d ${SRC_DIR} ${SRC_DIR}/chimes.zip
        [ $? -ne 0 ] && net_error "Chimes wav files"
        sudo mkdir -p ${WAV_DIR}
        for i in os7-342 os7-384 os7-480 os7-600 os8-480 \
                 os8-600 os9-480 os9-600 os9-768; do
            sudo mkdir ${CONF_DIR}/${i}${WAV_DIR}
        done
        sudo cp ${SRC_DIR}/chimes/m1.wav ${CONF_DIR}/os7-342${WAV_DIR}/os7.wav
        sudo cp ${SRC_DIR}/chimes/cc.wav ${CONF_DIR}/os7-384${WAV_DIR}/os7.wav
        sudo cp ${SRC_DIR}/chimes/pe.wav ${CONF_DIR}/os7-480${WAV_DIR}/os7.wav
        sudo cp ${SRC_DIR}/chimes/pe.wav ${CONF_DIR}/os7-600${WAV_DIR}/os7.wav
        sudo cp ${SRC_DIR}/chimes/pe.wav ${CONF_DIR}/os8-480${WAV_DIR}/os8.wav
        sudo cp ${SRC_DIR}/chimes/pm.wav ${CONF_DIR}/os8-600${WAV_DIR}/os8.wav
        sudo cp ${SRC_DIR}/chimes/pm.wav ${CONF_DIR}/os9-480${WAV_DIR}/os9.wav
        sudo cp ${SRC_DIR}/chimes/g3.wav ${CONF_DIR}/os9-600${WAV_DIR}/os9.wav
        sudo cp ${SRC_DIR}/chimes/g3.wav ${CONF_DIR}/os9-768${WAV_DIR}/os9.wav
        sudo cp ${SRC_DIR}/chimes/c2.wav ${WAV_DIR}/os7.wav
        sudo cp ${SRC_DIR}/chimes/pm.wav ${WAV_DIR}/os8.wav
        sudo cp ${SRC_DIR}/chimes/g3.wav ${WAV_DIR}/os9.wav
        Cleanup
    fi
}


function MacOS_version {
    Base_dir
    VER=$1
    MACOS_DIR=${BASE_DIR}/macos${VER}
    HDD_IMAGE=${HDD_IMAGES}/${VER}/hdd.dsk.gz
    MACOS_CONFIG=${MACOS_DIR}/macos${VER}.cfg
    ROM=${ROM4OS[$1]}
    rm -rf $MACOS_DIR 2>/dev/null
    mkdir $MACOS_DIR 2>/dev/null
    Launcher
}


function logo {

    logotype=( " __  __            _       _            _    "
               '|  \/  | __ _  ___(_)_ __ | |_ ___  ___| |__ '
               '| |\/| |/ _  |/ __| |  _ \| __/ _ \/ __|  _ \'
               '| |  | | (_| | (__| | | | | || (_) \__ \ | | |'
               '|_|  |_|\__,_|\___|_|_| |_|\__\___/|___/_| |_|'
             );

    clear && echo
    for i in {0..9}; do
        [ $(($i % 2)) -gt "0" ] && printf "\e[93m" || printf "\e[96m"
        printf "${logotype[${i}]}"
    done
    echo
    for i in {1..47}; do printf ' '; done
    printf "\e[90m"
    echo "v.${VERSION}"
    printf "\e[0m\n"
}


function Asoft {
    if ! [ -d ${BASE_DIR}/asoft ] ; then
        wget -c $ASOFT -O - | tar -xz -C $BASE_DIR
        [ $? -ne 0 ] && net_error "asoft"
    fi
}
