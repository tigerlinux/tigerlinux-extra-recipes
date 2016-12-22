#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# This shows simple way to use command line args
#
#

# Import sys library:

import sys

# Any command line argument will be stored in the
# list sys.argv, where sys.argv[0] is the program
# or script name:

print ("")

print ("I was called as: " + str(sys.argv[0]))

print ("")

print ("My arguments are: ")
print ("")

for position in range(1,len(sys.argv)):
    print (sys.argv[position])

print ("")

# END
