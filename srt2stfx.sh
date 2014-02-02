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

awk 'BEGIN{ p="[0-9][0-9]:[0-5][0-9]:[0-5][0-9],[0-9][0-9][0-9]"; }
  NF==1 && match($1,"^[0-9]+[\r]?$") {
		seq = $1;
    getline;
    if(match($0,"^" p " --> " p "$")) {
			split($1,b,"[:,]");
      sb = (3600 * b[1]) + (60 * b[2]) + b[3] ;
			split($3,e,"[:,]");
      se = (3600 * e[1]) + (60 * e[2]) + e[3] ;
      sd = se - sb ;

			for(buf=""; !match($0,"^$"); getline) {
				buf = buf $0 "\n" ;
      }
      printf("%05d\tsecondscreen text %02d %s",sb,sd,buf);
    }
  }' "${inf}" > "${inf}".stfx
