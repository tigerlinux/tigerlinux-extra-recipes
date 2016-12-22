#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 22, 2016
# TigerLinux AT Gmail DOT Com
# Metaclasses - Extending classes methods by using metaclasses
#
#

# Note: We'll force python 2.6-2.7 here, as metaclasses declarations between
# series 3 and 2.6/2.7 are different.

import sys

if sys.version_info.major == 2 and sys.version_info.minor >= 6:
    pass
else:
    print ("Unsupported python version. This script must run be run on python 2")
    sys.exit(1)

print ("")

# This time, we'll see something more practical: Using metaclasses in order to augment
# the methods of a class. Then, let's play STAR WARS again !..jejeje

# First, let's define some functions:

# VERY IMPORTANT !. Those functions will be used in a class, so, remember
# to include as first argument the class name, even if you don't use it:
def setshiptocapital(myclass,string):
    return string.upper()

# Due the fact that this function will use attributes defined inside
# the class, we'll use the class name to construct our print outs:
def printshipdata(myclass):
    print ("\nSTARSHIP SPECS FOLLOWS: ")
    print ("\tName:  " + str(myclass.shipname))
    print ("\tClass: " + str(myclass.shipclass))
    print ("\tSpeed: " + str(myclass.shipftlspeed) + " Light-years per hour\n")

# Now, let's define a metaclass that will "extend" any class using it with those
# two previouslly defined functions:

# The trick is easy. The "classdictionary" includes attributes and methods. By
# assigning keys and values to this dictionary, we are effectively adding things
# to any class using this as metaclass
class methodaugmenter(type):
    def __new__(metaname, classname, supers, classdictionary):
        # The first two add the methods
        classdictionary["setshiptocapital"] = setshiptocapital
        classdictionary["printshipdata"]  = printshipdata
        # The last one will add an attribute, that will hold all the
        # names of our starships in a list
        classdictionary["flotilla"] = []
        return type.__new__(metaname, classname, supers, classdictionary) 

# Now, let's define a class:

class starship(object):
    __metaclass__ = methodaugmenter
    def __init__(self, shipname, shipclass, shipftlspeed):
        self.shipname = shipname
        self.shipclass = shipclass
        self.shipftlspeed = shipftlspeed
        # Remember the flotilla attribute in the metaclass ??. Here,
        # we add to the atribute (that is a list) the shipname
        self.flotilla.append(self.shipname)
    def __str__(self):
        return self.shipname
    def __del__(self):
        # On instance destruction, remove our name from the
        # flotilla list. Again, remember the "flotilla" attribute was
        # defined on the "methodaugmenter" metaclass !
        print ("We'll remove %s from our flotilla\n" % (self.shipname))
        self.flotilla.remove(self.shipname)

# And instantiate one object:

xwing = starship("X-Wing", "Fighter Class", 40.5)

# Then, let's use the methods added by the metaclass:

print (xwing.setshiptocapital(xwing.shipname))

# xwing.printshipdata(Name=xwing.shipname,Class=xwing.shipclass,FTL-Speed=xwing.shipftlspeed)
# printshipdata("hello",Name=xwing.shipname,Class=xwing.shipclass,FTL-Speed=xwing.shipftlspeed)
xwing.printshipdata()

# And, print our flotilla (this variable was defined in the augmenter metaclass too:

print ("Our flotilla has the following ships: " + str(xwing.flotilla) + "\n")

# Another ship two ships:

bwing = starship("B-Wing", "Space Superiority Fighter", 90.5)

bwing.printshipdata()

ywing = starship("Y-Wing", "Space Atack/Bomber", 60.32)

ywing.printshipdata()

# Now, see what happened to the .flotilla attribute in the instances and the class:

print ("\nAnd now, our flotilla:\n")

print (xwing.flotilla)
print (starship.flotilla)
print (bwing.flotilla)
print (ywing.flotilla)

# Yes yes yes yes... the attribute "flotilla" augmented by the metaclass "methodaugmenter"
# has the same value, as it's changed by the class at init time !.

print ("\nRemoving the B-WING from our flotilla..\n")

# Let's delete the b-wing:

del bwing

# And see our flotilla attribute:

print ("\nAnd now, our flotilla:\n")

print (xwing.flotilla)
print (starship.flotilla)
print (ywing.flotilla)

# Now, let's remove all other starship instances:

print ("\nDestroying the remaining fleet... we are defenseless against the empire of Darth Pythonic !!\n")

del xwing,ywing

# And print our flotilla... jejeje again..

print ("\nAnd now, our flotilla:\n")

print (starship.flotilla)

# This is by far the best example of how to augment a class by using a metaclass.

print ("")

# END
