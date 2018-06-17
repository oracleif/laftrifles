#!/bin/ksh

CC="$1"

C1=${CC%?}
C2=${CC#?}

SEQ=$C1


echo "$SEQ"
while read
do
	CSQ=$(echo "$SEQ" | tr -- "${C1}${C2}"  "${C2}${C1}")
	SEQ=${SEQ}${CSQ}
	echo "$SEQ"
done
