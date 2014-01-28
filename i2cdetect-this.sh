#!/bin/sh
# License:
# i2cdetect-this.sh - detect a device at a specific address on Raspberry Pi i2c bus
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

if [ "$1" = "" ] ; then
  printf "Usage: %s 6e \n" $0
  exit 1
fi

for bus in $(i2cdetect -l | cut -f3) ; do sudo i2cdetect -y $bus; done | \
mawk -v hex=0x$1 'BEGIN{found=0;hi=sprintf("^%01d0:",hex/16 ); lo=2+(hex%16);}
  match($0,hi){  if($lo != "--"){found++;printf("%s\n",$lo);}  }
  END{if(found){exit 0}else{exit 1}}'

printf "ReturnCode: %d\n" $?
