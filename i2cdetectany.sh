#!/bin/sh
# License:
# i2cdetectany.sh - detect a device at a specific address on Raspberry Pi I2C bus
# Copyright (C) 2013-11-07 Phill W.J. Rogers
# PhillRogers_at_JerseyMail.co.uk
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# SoFar
#  if no address specified then list all
#  report bus and address of each instance
#  validate given arg(s)
#  second optional arg to specify exclusively which bus to probe
#  2014-02-07  tidied, renamed, released
#  2014-02-28  allow specifying of default bus for this hardware
# ToDo:
#  use bit masks to detect device at all possible alternate addresses?
# Note:
#  For Adafruit_LCD, use this to detect MCP23017 on standard bus then
#  use separate routine to work out if it's deffo the Adafruit_LCD ?

usage(){
	printf "Usage: $0 [6e [0|1|?]] \n"
	printf "Prints a full list of detected I2C devices with descrption where known.\n"
	printf "Or sets exit code TRUE if a device is detected at the specified address.\n"
	printf "Where 6e is any hex address between 03 and 77 inc.\n"
	printf "Where 0 is the specific I2C bus to probe between 0 and 1 inc.\n"
	printf "Or use ? to specify the default bus for this revision of hardware.\n"
	exit 1
}

awk '/^Revision/{if(length($3)<=5){r=$3}else{r=substr($3,length($3)-5)};if(0+("0x"r)>=4){exit 1}else{exit 0}}' /proc/cpuinfo
if [ "$?" = "0" ] ; then # Test if this Raspberry Pi is revision 1 hardware. Set useful vars for script processing.
  i2c=0 ; rev=1
else
  i2c=1 ; rev=2
fi
export i2c rev

if [ "$1" = "" ] ; then
	printf "Default I2C bus for this revision of hardware is: $i2c \n"
  printf "Probing for all I2C devices (bus, address, value, description) .. \n"
else
	hex=$(echo $1 | mawk 'BEGIN{rc=1;}{$1=tolower($1);}
			match($1,"^[0-9a-f][0-9a-f]$"){
				print $1;
				rc=0;
			}
		END{exit rc}')
	if [ "$?" != "0" ] ; then
    usage
	fi
	if [ "$2" != "" ] ; then
		if [ "$2" = "0" -o "$2" = "1" ] ; then
      bus=$2
    else
      if [ "$2" = "?" ] ; then
        bus=$i2c # default bus for this revision of hardware
      else
				usage
      fi
    fi
  fi
fi

[ ! -w /dev/i2c-0 -o ! -w /dev/i2c-1 ] && which gpio >/dev/null && gpio load i2c

if [ "$bus" != "" ] ; then
  echo $bus
else
  # loose the second 'cut' line to keep the full bus ID
  i2cdetect -l | cut -f3 | cut -d. -f2
fi | while read bus ; do
	i2cdetect -y $bus | \
	mawk -v bus=$bus ' # un-roll table
		NR>1{
			hi = 0 + sprintf("0x%s", substr($0, 1, 2) );
			for(lo=0; lo<16; lo++) {
				addr = hi+lo;
				if(addr>2 && addr<120) {
					val = substr($0, 5+(3*lo), 2);
					if(val != "--") {
						printf("%s\t0x%02x\t0x%s\t\n", bus, addr, val);
					}
				}
			}
		}' 
done | mawk -v hex="$hex" ' # loop-up
  BEGIN{OFS=FS="\t";rc=0;if(hex!=""){rc=1;hex=0+("0x"hex)}}
	{addr=0+$2;if(addr==hex){rc=0;exit};
  if( addr == 0+"0x20" ) { $4 = "Adafruit LCD + buttons" }
  if( addr == 0+"0x21" ) { $4 = "MCP23017 16-pin I/O expander - alt_addr=1" }
  if( addr == 0+"0x3b" ) { $4 = "Raspberry Pi camera" }
  if( addr == 0+"0x40" ) { $4 = "PCA9685 16-ch PWM Adafruit" }
  if( addr == 0+"0x48" ) { $4 = "4-ch ADC ADS1015/ADS1115 4-ch ADC Adafruit" }
  if( addr == 0+"0x68" ) { $4 = "DS1307 RTC Adafruit" }
  if( addr == 0+"0x70" ) { $4 = "Built-in 4-ch I2C multiplexer" }
  if( addr == 0+"0x77" ) { $4 = "BMP085 Bosch pressure & temperature Adafruit" }
  if(hex==""){print;}}END{exit rc}'

# FIN
