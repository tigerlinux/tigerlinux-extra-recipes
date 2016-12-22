#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Modules - Calling function - with functions name
#
#

print ("")

# Let's import the module, this time using "from" and the module names, and,
# the two variables inside the module:

from mymodule import myfunction01,sumallitems,variable1,variable2

# And define a string and a list:

mystring="GATIBURU"
mylist= [ 1, 3, 20, 31 ]

# Now, let's call the functions inside the module. This time, we can call them directly without
# the module name at the front of the function:

myfunction01(mystring)

print ("The sum of all items on list " + str(mylist) + " is: " + str(sumallitems(mylist)))

# Also, let's see the variables in the module (variable1 and variable2):

print ("")
print (variable1)
print (variable2)
print ("")

# Change one the variables:

variable2 = 99

# print it:

print (variable2)

# And print now variable2 and variable2, with the module name, after reinporting the module:

import mymodule

print (mymodule.variable2, variable2)

print ("")

# If you change the variable the following way, you actually changing the variable inside
# the module, and this is normally a bad practice:

mymodule.variable2 = 78

print (mymodule.variable2, variable2)

print ("")

# END
