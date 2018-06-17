#!/bin/ksh

#        "\033[31m"
#        "\033[32m"
#        "\033[33m"
#        "\033[37m"
#        "\033[36m"
#        "\033[35m"
#        "\033[34m"

trap 'tput sgr0; tput cnorm; exit' 0 1 2 3 9 15

CC="$1"

if [ "$2" ]
then
	COLR=$2
else
	COLR=1
fi

C1=${CC%?}
C2=${CC#?}

H1=$(print "\033[3${COLR}m")
H2=$(print "\033[37m")

SEQ=$C1

print "$SEQ"
while read
do
	CSQ=$(print "$SEQ" | tr "${C1}${C2}"  "${C2}${C1}")
	SEQ=${SEQ}${CSQ}
	print "$SEQ" | sed -e "s/${C1}/${H1}${C1}/g" -e "s/${C2}/${H2}${C2}/g"
done
