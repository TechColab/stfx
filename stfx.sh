#!/bin/sh
# License:
# stfx.config - sample template for site-specific customised routines.
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
# https://github.com/TechColab/stfx.git
# 
# Purpose:
#		Part of the 'stfx' suite
#		To trigger physical effects in sync with movie cue points
# SoFar:
#		2013-11-19 PhillRogers@JerseyMail.co.uk
#		Ready for first live public perfomance use.
#		2013-11-24 PhillRogers@JerseyMail.co.uk
#		clear screen and fix test for absent stfx files
#		fix for movie titles with a space in the name
#		allow repeated actioins if different times
#		2013-11-24 PhillRogers@JerseyMail.co.uk
#		move cache to separate file
#		fix text message pick-up to include '\r'
#		replace fbi with direct write to fb0 for speed
#		2013-11-25 PhillRogers@JerseyMail.co.uk
#		return to blocking repeats to fix flash with new fb copy
#		2013-12-17 PhillRogers@JerseyMail.co.uk
#		text centered. appx 5" chars on a 42" screen. auto-wrap
#		2014-01-14 PhillRogers@JerseyMail.co.uk
#		tweaked to run all on RPi with nothing on media_player
#		Merge actions into same script as poll loop
#		2014-01-15 PhillRogers@JerseyMail.co.uk
#		Bigger loop to: wait for VLC, go back to waitig if VLC closes
#		allow repeated actioins if different times - make optional
#		search network connections for a running copy of VLC .. 
#		2014-01-16 PhillRogers@JerseyMail.co.uk
#		allow for *.stfx files to be in any sub-folder
#		auto purge cache if this TV has different frame buffer size
#		2014-01-20 PhillRogers@JerseyMail.co.uk
#		move actions back to separate file, called as a config file
#		add raspistill & raspivid - easier than using WiFi GoPro.
#		2014-01-21 PhillRogers@JerseyMail.co.uk
#		test with HDMI->VGA+audio adapter.
#		fix a few bugs with auto cache rebuild
#		Optional (auto-detected) Adafruit LCDmenu for clean shutdown
#		test with CompositeVideo output.
#		tweak screen restore after blanking for cache rebuild
#		2014-01-25 PhillRogers@JerseyMail.co.uk
#		change so *.stfx gets it's name from the movie file name, if no title.
#		Would be nice to use filename fully but see lower notes.
#		Tweaked to tolerate spaces in filename.
#		2014-01-30 PhillRogers@JerseyMail.co.uk
#		moved temporary files to tmpfs for speed and save SD wear
#		added timeing log to get an idea of acheivable resolution
#		longest itteration during test clip was 154mS (using WiFi)
#		seems to run fine without the sleep
# ToDo:
#		Repeats still faulty.  Should support multiple concurrent actions.
#		Check if image cache reliable is really reliable now.
#		Test installer
# stfx file format:
#		The file extention is 'stfx' in lower case.
#		The file's base name is the movie 'title' as specified in the m2u playlist with '_' in place of ' '.
#		The file is a plain ASCII text file and lines can be in any order but chronological is recommended.
#		Lines beginning with '#' are ignored for use as comments.
#		Lines begin with the number of whole seconds into the movie at which this line will be triggered.
#		Followed by a single TAB character.
#		Followed by the 'action' noun or verb which should be descriptive and without any special characters.
#		Followed (optionally) by a space and any number of space-separated arguments for the action.
#		Followed by LF or CRLF
#

