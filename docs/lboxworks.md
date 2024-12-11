# lboxworks

Most of the game scripts are pretty straightforward, but *lboxworks* bears some
additional explaining.  It's not a game in itself, but provides a handy
workspace for solving the **Letterboxed** puzzles featured in the NY Times.

## The game

In Letterboxed, the player is presented with a square play area.  Along each
side of the square there are 3 letters.  The player must form words by drawing
lines from one letter to the next, but lines can only be drawn from one side to
another.  Words can only be formed using the provided letters, and no word can
contain two consecutive letters from the same side of the square (a significant
constraint).

The goal is to build a chain of words that eventually use all of the letters
around the square.  The player can start wherever they choose, but once
underway each new word in the chain must start with the last letter of the
previous word.  The player's performance is judged by the number of words they
need to use to "touch" all the letters - the fewer words used the better, and
each puzzle includes a "par" score for the number of words the player is
expected to need to complete their chain.


## Usage

***lboxworks*** accepts the four (one for each side of the square) 3-letter lists
to start with, then keeps track of the words you create while attempting to
build your word chains.  On each "turn" the player is shown the current status
of the puzzle, i.e., the current sequence of words in the chain, unused letters
remaining, the four 3-letter groups, and the list of words guessed so far.

Below the status display, the player is presented with a menu of available
operations, allowing them to add a word to their word list, delete a word from
that list, select a word from the list to add to the beginning or end of their
word chain, or clear the word chain to start over.

It's easiest to understand how all this works by reviewing an example.  Below
we see a Letterboxed puzzle as partially worked in *lboxworks*:

```
----------> Solution so far:  emerald durable
--------> Remaining letters: xfit
------------> Letter groups: mux afi lrt deb
----------> Available words:
admire          area            emerald         idle
admit           durable         era             literature
alarm           elf             exam            maritime
amateur         elite           flexible        texture

Enter operation
[b]egin solution w/word
[e]nd solution w/word
[a]dd to word list
[d]elete word from list
[r]eset solution
[q]uit:

```

So given the "Letter groups" *mux, afi, lrt,* and *deb*, we have so far
built the words listed under "Available words:".  From these, we've selected
words to start the chain shown after "Solution so far:", and after "Remaining
letters:" we can see what letters have not yet been used in our chain.

The operations now available to us are:

###a - add to word list

This option will allow us to enter words to add to the word list.  When a word
is entered, the script checks to make sure that 1) it only contains letters
from the listed letter groups, 2) it does not contain two consecutive letters
from any group, and 3) it is not already in the word list.  If these tests
fail, an error message is returned.

Either way, we can continue entering words to add to the list, which persists
for the life of the current game session.  If we hit *Enter* without first
entering a word, we return to the main menu.

###d - delete a word from the list

There is no dictionary built into the script, so it is possible to enter words
with typos and/or words that might be rejected by the Letterboxed application
(e.g., it does not accept proper nouns).


###b - choose a word to add to the beginning of the chain

###e - choose a word to add to the end of the chain

###r - reset the chain

###q - quit the game

