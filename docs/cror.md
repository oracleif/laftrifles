# cror: A Shell Script for Abstract ASCII Art Patterns

*cror* doesn't need much in the way of documentation (I mean, just play with
it), but it's an odd little shell script and I wanted to explain where it came
from and some general ideas about its use.  You might search this doc for some
ideas on how to play with it, but it's mainly a place to record some thoughts
on how it evolved.

## Showing the usage message

Calling *cror* with a  *-?* flag (or any other unrecognized flag, though note
that the *-h* flag sometimes used to show help is used here to specify HP
terminal cursor positioning) will cause it to output a simple usage message as
follows:

```
cror [options]
options: [-a] [-h] [-u] [-4] [-j] [-p pause-time] [-d delay] [-s size]
         [-l] [-k] [-g] [-r] [-t] [-T x] [-c] [-b] [-f] [-{C|M} csize]

CURSOR POSITIONING OPTIONS
-a = assume ANSI cursor positioning (default)
-h = assume HP cursor positioning
-u = universal mode, use tput calls (MUCH slower)

OTHER OPTIONS
-4 four-way symmetry for kaleidoscope effect
-j jump to random location on color or tone change
-p pause-time = seconds to sleep between loop CYCLES (only meaningful with -l)
-d delay = seconds to sleep between STEPS (decimals supported)
-s size = number of iterations per pattern (default is no limit)
-l = loop mode - repeats until interrupted (only meaningful with -s)
-k = keep screen, do not erase before each iteration
-g = grow pattern, like -k but do not recenter cursor
-r = recalculate screen size for each pattern
-t = two-tone, switches between '#' and '.' when drawing
-T = configurable two-tone, switches between '#' and given 'x' when drawing
-c = clear screen on program termination
-C csize = allow color change every <csize> chars (if supported)
-M csize = allow ANSI-256 color change every <csize> chars (if supported)
-b = ring bell when switching between '#' and '.' (good with -tTC only)
-f = make two-tone characters flash
```

That explains most of what you need to know.  If in doubt about specifics
you can just try options to see what happens, and some additional detail for many
of these options will be provided below.


## Motivation

I've long been fascinated with the visual effects that can be produced by
random walks (largely because I'm easily amused by simple eye candy and
lazy enough to appreciate that such algorithms are easy to implement), so
I wrote a few different small programs to bring these to my computer
displays.  Initially, this took the form of "worm" programs, where one or more
strings of light blocks or characters would crawl randomly around the screen,
leaving trails or not, optionally erasing or "eating" whatever was on the
display for additional amusement value (through the simple expedient of not
clearing the screen first - I did admit to being lazy).

I eventually noticed the rorschach screensaver for X and, realizing that this
was in effect the product of a symmetrical random walk, began trying to
re-create the effect on lower resolution block or character-based displays.
My initial efforts used the simple block graphics available on the display of
my CP/M-based Kaypro 1 driven by a program written with a tiny C compiler, and
it quickly became clear that producing the equivalent of a Rorschach ink blot
on screen was pretty easy even with such limited hardware.

At around this same time, the shell scripts I was preparing in my work life
were getting more sophisticated.  I had become more comfortable building
application admin tools with Ksh (Bash would come many years later) as I saw
the power of scripting to produce useful results (and with much less effort
than would be needed for compiled languages like C).

It wasn't long before these two interests overlapped, and I thought it could
be an interesting exercise to write a symmetric random walk screen toy as a
shell script.  That's how my work on this script began.  I called it cror for
"Character-based RORschach", and every few years I come back to it, just to
play, or perhaps to throw in another feature or two after some random
inspiration.

## Symmetry

2-way "mirroring" was the key to producing the Rorschach effect.  A simple
random walk (i.e., move the cursor one position in a randomly selected
direction, output one character, repeat) gets a lot more interesting when
mirrored across the screen, creating an illusion of intentionality, even
design.  Present a random symmetric image to a human observer and in many cases
the visual cortex, cultural programming, and the subconscious mind will find
some way to generate structure and meaning from the most tenuous forms and
associations (as is the case with the ink blot tests that inspired the script's
name).