obeydir=$(echo $0 | awk -v pwd="$(pwd)" '# simplified version
	/^\//{p=$0;exit} /^\.\//{$0=substr($0,3)}{p=pwd"/"$0;exit}
	END{b=split(p,a,"/");p=substr(p,1,length(p)-length(a[b])-1);print p}')
cd "${obeydir}" ; obeydir="$(pwd)"
printf "Now self-located to ${obeydir} for further processing.\n"

T=/run/stfx # all our temporary files are here in the RAM file system
[ ! -d $T ] && sudo mkdir $T
sudo chown pi:pi $T
echo $PATH | egrep -q "(^|:)/usr/local/bin(:|$)" || PATH=$PATH:/usr/local/bin:
export PATH
rm -f $T/debug.log

# Currently connected TV may have differnt auto-detected parameters to previous TV.
# Save initial TV state, detect if empty frame buffer is same as last time.
# If different then dump the current cache & rebuild a new cache set.
fbset -s > $T/fbset-s.log
# cat $T/fbset-s.log >> $T/debug.log
sudo sh -c "TERM=linux setterm -foreground black >/dev/tty0"
sudo sh -c "TERM=linux setterm -cursor off -clear >/dev/tty0"
cat /dev/zero > /dev/fb0 2>/dev/null 
cat /dev/fb0 > blank.fb
# dissable TV output while building the cache to avoid distracting viewers
tvservice -s > $T/tvservice-s.log
tvservice -o
blank=$(cksum blank.fb | awk '{print $1}')
[ ! -f cache/blank.fb ] && true > cache/blank.fb
prev_blank=$(cksum cache/blank.fb | awk '{print $1}')
[ "${prev_blank}" != "${blank}" ] && rm -f cache/*.fb
mv blank.fb cache/
rm -f cksum.log

# pre-compose and cache text images
find public/Movies -type f -name "*.stfx" -exec cat {} \; | \
awk '/^#/{next}/^[0-9]/ && $2=="secondscreen" && $3="text"{$1=$2=$3=$4="";while(gsub("(^ | $)",""));print}' | \
while m=`line` ; do
	b=text-$(echo "$m" | cksum | cut -d' ' -f1)
	printf "Processing text ${b} .. \n"
	printf "%s\t=>%s<=\n" ${b} "${m}" >> cksum.log
	if [ ! -f cache/${b}.fb ] ; then
		if [ ! -f ${b}.jpg ] ; then
			printf "Creating image .. \n"
			# convert -background black -fill white -size 1920x1080 label:"$m" ${b}.jpg
			if expr `echo "${m}" | wc -c` \> 40 >/dev/null ; then
				font_size=208
			else
				font_size=360
			fi
			convert -size 1920x1080 -background black -fill white -gravity center -density 53 -pointsize $font_size caption:"${m}" ${b}.jpg
		fi
		printf "Capturing frame buffer .. "
		cs="$blank"
		while [ "$cs" = "$blank" ] ; do
			printf "."
			sudo fbi -noverbose -T 1 -a -1 -t 3 ${b}.jpg 2>/dev/null ; sleep 2 ; cat /dev/fb0 > cache/${b}.fb
			cs=$(cksum cache/${b}.fb | awk '{print $1}')
		done
		printf " \n"
		rm -f ${b}.jpg
	fi
done
true >> cksum.log

# pre-compose and cache graphic images
# following had a reliability issue - MIGHT be ok now.
find public/Movies -type f -name "*.jpg" -print | \
while read f ; do
	ext=$(echo "${f}" | awk -F. '{print $NF}')
	b=$(basename "${f}" .$ext)
	printf "Processing image ${b} .. \n"
	if [ ! -f cache/image-${b}.fb ] ; then
		printf "Capturing frame buffer .. "
		cs="$blank"
		while [ "$cs" = "$blank" ] ; do
			printf "."
			sudo fbi -noverbose -T 1 -a -1 -t 6 "${f}" 2>/dev/null ; sleep 3 ; cat /dev/fb0 > cache/image-${b}.fb
			cs=$(cksum cache/image-${b}.fb | awk '{print $1}')
		done
		printf " \n"
	fi
done

# will be root if launched from the boot process

if [ "$(id -u)" = "0" ] ; then
  true > $T/tmp.xml
  chown -R pi:pi cache cksum.log $T/tmp.xml
fi

# check which TV output to restore
set $(perl -n -e ' m/ \[(NTSC|PAL) (.+)\]/ && print "$1\t$2\n" ; ' $T/tvservice-s.log) NOT_CV
if [ "$1" = "NOT_CV" ] ; then
  tvservice -p
	# switch the TV on
	echo "on 0" | cec-client -s >/dev/null 2>&1
  sleep 3
	# select the Raspberry Pi's HDMI input
  echo "as" | cec-client -s >/dev/null 2>&1
else
	tvservice --sdtvon="$1 $2"
fi
rm -f $T/tvservice-s.log
fbset -db $T/fbset-s.log $(awk -F'"' '/^mode/{print $2}' $T/fbset-s.log) && rm -f $T/fbset-s.log

# finished preparation
rm -f tmp.jpg ; font_size=72 ; m="Waiting for media player."
convert -size 1920x1080 -background black -fill white -gravity center -density 53 -pointsize $font_size caption:"${m}" tmp.jpg
sudo fbi -noverbose -T 1 -a -1 tmp.jpg 2>/dev/null
# printf "Cache done.\n" ; exit 0 # DeBug

# load the customised config
. ./stfx.config

# start the outer loop, looking for the media player
while true ; do

	media_player_ip=
	media_player_lan=

	if [ "${media_player_ip}" = "" ] ; then
		printf "Enumerating LANs .. \n"
		for lan in $( ifconfig -a | awk '/encap:Ethernet/{print $1}' | sort ) ; do
			if [ "${media_player_ip}" = "" ] ; then
				printf "Enumerating IP devices on LAN -=>${lan}<=- .. \n"
				for ip in $( arp -i ${lan} -a | perl -n -e ' /\(([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\)/ && print "$1\n" ;' ) ; do
					if [ "${media_player_ip}" = "" ] ; then
						printf "Looking for VLC on IP device -=>${ip}<=- .. \n"
						true > $T/tmp.xml
						wget -q --timeout=1 --tries=1 --user='' --password=${vlc_http_password} -O $T/tmp.xml http://${ip}:8080/requests/status.xml
						if [ "$?" = "0" -a -s $T/tmp.xml ] ; then
							media_player_ip=${ip}
							media_player_lan=${lan}
						fi
					fi
				done
			fi
		done
	fi

	if [ "${media_player_ip}" = "" ] ;then
		printf "Failed to find media player.  Will retry in a mo.\n"
		sleep 3
	else
		printf "Found media player at ${media_player_ip} on ${media_player_lan} \n"

		printf "Entering polling loop .. \n"
		fn_init
		# time_start=0 ; time_prev=0
		prev="" ; export prev
		rm -f status.log ; true > $T/tmp.xml
		while wget -q --user='' --password=${vlc_http_password} -O $T/tmp.xml http://${media_player_ip}:8080/requests/status.xml ; do
			# ls -l $T/tmp.xml
			status=$( perl -e '
				while (<>) {
					if( $_ =~ /^<time>(\d*)<\/time>/ ) { $time=$1; }
					if( $_ =~ /<info name=.title.>(.*?)<\/info>/ ) { $title = $1 ; }
					if( $_ =~ /<info name=.filename.>(.*?)<\/info>/ ) { $filename = $1 ; }
				}
				# Would be better to use the filename so it matches that of the *.srt
				# But VLC incorrectly reports the title, if present, in place of the filename
				# So cannot rely on the reported filename.  So must rely on the title.
				# But if title not given then try the filename anyway. Beware extension.
				if($title ne "") { $movie = $title ; } else {
					my @tmp1 = reverse split("/",$filename) ;
					my @tmp2 = reverse split("\\.",$tmp1[0]);
					my $ext = $tmp2[0] ;
					my $bfn = substr($tmp1[0], 0, length($tmp1[0]) - length(".$ext")) ;
					$movie = $bfn ;
				}
				if($time ne "") { print "$time\t$movie\n" ; }
				' $T/tmp.xml )
			# printf "DeBug: status-=>%s<=- \n" "${status}"

			if [ "${status}" != "" ] ; then
				set $(echo ${status}) ; seconds=$1 ; shift ; movie="$*"
				# printf "DeBug: Title:%s\tSeconds:%d\n" "$movie" "$seconds"
				if [ -f "public/Movies/${movie}.stfx" ] ; then
					action=$(awk -v seconds=${seconds} -v prev="${prev}" 'BEGIN{OFS=FS="\t"}/^#/{next}
						match($2,"^secondscreen"){$1=$1 -0} # compensate for frame buffer rendering time
						(seconds>=$1) && (seconds<($1 +1)) && $2!=prev{print $2;exit}
						' public/Movies/"${movie}".stfx )
			# Phill - dragons be here - above and below
					if [ "$repeats" = "on" ] ; then
						if [ "${action}" != "" ] && [ "${seconds} ${action}" != "${prev}" ] ; then
							# echo "${seconds} ${action}" >> $T/debug.log
							prev="${seconds} ${action}"
							fn_action "${action}"
						fi
					else
						if [ "${action}" != "" ] && [ "${action}" != "${prev}" ] ; then
							# echo "${action}" >> $T/debug.log
							prev="${action}"
							fn_action "${action}"
						fi
					fi
				fi
			fi

			# time_end=$(date +"%s%N")
      # if [ "$time_start" != "0" ] ; then
			# 	time_busy=$(expr $time_end - $time_start)
			# 	expr $time_busy \> $time_prev > /dev/null && echo $time_busy > $T/longest_busy_time.log
			# 	time_prev=$time_busy
      # fi
			sleep 0.25 # Not needed but just trying to not pester the media_player too much.
			# time_start=$(date +"%s%N")

		done
		rm -f status.log ; true > $T/tmp.xml

	fi

done
fn_cleanup # /* NOTREACHED */
