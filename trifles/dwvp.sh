#!/usr/bin/ksh

function shuffle
{
	SIZE=$1
	DRAWN=0
	OUTPUT=" "
	while [ $DRAWN -lt $SIZE ]
	do
	DRAW=$(( ($RANDOM % $SIZE)+1))
	if [ "$OUTPUT" = "${OUTPUT#* ${DRAW} }" ]
	then
		OUTPUT="${OUTPUT}${DRAW} "
		DRAWN=$(( ${DRAWN} + 1 ))
	fi
	done
	print "$OUTPUT"
}

typeset -i BALANCE WIN
typeset -u KEEP HOLD

CHEAT="--------"
PSYCHIC=""
PLAY=TRUE
Unique() { sort -u ; }

set -A CARDS xxx \
A-S 2-W 3-S 4-S 5-S 6-S 7-S 8-S 9-S T-S J-S Q-S K-S \
A-H 2-W 3-H 4-H 5-H 6-H 7-H 8-H 9-H T-H J-H Q-H K-H \
A-C 2-W 3-C 4-C 5-C 6-C 7-C 8-C 9-C T-C J-C Q-C K-C \
A-D 2-W 3-D 4-D 5-D 6-D 7-D 8-D 9-D T-D J-D Q-D K-D

#############################################################################
#	Process command line options
#############################################################################


USAGE="${0##*/} [-c] [-p]

-c	cheat mode - enter your own next cards
-p	psychic mode - see the next cards on the stack
"
while getopts cp optc
do
	case $optc in
		c)	CHEAT="-"
			Unique() { cat ; }
			;;
		p)	PSYCHIC=true ;;
		*)	print "$USAGE" >&2
			PLAY=FALSE
			;;
	esac
done
shift $(( $OPTIND - 1 ))

#############################################################################
#	Body of script
#############################################################################

BALANCE=0

while [ $PLAY = TRUE ]
do

#############################################################################
#	Start with the HOLD list empty, then shuffle 52 cards and pull the
#	first 10 for this hand (5 for the deal and up to 5 for the draw).
#	Report the dealt cards, marking any wild cards for emphasis.
#############################################################################

	HOLD=""

	DEAL="$(for CARDNO in $(shuffle 52 | sed 10q)
	do
		print "${CARDS[${CARDNO}]}"
	done)"

	print "\n"
	print "$DEAL" | sed 5q | pr -te -n5 | sed "/2-W/s/$/ <<<<<<<</"

#############################################################################
#	If playing as a PSYCHIC (ahem), also report the cards waiting for
#	the draw.
#############################################################################

	if [ "$PSYCHIC" ]
	then
		print "[The psychic sees: \c"
		print "$DEAL" | sed -n 6,10p | tr "\012" " "
		print "]"
	fi

#############################################################################
#	Ask the player which cards to keep/hold.  If the player elects to
#	quit, scroll-clear the screen; otherwise, accept the hold selection
#	and decrement the player's balance by 1 credit.
#############################################################################

	read KEEP?"Select cards to keep: "

	if [ "${KEEP}" != "${KEEP#[qQ]}" ]
	then
		( yes "" | sed 2000q ) 2>/dev/null
		print "Total: $BALANCE"
		PLAY=FALSE
		break
	else
		let BALANCE=${BALANCE}-1
	fi

#############################################################################
#	We start assuming no cards held, setting DRAW to 5.  The KEEP
#	string is then broken into individual numbers, and we step through
#	the list, checking each selection against the list of DEAL cards,
#	adding cards to HOLD, and decrementing the DRAW count by 1 for each
#	selection.
#############################################################################

	DRAW=5
	for CARD in $(	print "$KEEP" |
			sed "s/\([1-9]\)/ \1/g" |
			tr ' ' '\012' |
			Unique )
	do
		case $CARD in
		*${CHEAT}*) HOLD="${HOLD}$(echo ; print "${CARD}" )" ;;
		*) HOLD="${HOLD}$(echo ; print "$DEAL"| sed -n ${CARD}p)" ;;
		esac
		DRAW=$((${DRAW}-1))
	done

#############################################################################
#	With the DRAW count determined, combine the HOLD cards with the
#	DRAW cards to populate RESULT (a multiline string).
#############################################################################

	RESULT=$(print "$HOLD" | sed 1d
	if [ $DRAW -gt 0 ]
	then
		DRAW=$((DRAW+5))
		print "$DEAL" | sed -n 6,${DRAW}p
	fi)

#############################################################################
#	Scoring note - the key to scoring is recognizing that VP scoring is
#	based on two factors - the values of the cards and the suits of the
#	cards.  Most scoring is based on matched values - 3 of a kind, full
#	house, etc.  If none of the values match and the lowest and highest
#	values are a "hand's width" apart (difference of 4), that's a
#	straight.  If cards are all of one suit, a flush is scored, which
#	may combine with a value-scored straight for a straight flush; if
#	the straight flush begins with a 10, it's a royal flush.  Based on
#	this general reasoning, we calculate value score for matches and
#	straights, then check for flushes and adjust accordingly.  Highest
#	scoring hand possibilities should be considered first, so that
#	evaluation can be stopped once the highest remaining interpretation
#	is confirmed.
#############################################################################

