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
you can just try options to see what happens, though some additional detail for
many of these options will be provided below.


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

I eventually noticed the *rorschach* screensaver for X and, realizing that this
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
name).  This 2-way symmetry is the default mode and cannot be disabled.

4-way symmetry (selected with the ***-4*** option) was a later refinement.  I
initially regarded this as a crude kaleidoscope effect, but later saw it as
more of a tile generator (which motivated a later feature for jumping around
the screen more randomly - see below).


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
in the wake of a mirrored crawl starting from the center of the display.
Unless running in the slow universal mode or with the delay option, this will
quickly fill the display with an uninteresting uniform grid of '#' characters

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

With a size limit available, it was then possible to provide a ***-l*** option
to produce one pattern after another in an endless loop, pausing to wait after
generating a pattern for a user response before clearing the screen and
generating the next one.  For instance, *cror -ls 2000* would draw a random
symmetrical pattern by taking 2000 steps on a random walk from the center of
the screen, wait for the user to hit *enter*, clear the screen, then
draw a new pattern.

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

The ***-k*** option "keeps" the generated pattern in place across iterations
when looping.  Put another way, on each iteration it starts a new pattern
without erasing the previous one.  In this way, a relatively lower size could
be used and the user could then repeatedly run *cror* until a pattern finally
"spread out" to sufficient size while maintaining a fairly dense center
pattern.

While this *-k* flag produced interesting results, the obvious drawback was
that by restarting at the center of the screen it still overwrote much of what
was generated before, even if the previous pattern was not erased entirely.
This could be avoided if the next pattern started generating exactly where the
previous pattern left off instead of restarting at the center of the screen.

The modification to achieve this wound up being less bother than I'd expected,
so I added the new ***-g*** flag to "grow" patterns.  It was now possible to
set a modest *-s* size and just grow the pattern incrementally until a
satisfying result was achieved.

### Random jumps

I had considered the continuity of form guaranteed by stepwise random walks as
a virtue of the design, especially in terms of reflecting the behavior of the
folded ink blots that *cror* was intended to mimic.  But as I began to play
more with varying the "text" that made up these symmetric forms (as we'll
review in the next section), I wanted to have the option of breaking out of the
inkblot model and allow for generation of patterns with gaps and multiple
separate "blobs".

My first thought was to build on the logic of the *-k* and *-g* flags, which
either re-centered or resumed the pattern, and instead start the next
incremental group at a random spot on the screen.  This achieved the desired
result of allowing pattern increments to start at random locations, but
I found the lack of variety in size less interesting than I'd hoped.

I eventually tied these random jumps to other changes in how the pattern was
being generated, i.e., changes in **what** was output as opposed to **where**.


## Changing what's output

Beyond controlling the size and location of the generated pattern elements as
described above, another way of increasing the visual interest in *cror*'s
generated patterns was to change the characters being output to the screen and
their attributes.

### Two-tone textures

As noted earlier, the primary output character used to draw the images onscreen is the
***#*** character.  More texture can be added to the pattern by randomly
switching between this primary character and an alternate character while
drawing.

For maximum contrast the ***-t*** option tells *cror* to use the ***.*** (dot
or period) character as the alternate; the contrast among blank, '.' and '#'
areas provided some additional texture to the generated patterns.

A minor refinement to this idea was to let the caller choose their own
alternate character.  Using the the ***-T*** option instead of *-t* allows you
to specify the alternate character you want to be used.

The random jump feature enabled by *-j* (described above) is triggered by
toggling between the primary and alternate characters.


### Flashing/blinking

Many video display terminals (VDTs) offered various character attributes like
reverse, half-tone, or blinking.  If the ***-f*** "flash" option is specified,
alternate characters will blink on and off.

The flashing attribute can be a bit of a hit or miss proposition, depending on
the particular VDT or emulator/client and optional settings.  It's still
available, but often won't act as expected, making it one of the less reliable
options.

### 8-Color mode

A great advantage of modern clients is their implementation on color displays.
As I maintained *cror*, it seemed an obvious next step to add color to the
patterns it generated to increase visual interest.

The ***-C*** "color" option tells *cror* to cycle through the eight (8) standard
ANSI colors (I didn't bother with the "light" variants) as it generates its
patterns.  While color changes always take place in the transition between
primary and alternate output characters, *-C* takes a numeric argument setting
the minimum number of characters that must be output before such a random color
change is allowed.  This allows the caller to tune the size of color "patches"
to achieve different effects.


### 216-color mode

Some time after the *-C* feature was implemented, I realized that the ssh
client I was regularly working with supported the ANSI 256-color palette.  I
decided more colors were more fun, so I added support for them in *cror*.

The ***-M*** "multi-color" option allows colors to change periodically
across the 216-color "cube" in the ANSI256 palette (in addition to the color
cube ANSI256 supports the 16 standard ANSI colors plus an extended graytone
palette, none of which are of much interest in this application).

*-M* operates much like the *-C* option, but with a significant difference -
colors are selected randomly instead of cycling through the available palette
in a fixed sequence as the *-C* option does.  This seemed desirable because
most of the pairs across the 216 color palette are so closely matched they are
barely distinguishable, likely to make for rather boring subtly shaded patterns.


### Flashing and color for non-ANSI terminals

For terminals that support these attributes, *cror* can use **either** flashing
or color in its output even in universal (*-u*) or HP (*-h*) mode, but
the two options only work **together** reliably in ANSI (*-a* or default) mode.

This is because the *terminfo* database does not support a separate "not blink"
attribute, so in non-ANSI modes flashing is turned off by issuing a sequence
to turn off **all** attributes, which **may include color** depending on how a
particular terminal responds to *tput sgr0*.  Consequently, whenever the
drawing character switches back from the alternate flashing character to the
primary non-flashing character, the color attribute might be reset when the
flashing is turned off.

This issue is largely avoided when running in the default "hardcoded ANSI"
mode, since ANSI includes a specific "not blinking" attribute.  If you are
running in universal mode on some oddball terminal or emulator, you can
experiment with this to see how it behaves, but you could well see limited or
reduced color if the *-f* flashing option is used compared with when it is not.


## Interactivity

To facilitate interactive building of patterns, I eventually wrote the
*crorplay* wrapper script.  This uses a combination of *cror* and simple ksh
script controls to carry out the following workflow:


1. Present the user with a "Next: " prompt

1. User presses Enter to continue or ^C to exit the program.

1. If continuing, cror is called with requested options and commences
drawing its pattern.  Drawing will change colors in sequence at random
intervals, but only after at least CSIZE characters have been output in
the current color.  The pattern will grow by PSIZE characters at a time,
then pause.

1. If the user presses Enter, the pattern will grow by another PSIZE
characters.

1. If the user presses ^C to exit cror, cror will clear the screen on
exit and we return to step #1.


By default *crorplay* will increment its patterns 500 steps at a time, rotating
across the standard ANSI colors no more often than every 50 characters.  You
can add whatever options you like, with -s, -C, and -M overriding the
respective defaults.  This isn't a bad little screen toy for those moments when
a little tranquility is called for.



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

