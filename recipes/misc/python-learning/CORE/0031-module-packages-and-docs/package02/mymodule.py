#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Modules - Module file with a function - package version
#
#

# Second function, sum all items in a list

def sumallitems(inputlist):
    result = inputlist[0]
    for number in inputlist[1:]:
        result = result + number
    return result

# And, declare another variables

variable2 = 23