#############################################################################
#	Populate the VLIST array with the values of the selected cards.
#	Note that format of card name is V-S, where V is the value and S
#	the suit (wild deuces have a suit of W), so here we're extracting
#	the value character to the left of the "-" separator.  Face cards
#	are assigned their numeric equivalents, wild cards are replaced
#	with 00.  Sort the list before saving to VLIST; this groups
#	matching values and puts wild cards at the front of the list.
#############################################################################

	set -A VLIST $(print "${RESULT}" | cut -f1 -d'-' |
	sed "s/^\([3-9]\)$/0\1/
	s/2/00/
	s/T/10/
	s/J/11/
	s/Q/12/
	s/K/13/
	s/A/14/" | sort)

#############################################################################
#	If there are wild cards, determine offset of first non-wild card
#############################################################################

	NW=0
	if [ $VLIST = 00 ]
	then
		NW=1
		while [ ${VLIST[$NW]} = 00 ]
		do
			NW=$(( NW + 1 ))
		done
	fi

#############################################################################
#	Recording suits is much simpler - just extract the suit characters,
#	sort, and concatenate into a single string.
#############################################################################

	SLIST="$(print "${RESULT}" | cut -f2 -d'-' | sort | tr -d '\012')"
  
#############################################################################
#	Report the final selected/drawn cards before proceeding with
#	scoring.
#############################################################################

	print "$RESULT" | sed "s/^/------> /"

#############################################################################
#	Calculate the value score.  This turned out to be simpler than
#	expected, even with the added complexity of wild cards, which sort
#	at the beginning of the value array as 00 values.  Value scoring is
#	done with a sed command applied against the sorted VLIST.
#
#	To "value score" hands that include wildcards, it is not necessary
#	to evaluate every possible value the wildcard might take.  Instead
#	we "score" the remaining cards as they combine with a fixed number
#	of wildcards.  Importantly, we are only concerned with the highest
#	scoring combinations, which limits the possibilities we need to
#	evaluate. 
#
#	Scored ace-low straights are special cases that would not be
#	detected by the ordinary straight filter because we assign aces a
#	value of 14 (greater than King).  These will of necessity
#	include one or two wild cards, since 2s are wild and any hand with
#	three wild cards will out-score a straight.  There is only one case
#	to check with a single wild card (A345), but three possibilities
#	with two wild cards (A34, A35, and A45).
#############################################################################
#	With 4 deuces, we score 4 deuces.
#############################################################################
#	With 3 deuces, we might score 5-kind or 4-kind.
#############################################################################
#	With 2 deuces, we might score: - 5-kind, 4-kind - Ace-low straight
#	(w/3&4, 3&5, or 4&5) - 3-kind
#############################################################################
#	With 1 deuce, we might score: - 5-kind, 4-kind - full house (if we
#	see two pair) - Ace-low straight - 3-kind (if we see a pair) - If
#	none of the above, we have no value score (LOSER)
#############################################################################
#	Without deuces, we have only the "natural" cards to consider, which
#	for DWVP can score as: - 4-kind - full-house (two ways, more high
#	cards or more low cards) - 3-kind - a pair (this is a LOSER, but we
#	note as LOSER-PAIR to indicate that there is no possibility of a
#	straight) - If none of the above, we have no value score (LOSER)
#############################################################################

	VSCORE=$(print "${VLIST[*]}" | sed "\
	s/^00 00 00 00.*$/W4-DEUCES/
	s/^00 00 00 \([0-9][0-9]\) \1$/W3-5-KIND/
	s/^00 00 00 .*$/W3-4-KIND/
	s/^00 00 \([0-9][0-9]\) \1 \1$/W2-5-KIND/
	s/^00 00 .*\([0-9][0-9]\) \1.*$/W2-4-KIND/
	s/^00 00 03 04 14$/W2-STRAIGHT/
	s/^00 00 03 05 14$/W2-STRAIGHT/
	s/^00 00 04 05 14$/W2-STRAIGHT/
	s/^00 00 .*$/W2-3-KIND/
	s/^00 \([0-9][0-9]\) \1 \1 \1$/W1-5-KIND/
	s/^00 .*\([0-9][0-9]\) \1 \1.*$/W1-4-KIND/
	s/^00 \([0-9][0-9]\) \1 \([0-9][0-9]\) \2$/W1-FULL-HOUSE/
	s/^00 03 04 05 14$/W1-STRAIGHT/
	s/^00 .*\([0-9][0-9]\) \1.*$/W1-3-KIND/
	s/^00 .*$/W1-LOSER/
	s/^.*\([0-9][0-9]\) \1 \1 \1.*$/4-KIND/
	s/^\([0-9][0-9]\) \1 \1 \([0-9][0-9]\) \2$/FULL-HOUSE/
	s/^\([0-9][0-9]\) \1 \([0-9][0-9]\) \2 \2$/FULL-HOUSE/
	s/^.*\([0-9][0-9]\) \1 \1.*$/3-KIND/
	s/^.*\([0-9][0-9]\) \1.*$/LOSER-PAIR/
	s/^.*[0-9]$/LOSER/")

#############################################################################
#	Straight filter, first pass:  See if the lowest and highest natural
#	cards are within 4 of each other.  If so, this will be a straight if
#	there aren't any pairs, so set GOTSTRAIGHT to trigger further checks,
#	else clear GOTSTRAIGHT.
#############################################################################

	if [ $((${VLIST[4]} - ${VLIST[$NW]})) -le 4 ]
	then
		GOTSTRAIGHT=true
	else
		GOTSTRAIGHT=""
	fi

#############################################################################
#	Straight filter, second pass:
#	- If we've scored a LOSER or 3-kind with 2 wild cards, this indicates
#	that none of the natural cards match, so set the VSCORE to STRAIGHT if
#	GOTSTRAIGHT is set.
#	- If three deuces (W3-4-KIND), that beats a straight, so don't set
#	VSCORE but leave GOTSTRAIGHT set in case there's a SF or RF.
#	- If an ace-low straight was detected by the value scoring filter, set
#	GOTSTRAIGHT.
#	- Otherwise, there can't be a straight, so clear GOTSTRAIGHT.  Once
#	we're finished, set SCORE to VSCORE.
#############################################################################

	case $VSCORE in
	*LOSER|W2-3-KIND)
		if [ "$GOTSTRAIGHT" ]
		then
			VSCORE=STRAIGHT
		fi
		;;
	W3-4-KIND)
		true
		;;
	*STRAIGHT)
		GOTSTRAIGHT=true
		;;
	*)
		GOTSTRAIGHT=""
		;;
	esac

	SCORE="$VSCORE"

