#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Modules - Calling function - with asterisk
#
#

print ("")

# Let's import the module, this time using "from":

from mymodule import *

# And define a string and a list:

mystring="GATIBURU"
mylist= [ 1, 3, 20, 31 ]

# Now, let's call the functions inside the module. This time, we can call them directly without
# the module name at the front of the function:

myfunction01(mystring)

print ("The sum of all items on list " + str(mylist) + " is: " + str(sumallitems(mylist)))
