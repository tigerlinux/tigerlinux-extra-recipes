#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Modules - Module file with a function
#
#

# Let's define two functions here:

# First function, just print a string:

def myfunction01(string):
    for char in string:
        print (char)

# Second function, just return the sum of all numbers in a list:

def sumallitems(inputlist):
    result = inputlist[0]
    for number in inputlist[1:]:
        result = result + number
    return result

# And, declare two variables

variable1 = 22
variable2 = 23
