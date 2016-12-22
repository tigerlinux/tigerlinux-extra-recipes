#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Modules - Calling function
#
#

print ("")

# Let's import the module

import mymodule

# And define a string and a list:

mystring="GATIBURU"
mylist= [ 1, 3, 20, 31 ]

# Now, let's call the functions inside the module:

mymodule.myfunction01(mystring)

print ("The sum of all items on list " + str(mylist) + " is: " + str(mymodule.sumallitems(mylist)))
