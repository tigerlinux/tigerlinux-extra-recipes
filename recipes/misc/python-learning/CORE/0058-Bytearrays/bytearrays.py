#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 20, 2016
# TigerLinux AT Gmail DOT Com
# Byte Arrays
#
#

# IMPORTANT NOTE: THIS EXCERCISE IS ONLY FOR PYTHON 2.6/2.7

print ("")

# See the following statement:

mybytearray = bytearray("Kiki")

# The last statement declares the string "Kiki" as a byte array. 

# Now, see what is the result of calling each index on the array:

for index in range(0,len(mybytearray)):
    print ("My item is: ", mybytearray[index])

# The index object[index] call return not the char but the integer
# of the char. Now see the following loop:

for charorbyte in mybytearray:
    print ("My \"item\" is: ", charorbyte)

# WHOOPSSS !!... Still returns the integer of the char (the ascii code).

# Of course, you can still call a function to return of the original char in
# the string:

for byte in mybytearray:
    print ("The char is: ", chr(byte))


# Note that you can chance a byte into char with "chr()", and likewise, a
# char into byte with "ord()". See this:

for byte in mybytearray:
    print ("The byte is: ", ord(chr(byte)))

# Let's play with things in python:

# First, let's get a list from the byte array:

mylist = list(mybytearray)

print ("My list is: ", mylist)

# Now, with chr, let's play with the list:

for item in mylist:
    print ("The byte is %s and the char is %s" % (item,chr(item)))

print ("")
# END
