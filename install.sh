#!/bin/sh
# Released to the public domain.
#
# raspi-config # locale

cat << E_O_F
This is a pseudo installer.
Please consider it as a guide for a dedicated installation.
To make the easiest possible turn-key dedicated STFX effects-slave,
executing all of these commands will overwrite key system files.

So this has been dissabled for you safety.

If you REALLY want to do so then edit this installer to run.
E_O_F

exit 0 ; # comment out this line to run the installer as-is.

if [ "$(id -u)" = "0" ] ; then
  printf "Please run this as the normal pi user, not root.\n"
  exit 1
fi

# Because ~ becomes /root/ when sudo-ing:
PH=/home/pi ; export PH

# remove unwanted stuff, probably some redundancy here:
sudo tasksel remove desktop
sudo apt-get -y remove task-desktop 
sudo apt-get -y remove x-window-system-core xserver-xorg 
sudo apt-get -y remove x11-common midori lxde 
sudo apt-get -y autoremove 
sudo sh -c 'dpkg -l | egrep "^rc" | cut -d " " -f 3 | xargs dpkg --purge'
sudo apt-get clean
sudo rm `find /var/log/ -type f`
rm -rf ${PH}/python_games

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get install -y hostapd udhcpd
sudo apt-get install -y samba samba-common-bin
sudo apt-get install -y sox
sudo apt-get install -y fbi
sudo apt-get install -y cec-utils
sudo apt-get install -y imagemagick
sudo apt-get install -y git-core
sudo apt-get install -y git libtool build-essential pkg-config autoconf
sudo apt-get install -y libraspberrypi-dev
sudo apt-get install -y python-dev
sudo apt-get install -y python-rpi.gpio
sudo apt-get install -y python-smbus
sudo apt-get install -y i2c-tools

cd ${PH}/
[ ! -d git ] && mkdir git

cd ${PH}/git
git clone git://git.drogon.net/wiringPi
cd wiringPi
git pull origin
sudo ./build
cd ${PH}/
gpio -v
gpio readall

cd ${PH}/git
git clone https://github.com/adafruit/Adafruit-Raspberry-Pi-Python-Code.git
cd Adafruit-Raspberry-Pi-Python-Code/Adafruit_CharLCDPlate/
cd ${PH}/

cd ${PH}/git
git clone https://github.com/aufder/RaspberryPiLcdMenu.git
cd RaspberryPiLcdMenu
ln -s /home/pi/git/Adafruit-Raspberry-Pi-Python-Code/Adafruit_I2C/Adafruit_I2C.py ./
ln -s /home/pi/git/Adafruit-Raspberry-Pi-Python-Code/Adafruit_MCP230xx/Adafruit_MCP230xx.py ./
ln -s /home/pi/git/Adafruit-Raspberry-Pi-Python-Code/Adafruit_CharLCDPlate/Adafruit_CharLCDPlate.py ./
cd ${PH}/

cd ${PH}/git
git clone https://github.com/richardghirst/PiBits.git
cd PiBits/ServoBlaster/user
make
sudo make install
cd ${PH}/
sudo update-rc.d servoblaster disable
sudo servod --pcm
ps -ef | egrep "servo[d]"
sudo killall servod

cd ${PH}/git
git clone https://github.com/Pulse-Eight/libcec.git
cd libcec
./bootstrap
ARGS="--prefix=/usr --enable-rpi --with-rpi-include-path=/opt/vc/include --with-rpi-lib-path=/opt/vc/include"
LDFLAGS="-s -L/usr/lib -L/usr/lib -L/opt/vc/lib" ./configure $ARGS
make
cd ${PH}/
cec-client -l

cd ${PH}/
[ ! -d PiFm ] && mkdir PiFm
cd PiFm
wget http://omattos.com/pifm.tar.gz
gunzip < pifm.tar.gz | tar -xvf -
sudo ./pifm left_right.wav 87.5
cd ${PH}/

[ ! -d stfx ] && mkdir stfx
cd ${PH}/stfx
ln -s /home/pi/git/Adafruit-Raspberry-Pi-Python-Code/Adafruit_I2C/Adafruit_I2C.py ./
ln -s /home/pi/git/Adafruit-Raspberry-Pi-Python-Code/Adafruit_MCP230xx/Adafruit_MCP230xx.py ./
ln -s /home/pi/git/Adafruit-Raspberry-Pi-Python-Code/Adafruit_CharLCDPlate/Adafruit_CharLCDPlate.py ./
ln -s /home/pi/git/RaspberryPiLcdMenu/ListSelector.py ./
python -m compileall .

mkdir -p cache public/Movies
ln links.html public/
ln 'The Room.stfx' public/Movies/'The Room.stfx'

ln -s public/VLCPortable/Data/settings/vlcrc ./
mkdir -p public/VLCPortable/Data/settings
true >> vlcrc
cat vlcrc.template > vlcrc

ln -s public/WinSCPPortable/Data/settings/winscp.ini ./
mkdir -p public/WinSCPPortable/Data/settings
true >> winscp.ini
cat winscp.ini.template > winscp.ini

ln -s public/PuTTYPortable/Data/settings/putty.reg ./
mkdir -p public/PuTTYPortable/Data/settings
true >> putty.reg
cat putty.reg.template > putty.reg

cccc() { # I should learn how to use 'make'
rm -f lint $1 a.out
gcc -I/usr/local/include -L/usr/local/lib -lwiringPi -lm -Wall -O $1.c 2>lint && strip a.out && mv a.out $1
[ -f lint ] && [ ! -s lint ] && rm -f lint
[ -s lint ] && cat lint
}
cccc led_strip_car-fuzz1
cccc led_strip_car-knightrider
cccc led_strip_car-plod1
cccc led_strip_grey

rm -f cksum.log blank.fb lint a.out *.pyc cache/*
[ ! -w /dev/i2c-0 -o ! -w /dev/i2c-1 ] && gpio load i2c
[ ! -w /dev/spidev0.0 -o ! -w /dev/spidev0.1 ] && gpio load spi

# should ask before over-writing the various system config files
ls -l `cat ammended.lof`
tar -T ammended.lof -czf before-ammendment-$(date +"%Y%m%d%H%M%S").tgz > /dev/null 2>&1
sudo tar -C / -xzf ammended.tgz
sudo chown -R pi:pi .
cd ${PH}/

sudo update-rc.d hostapd disable
sudo update-rc.d udhcpd enable
sudo update-rc.d ssh enable

which rpi-update >/dev/null || sudo apt-get install -y rpi-update
# sudo rpi-update
sudo shutdown -F -r now

# build the install file - just for my notes
# rm -f stfx.tgz ; tar -czf stfx.tgz links.html vlcrc.template winscp.ini.template putty.reg.template \
# led_strip_car-fuzz1.c led_strip_car-knightrider.c led_strip_car-plod1.c led_strip_grey.c \
# install.sh ammended.lof ammended.tgz i2cdetect-this.sh lcdmenu.py lcdmenu.xml stfx.sh stfx.config \
# 'The Room.stfx'