#############################################################################
#	Suit score checking.  If all the natural cards are the same suit
#	(plus zero or more wild cards), we have a flush, so set SSCORE to
#	"FLUSH".  Otherwise, set SSCORE empty.
#############################################################################

	SSCORE=$(print "$SLIST" | sed "\
	s/\([HSDC]\)\1\1\1\1/FLUSH/
	s/^\([HSDC]\)\1\{1,\}W*$/FLUSH/
	s/^[HSDCW].*$//")

#############################################################################
#	If SSCORE and GOTSTRAIGHT are both set, we have some kind of
#	straight flush:
#	- If the first card is a 10, it is a NATURAL royal flush (woo-hoo!).
#	- Otherwise, if the first NON-WILD card is AT LEAST a 10, it is a
#	WILD royal flush (yay!).
#	- If neither, it's a plain straight flush (not bad!).
#############################################################################

	if [ -n "$SSCORE" -a -n "$GOTSTRAIGHT" ]
	then
		if [ ${VLIST[0]} = 10 ]
		then
			SCORE="ROYAL-FLUSH"
		elif [ ${VLIST[$NW]} -ge 10 ]
		then
			SCORE="WILD-ROYAL"
		else
			SCORE="STRAIGHT-FLUSH"
		fi

#############################################################################
#	If we don't have a straight flush, we'll keep the FLUSH unless the
#	value score in VSCORE is higher, e.g., 5-kind, 4-kind, or full
#	house.
#############################################################################

	elif [ -n "$SSCORE" ]
	then
		case $VSCORE in
		*5-KIND|*4-KIND|*FULL-HOUSE)
			SCORE="$VSCORE"
			;;
		*)
			SCORE="$SSCORE"
			;;
		esac
	fi

#############################################################################
#	Now that we've determined the highest scoring interpretation for
#	this hand, look up its payout and assign that to WIN.
#############################################################################

	case $SCORE in
		ROYAL-FLUSH)	WIN=1000 ;;
		W4-DEUCES)	WIN=800 ;;
		*5-KIND)	WIN=200 ;;
		WILD-ROYAL)	WIN=125 ;;
		STRAIGHT-FLUSH)	WIN=50 ;;
		*4-KIND)	WIN=5 ;;
		*FULL-HOUSE)	WIN=4 ;;
		FLUSH)		WIN=3 ;;
		*STRAIGHT)	WIN=3 ;;
		*3-KIND)	WIN=1 ;;
		*)		WIN=0 ;;
	esac

#############################################################################
#	Adjust and report the balance after this play.
#############################################################################

	let BALANCE=${BALANCE}+${WIN}
	print "$SCORE (balance: $BALANCE)" |
	sed "\
	s/^.*\(LOSER\)/------------ \1/
	s/^\([^-]\)/>>>>>>>>>>>> Win ${WIN} for \1/"

done
