# cror: A Shell Script for Pretty Patterns

*cror* doesn't need much in the way of documentation (I mean, just play with
it), but it's an odd little shell script and I wanted to explain where it came
from and some general ideas about its use.  You might search this doc for some
ideas on how to play with it, but it's mainly a place to record some thoughts
on how it evolved.

## Motivation

I've long been fascinated with the visual effects that can be produced by
simple random walks, writing small programs to bring these to my computer
displays.  Initially, this took the form of "worm" programs, where one or more
strings of light blocks or characters would crawl randomly around the screen,
sometimes amusingly erasing or "eating" whatever was on the display.

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
associations.

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
***-a*** option for hard-coded ANSI cursor positioning.

It did cross my mind to go beyond inefficient recurring calls to *tput* and
special support for a couple of specific terminal control sets, but as it
happens ANSI cursor controls took over almost the entire character
console/terminal space.  With all those bases covered and the world moving on,
I haven't been inclined to invest the effort in figuring out how to make a
more portable approach more efficient.  The script now just assumes ANSI
unless told otherwise.

### Running it anywhere

For those who'd like to run *cror* on an old ADM 5 terminal they find laying
around out there, the ***-u*** "universal" option still provides access to the
original slower *tput*-based terminal control.  Such old terminals don't have
much in the way of screen real estate anyway, so even in universal mode the
script can fill the available space quickly enough.


### Slowing it down

Having gotten the script to generate its "ink blots" so much more quickly, I
eventually realized that there had sometimes been entertainment value in being
able to watch patterns form more slowly as they were being drawn.  To get that
effect more directly without burning CPU cycles on *tput* calls, I introduced
a delay option ***-d*** which tells *cror* how long to sleep (*-d* takes an
argument for the number of seconds) after output of each character.  To be
really useful this requires that the system have a version of *sleep* that
accepts arguments of fractional seconds.  Granularity on this is limited - on
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
visual interest, but ultimatley replaces the concept of an ink blot with that
of a swirling mosaic - nice, but not the same.

### Size limit

The first and most obvious solution was to set a fixed size for the pattern to
generate before exiting the script.  The ***-s <nbr of iterations>*** option
does exactly this.  

### Looping and pausing

With the concept of a size limit available, it was then possible to provide a
***-l*** option to produce one pattern after another in an endless loop,
pausing to wait after generating a pattern for a user response before
generating the next one.  For instance, *cror -ls 2000* would draw a random
symmetrical pattern by taking 2000 steps on a random walk, then wait for the
user to hit *enter* before clearing the screen and drawing a new pattern.




### Keeping and growing

### Jumping 

## Changing what's output

### Two-tone textures

### 8-Color mode

### 216-color mode

ANSI and ANSI256

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
> occasionally incorporating features from *ksh93* or even *zsh* (to which I'd
> say stop pretending it's *ksh*).
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
> *ksh*, despite being buggy and incompatible in its own right.  At this
> juncture I'm starting to think there's a stealth agenda to discredit *ksh*
> by delivering sub-par workalikes under the same name.



## Unexpected uses

