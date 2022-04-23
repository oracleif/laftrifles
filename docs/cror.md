# cror: A Shell Script for Pretty Patterns

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
were getting more sophisticated.  I had become more comfortable tackling
complicated utilities with Ksh (Bash would come many years later) as I
saw the power in leveraging shell features and \*nix utilities to produce
interesting results with less effort than would be needed for compiled
languages like C.

It occurred to me that it would be an interesting exercise to write a
symmetric random walk screen toy as a shell script.  That's how my work on
this script began.  I called it cror for "Character-based RORschach".

## Symmetry

2-way "mirroring" was the key to producing the ink blot effect

4-way was a later refinement.  I initially regarded this as a crude
kaleidoscope effect, but later saw it as more of a tile generator (which
motivated a later feature for jumping around the screen more randomly - see
below).

## Portability and performance

Using tput vs. hard-coding for ANSI and HP terminals.

## Constraining the random walk

size limit
looping and pausing
keeping and growing
jumping 


## Two-tone textures

## Color

ANSI and ANSI256

## Interactivity

The crorplay wrapper.
