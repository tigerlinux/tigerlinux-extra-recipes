#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12, 2016
# TigerLinux AT Gmail DOT Com
# Sample random usage
#
#

# Let's import random library:

import random

# First, let's define a "list":

mylist = [ 23, 56, 89, 112 ]

# Print a simple random number:

print ( "This is a random number: " + str(random.random()))

# Now, from the list, let's randomlly pick any of the four numbers:

print ( "Let's pick a number from the list: " + str(mylist) + " : " + str(random.choice(mylist)))

# You can see more at: https://docs.python.org/2/library/random.html

print ( "More random-lib functions explained at: https://docs.python.org/2/library/random.html" )

# END
