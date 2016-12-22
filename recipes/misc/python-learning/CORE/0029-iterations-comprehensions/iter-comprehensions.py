#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# More iterations with comprehensions
#
#

print ("")

# Let's review some comprehensions here:

# First, let's remember how can we create dictionaries with comprehensions:

mydict1 = dict( (value, value**2) for value in [1,2,3,4,5,6] )
mydict2 = { value: value**2 for value in [1,2,3,4,5,6]  }
mydict3 = { value: value**3 for value in [1,2,3,4,5,6] if (value**3) % 2 == 0 }

print (mydict1)
print (mydict2)
print (mydict3)

print ("")

# Also remember that, while lists can keep order, set does not when using
# comprehensions:

mylist1 = [ val1 + val2 for val1 in [ "red", "blue", "black" ] for val2 in [ "-one", "-two", "-three"  ] ]

print (mylist1)

# See the same comprehension using a set:

myset1 = { val1 + val2 for val1 in [ "red", "blue", "black" ] for val2 in [ "-one", "-two", "-three"  ] }

print (myset1)

# Now, using a dictionary. Again, a sample for a tipical "fighter squadrons". In this sample, the list will
# return the plane designation (red-one) and the squadron which belongs (red):

mydict4 = { val1+val2: val1 for val1 in [ "red", "blue", "black" ] for val2 in [ "-one", "-two", "-three"  ] }

print (mydict4)

print ("")

# END
