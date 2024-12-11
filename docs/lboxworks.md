# lboxworks

Most of the game scripts in this package are pretty straightforward, but
*lboxworks* bears some additional explaining.  It's not a game in itself, but
provides a handy workspace for solving the **Letterboxed** puzzles featured in
the NY Times.

## The game

In Letterboxed, the player is presented with a square play area.  Along each
side of the square there are 3 letters.  The player must form words by drawing
lines from one letter to the next, but lines can only be drawn from one side to
another.  As a result, words can only be formed using the provided letters, and
no word can contain two consecutive letters from the same side of the square (a
significant constraint).

The goal is to build a chain of words that eventually use all of the letters
around the square.  The player can start wherever they choose, but once
underway each new word in the chain must start with the last letter of the
previous word.  The player's performance is judged by the number of words they
need to use to "touch" all the letters - the fewer words used the better, and
each puzzle includes a "par" score for the number of words the player is
expected to need to complete their chain.


## Usage

***lboxworks*** accepts no flags, and the arguments are optional.  If we
provide at least four arguments, the first three letters of each of these are
interpreted as the four 3-letter groups along each side of the puzzle square.
If less than four arguments are provided, the command line is ignored and we
are prompted individually for each of the four letter groups.

Any additional arguments will be used to start the word list.  It should be
noted that the ability to provide an initial word list is intended primarily as
a convenience for restarting a session that had to be interrupted.  At this
time no validation is applied to these words, though that is planned for a
future enhancement.

With the letter groups established, *lboxworks* then keeps track of the words
we create while attempting to build our word chains.  On each "turn" we are
shown the current status of the puzzle, i.e., the current sequence of
words in the chain, unused letters remaining, the four 3-letter groups, and the
list of words guessed so far.

Below the status display, we are presented with a menu of available
operations, allowing us to add a word to our word list, delete a word from
that list, select a word from the list to add to the beginning or end of our
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
[a]dd to word list
[d]elete word from list
[b]egin solution w/word
[e]nd solution w/word
[r]eset solution
[q]uit:

```

So given the "Letter groups" *mux, afi, lrt,* and *deb*, we have so far
built the words listed under "Available words:".  From these, we've selected
words to start the chain shown after "Solution so far:", and after "Remaining
letters:" we can see what letters have not yet been used in our chain.

The individual operations are explained below.

### Operations

#### a - add to word list

This option will allow us to enter words to add to the word list.  When a word
is entered, the script checks to make sure that 1) it only contains letters
from the listed letter groups, 2) it does not contain two consecutive letters
from any group, and 3) it is not already in the word list.  If these tests
fail, an error message is returned.

Either way, we can continue entering words to add to the list, and after each
addition the status information is updated.  The word list persists for the
life of the current game session.  If we hit *Enter* without first entering a
word, we return to the main menu.

Note that adding a word to the word list does **not** remove letters from the
"Remaining letters" list.  Letters are only removed from this list when words
are added to the **Solution** word chain.

#### d - delete word from list

There is no dictionary built into the script, so it is possible to enter words
with typos and/or words that might be rejected by the Letterboxed application
(e.g., it does not accept proper nouns).  In these cases, using the [d]
operation will present us with the word list in a menu so that we can select a
word for removal.

#### b - begin solution w/word

The solution is built up by adding words to the chain.  The [b] operation is
used to add a word to the **beginning** of the chain.  When selected, it will
present a numbered menu of all words in our list that end with the first letter
of the word at the beginning of the current chain.

If we are just starting (i.e., the solution is currently empty) the menu will
include **all** of the words in the current list.

If for any reason you change your mind (e.g., after reviewing the list and the
remaining letters you think of a different word you would rather use and want
to add it to the word list), entering anything but one of the numbers in the
menu will exit the operation and return you to the main menu without adding a
word to the solution.

If a solution has been started but **none** of the words in the current list
end with the right letter, the [b] operation does nothing.

Once a word is selected from the menu, it will be added to the beginning of the
solution chain and its letters removed from the "Remaining letters" list.

#### e - end solution w/word

As one might expect, the [e] operation is similar to the [b] operation, except
that the word selected from the numbered menu will be added to the **end** of the
solution word chain.  The menu will include only those words that begin with
the last letter of the last word in the current chain.  Otherwise, [e] works
just like the [b] operation.

Either the [b] or [e] operation can be used to start a new solution.

#### r - reset solution

If you reach an impasse or want to change your solution, the [r] operation
allows you to reset the workspace by clearing the current solution and
repopulating the "Remaining letters" list.  This does **not** clear the
"Available words" list, although as noted above individual words can be removed
from the list using the [d] operation.

#### q - quit

This quits the game and exits the script.

