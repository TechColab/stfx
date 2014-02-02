#!/bin/bash

# much work to do .. 
# 1:39:34,26 = ( (1*3600)+(36*60)+34 ) = 5794
# 111	secondscreen text 3 "Focus!"

obeydir=$(echo $0 | awk -v pwd="$(pwd)" '# simplified version
	/^\//{p=$0;exit}/\.\//{$0=substr($0,3)}{p=pwd"/"$0;exit}
  END{b=split(p,a,"/");p=substr(p,1,length(p)-length(a[b])-1);print p}')
cd "${obeydir}"

fin="$*"
if [ ! -f "${fin}" ] ; then
  printf "Falure to find input file.\n"
  exit 1
fi

awk '
  !match($1,"^#") && $2=="secondscreen" {
    while(gsub("(^ | $)","",$0));
    while(gsub("\t"," ",$0));
    while(gsub("  "," ",$0));
		$4 = sprintf("%02d", $4);
		$1 = sprintf("%05d\t", $1);
  }
	{	print; } ' "${fin}"
