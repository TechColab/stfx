/*
    led_strip_car-knightrider - flash RGB LED strip like the Knightrider car.
    Copyright (C) 2014 Phill W.J. Rogers
		PhillRogers_at_JerseyMail.co.uk
		
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
		
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
		
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
Common parts for all chip types:
  double buffering because the write function may also read back the prev value into the same buffer
  gamma correction
  R,G,B values of 0-255
Separation of IC specific parts - LPD8806
  change 'RGB' order to 'GRB'
  reduction to 7-bit
  set hi-bit
  add latch code
*/

#include "wiringPi.h"
#include "wiringPiSPI.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <time.h>
#include <math.h>

void msleep(unsigned long milisec) {
  struct timespec req = {0} ;
  time_t sec=(int)(milisec/1000);
  milisec=milisec-(sec*1000);
  req.tv_sec=sec;
  req.tv_nsec=milisec*1000000L;
  nanosleep(&req, (struct timespec *)NULL) ;
}

void update_LPD8806(int channel, uint8_t *ptr, uint8_t buflen) {
  int loop=0;
  uint8_t val=0, r=0, g=0, b=0;
  uint8_t eo_buf[] = { 0,0,0 } ;
  for(loop=0; loop<buflen; loop+=3) {
    g = ptr[loop+0] ;
    r = ptr[loop+1] ;
    b = ptr[loop+2] ;
    ptr[loop+0] = r ;
    ptr[loop+1] = g ;
    ptr[loop+2] = b ;
  }
  for(loop=0; loop<buflen; loop++) {
    val = (ptr[loop]>>1) | 0x80 ;
    ptr[loop] = val ;
  }
  wiringPiSPIDataRW(channel, ptr, buflen) ;
  wiringPiSPIDataRW(channel, eo_buf, sizeof(eo_buf)) ;
  /* consider converting read prev values back to RGB,0-255 */
}

uint8_t byte_gamma(uint8_t val) {
  return (uint8_t)( floor( (255.0 * pow( 1.0 * val , 2.5) ) + 0.5) ) ;
  // return val ;
}

int main(int argc, char **argv) {
  int seqlen=32 ;
  int numofleds=32 ;
  int channel=0 ;
  int rep=5 ;
  int delay=15 ;
  int width=5 ;
  uint8_t bufsize=(3*numofleds) ;
  uint8_t buf[bufsize] ;
  uint8_t ary[seqlen][bufsize] ;
  int loop_seq=0, loop_led=0;
  loop_seq=loop_seq; loop_led=loop_led; /* may not be used */

  memset(buf, 0, bufsize);
  memset(ary, 0, (sizeof(uint8_t) * seqlen * bufsize) );
  // set output SPI channel to 0 and speed to 8MHz
  if(wiringPiSPISetup(channel, 8000000) < 0) {
    fprintf(stderr, "Unable to open SPI device 0: %s\n", strerror(errno)) ;
    exit(1) ;
  }
  wiringPiSetupSys() ;

  // create the pattern(s)
  for(loop_seq=0; loop_seq<(32+1-width); loop_seq++ ) {
    ary[loop_seq][(3*loop_seq)+0] = 4 ;
    ary[loop_seq][(3*loop_seq)+3] = 64 ;
    ary[loop_seq][(3*loop_seq)+6] = 255 ;
    ary[loop_seq][(3*loop_seq)+9] = 64 ;
    ary[loop_seq][(3*loop_seq)+12] = 4 ;
  }

  // animate the sequence
  for(rep=0; rep<5; rep++) {
    for(loop_seq=0; loop_seq<(32+1-width); loop_seq++) {
      memcpy(buf, &ary[loop_seq][0], bufsize) ; update_LPD8806(channel, buf, bufsize) ;
      msleep(delay);
    }
    for(loop_seq=(31-width); loop_seq>=0; loop_seq--) {
      memcpy(buf, &ary[loop_seq][0], bufsize) ; update_LPD8806(channel, buf, bufsize) ;
      msleep(delay);
    }
  }

  memset(buf, 0, bufsize) ; update_LPD8806(channel, buf, bufsize) ;
  return 0 ;
}


















/* */
