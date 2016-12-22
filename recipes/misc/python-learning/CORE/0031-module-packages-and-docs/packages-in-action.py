#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Modules - packages in action !!
#
#

print ("")

# Let's import the module, but this time from a directory. This directory
# contains the module functions and a special file "__init__.py" used by
# python to diferentiate normal dirs from dirs containint module packages:

from package01.mymodule import *
from package02.mymodule import *

# Also, you can change the name with the "as" call.
# All functions from this "package03.othermodule" will
# be referenced as "supermod"

import package03.othermodule as supermod

# Note that you can do the same for functions:
# from XMOD import XFUNCTION as NEWNAMEFORFUNCTION


# And define a string and a list:

mystring="GATIBURU"
mylist= [ 1, 3, 20, 31 ]

# Now, let's call the functions inside the module. This time, we can call them directly without
# the module name at the front of the function:

myfunction01(mystring)

print ("The sum of all items on list " + str(mylist) + " is: " + str(sumallitems(mylist)))

# And, let's print the following variables, also from both packages:

print ("Variables: " + str(variable1) + " and " + str(variable2) + " and " + str(supermod.variable3))

print ("The squared of all items on list " + str(mylist) + " is: " + str(supermod.mysquaredlist(mylist)))

print ("")

# You can print the documentation in the function from package03.othermodule
# using __doc__ attribute:

print ("The documentation for mysquaredlist is: ")
print (supermod.mysquaredlist.__doc__)

# And the documentation from the module too:

print ("The documentation for the module is: ")
print (supermod.__doc__)


# Note that you can have multiple subdir structures in your module tree. Just ensure to include
# the __init__.py file, even if it's blank, in each directory where you plan to include module
# files.

# ALSO: Package03 have docstring. You can view them with:
# pydoc ./package03/othermodule.py

print ("")

# END
