#!/bin/sh

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
  /^#/{next}
  $2=="secondscreen" && $3=="text" {
		$4 = sprintf("%02d", $4);
		$1 = sprintf("%05d", $1);
    $2=$3="";
		print $0;
  }' "${fin}" | \
  sort -k1,1n | \
  awk -v nl="\\\n" 'BEGIN{seq=0;}
  { s = $1; seq++;
		h = int(ts / 3600); s -= (3600 * h);
		m = int(ts / 60); s -= (60 * m);
    from=sprintf("%02d:%02d:%02d,000",h,m,s);
    s = $1 + $2;
		h = int(ts / 3600); s -= (3600 * h);
		m = int(ts / 60); s -= (60 * m);
    till=sprintf("%02d:%02d:%02d,000",h,m,s);
    $1=$2=""; buf=$0;
    printf("%d\r\n%s --> %s\r\n", seq,from,till);
    while(gsub("(^ | $)","",buf));
    while(n=index(buf,nl)) {
			printf("%s\r\n", substr(buf,1,n-1) );
      buf = substr(buf,n+2);
    }
    if(buf != "") {
			printf("%s\r\n", buf );
    }
		printf("\r\n");
  }' > "${fin}".srt