4-way symmetry was a later refinement.  I initially regarded this as a crude
kaleidoscope effect, but later saw it as more of a tile generator (which
motivated a later feature for jumping around the screen more randomly - see
below).

## Portability and performance

### Speeding it up

When it came to moving and mirroring the cursor across the screen, *tput* was
the most obvious choice for generating the required escape sequences.  Using
*tput* also made the script portable to any terminal type supported by
*terminfo*.  The catch was that the very nature of *cror*'s random walks
requires issuing a continuous stream of those sequences, and issuing *tput*
commands for every cursor movement made the drawing process painfully slow
even on modern hardware (much less the older minicomputers on which *cror* was
originally running).

I eventually added a ***-h*** option to just emit hard-coded cursor
positioning sequences for HP terminals (which were the terminals and emulators
I was using most often at the time).  It made a huge difference, and for the
first time I appreciated how fast the script could be when not making
context switches to load *tput*.

Seeing this improvement I wanted to have it available when running in graphical
Unix desktops as well, but Xterm uses ANSI escape sequences for cursor
positioning (and yes, HP sequences were completely different), so I added the
***-a*** option and supporting logic for hard-coded ***ANSI*** cursor positioning.

It did cross my mind to go beyond inefficient recurring calls to *tput* and
specific support for HP and ANSI (e.g., with an initial retrieval of
*terminfo* attributes interpreted to generate complete escape sequences), but as
it happens ANSI cursor controls took over almost the entire character
console/terminal field.  With all those bases covered and the world moving on,
I haven't been inclined to invest the effort in figuring out how to make a more
portable approach more efficient.  The script now just assumes ANSI unless told
otherwise (making the *-a* flag redundant but still accepted).

### Running it anywhere

Though ANSI is the default I never took out the *tput*-based functions, so
those who'd like to run *cror* on, e.g., an old ADM 5 terminal they find laying
around out there still can.  The ***-u*** "universal" option provides access to
the original slower *tput*-based terminal control.  Such old terminals don't
have much in the way of screen real estate anyway, so even in universal mode
the script can fill the available space quickly enough.  Most features allowing
control of the output (see *Managing the random walk* and *Changing what's
output* below) work in universal mode, but note that color is only supported
for ANSI terminals.


### Slowing it down

Having gotten the script to generate its "ink blots" so much more quickly, I
eventually realized that there had sometimes been entertainment value in being
able to watch patterns form more slowly as they were being drawn.  To get that
effect more directly without burning CPU cycles on *tput* calls, I introduced a
delay option ***-d*** which tells *cror* how long to sleep (*-d* takes an
argument for the number of seconds) after output of each character.  For
obvious reasons, to be of any practical value this requires that the system
have a version of *sleep* that accepts arguments of fractional seconds (as any
reasonably current Linux system would).  Granularity on this is limited - on
Linux systems I've been working with I've noticed that values less than .001
(e.g., .0009) are treated as 0, so that's about as fast as you can get without
effectively going back to no delay at all.  Even so, specifying *-d .001* is
still noticeably faster than the delay introduced by making calls to *tput*.



## Managing the random walk

Called with no options, *cror*'s default behavior is to output '#' characters
in the wake of a mirrored crawl around the display.  Unless running in
universal mode or with the delay option, this will quickly fill the display
with an uninteresting uniform grid of '#' characters

