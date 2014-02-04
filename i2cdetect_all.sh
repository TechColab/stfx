#!/bin/sh
# License:
# i2cdetect_this.sh - detect a device at a specific address on Raspberry Pi i2c bus
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

# ToDo:
# probe each bus separately
# capture i2cdetect output to temp file to save from re-probing
# use bit masks to detect device at all possible alternate addresses
# report bus and address of each instance
# 

printf "Probing for I2C devices .. \n" # should separate each bus
gpio load i2c
i2cdetect_this() {
for bus in $(i2cdetect -l | cut -f3) ; do sudo i2cdetect -y $bus; done | \
mawk -v hex=0x$1 'BEGIN{found=0;hi=sprintf("^%01d0:",hex/16 ); lo=2+(hex%16);}
  match($0,hi){  if($lo != "--"){found++;printf("%s\n",$lo);}  }
  END{if(found){exit 0}else{exit 1}}'
}
i2cdetect_this 3b >/dev/null && printf "Raspberry Pi camera\n"
i2cdetect_this 20 >/dev/null && printf "Adafruit LCD + keypad\n"
i2cdetect_this 21 >/dev/null && printf "MCP23017 16-pin I/O\n"
i2cdetect_this 22 >/dev/null && printf "MCP23017 16-pin I/O\n"
i2cdetect_this 23 >/dev/null && printf "MCP23017 16-pin I/O\n"
i2cdetect_this 24 >/dev/null && printf "MCP23017 16-pin I/O\n"
i2cdetect_this 25 >/dev/null && printf "MCP23017 16-pin I/O\n"
i2cdetect_this 26 >/dev/null && printf "MCP23017 16-pin I/O\n"
i2cdetect_this 27 >/dev/null && printf "MCP23017 16-pin I/O\n"
i2cdetect_this 48 >/dev/null && printf "Adafruit 4-ch ADC ADS1015/ADS1115\n" # 4 addr pins = 3 alt addresses
i2cdetect_this 77 >/dev/null && printf "Bosch BMP085 pressure & temperature\n"
i2cdetect_this 68 >/dev/null && printf "DS1307 RTC\n"
i2cdetect_this 40 >/dev/null && printf "Adafruit 16-ch PWM PCA9685\n" # 6 addr pins = 63 alt addresses!