Slowing the crawl with *-d* can make this a bit more interesting, but the end
result is the same - a screen filled with hash marks.  Altering the output
characters (which we'll discuss in the next section) can help in terms of
visual interest, but ultimately replaces the concept of an ink blot with that
of a swirling mosaic - nice, but not the same.

### Size limit

The first and most obvious solution was to set a fixed size for the pattern to
generate before exiting the script.  The size option ***-s*** does exactly this,
taking a single argument for the number of steps to take on the random walk
before exiting.

### Looping and pausing

With the concept of a size limit available, it was then possible to provide a
***-l*** option to produce one pattern after another in an endless loop,
pausing to wait after generating a pattern for a user response before
generating the next one.  For instance, *cror -ls 2000* would draw a random
symmetrical pattern by taking 2000 steps on a random walk, then wait for the
user to hit *enter* before clearing the screen and drawing a new pattern.

An obvious refinement was to allow the script to advance to the next pattern
automatically if the operator did not reply within a specified number of
seconds.  This is what the pause  ***-p*** option does; note that giving *-p*
an argument of 0 is interpreted as "wait indefinitely", so pretty much the same
as not providing the flag at all.


### Keeping and growing

Interacting with the loop features outlined above, I noticed that setting the
size too low could produce patterns too small to be interesting if the random
walk "doubled back" on itself too much.  On the other hand, setting it too
large could "overshoot" an interesting image and effectively erase it by
drawing over it.

### Jumping 

## Changing what's output

Beyond controlling the size and location of the generated pattern elements as
described above, another way of increasing the visual interest in *cror*'s
generated patterns was to change the characters being output to the screen and
their attributes.

### Two-tone textures

As noted, the primary output character used to draw the images onscreen is the
***#*** character.  More texture can be added to the pattern by randomly
switching between this primary character and an alternate character while
drawing.

For maximum contrast the ***-t*** option tells *cror* to use the ***.*** (dot
or period) character as the alternate.  If you want to try something different,
the ***-T*** option allows you to specify your own alternate character.

### Flashing/blinking

### 8-Color mode

### 216-color mode

ANSI and ANSI256

### Flashing and color for non-ANSI terminals

For terminals that support these attributes, *cror* can use **either** flashing
or color in its output even in universal (***-u***) or HP (***-h***) mode, but
the two options don't work together reliably.

The *terminfo* database does not support a separate "not blink" attribute, so
in non-ANSI modes flashing is turned off by issuing the sequence to turn off
**all** attributes, which **may include color** depending on how a particular
terminal responds to *tput sgr0*.  Consequently, whenever the drawing character
switches back from the alternate flashing character to the primary non-flashing
character, the color attribute might be reset when the flashing is turned off.
If running in universal mode on some oddball terminal or emulator, you can
experiment with this to see how it behaves, but you could well see limited
or reduced color if the ***-f*** flashing option is used compared with when it
is not.

## Interactivity

The crorplay wrapper.

## *cror* and flavors of Korn

There are some idiosyncrasies of the Korn shell that mesh well with the way
that *cror* was developed, and while it wouldn't be impossible to achieve a
similar result with Bash, it would be more effort than it's worth due to
Bash's own idiosyncrasies (the counter-intuitive loss of data from unexpected
spawning of subshells being the worst - though I've largely resigned myself to
this mess as I've moved to Bash, the excuses and workarounds for this misstep
remain laughable to this day).

That said, one must be very careful to get the **right** version of Korn
shell, by which I mean *ksh93*, the only fully functional Korn shell.
That was the command interpreter used to develop *cror* and no effort was made
to avoid features or techniques that don't work well on other "Korn-like"
shells.  Running *cror* with, e.g., *ksh2020* yields poor performance in any
mode, and apparent changes in *ksh2020*'s interrupt handling mean that
*crorplay* doesn't work at all.

So seriously - if you want to run *cror*, just install *ksh93* and be done
with it.

> **SIDE RANT:**  I don't mean to disparage the efforts of the folks working
> hard on other "*ksh*" variants, but the harsh truth is that none of those
> teams have produced stable implementations that are fully compatible with
> *ksh93*.  For the most part they aren't even trying, as it appears the real
> goal is achieving compatibility with the *ksh88*-influenced POSIX standard,
> occasionally incorporating features from *ksh93* (so tiny thanks) or even
> *zsh* (to which I'd say stop pretending it's *ksh*).
>
> It's been an unfortunate habit of Linux and BSD distributions to include
> these degraded versions of Korn shell (if any).  This is partly for
> ideological free software reasons and partly due to AT&T recalcitrance, but
> the bottom line is that *ksh93* has always taken some extra effort to put in
> place.
> 
> This has lately gotten a lot worse with the perverse decision of some
> distros to start treating the experimental *ksh2020* as somehow worthy of
> broad distribution, making it the version you get when you install plain
> *ksh*, despite being buggy and incompatible in its own right.  There's no
> legitimate reason for this, so one may be forgiven for suspecting a stealth
> agenda to discredit *ksh* by delivering sub-par workalikes under the same
> name.



## Unexpected uses

