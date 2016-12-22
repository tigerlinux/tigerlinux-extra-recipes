#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 13, 2016
# TigerLinux AT Gmail DOT Com
# Loops with ranges
#
#

# A simple loop with range:

print ("")

# Print all numbers from 0 to 21

for number in range(22):
    print (number)

print ("")

# print all numbers from -3 to 2

for number in range(-3,3):
    print (number)

print ("")

# print: 0, 2, 4, 6, 8

for number in range(0,10,2):
    print (number)

print ("")

# print: 1, 3, 5, 6, 9

for number in range(1,11,2):
    print (number)

print ("")

# Let's define the string:

mycat = "RrAaYyIiTtAa"

# First, print the capitals:

for letterpos in range(0,len(mycat),2):
    print (mycat[letterpos])

print ("")

# Now, the lower's:

for letterpos in range(1,len(mycat),2):
    print (mycat[letterpos])

print ("")

# Change the value of a list:

# See the list of numbers:

mylist = [ 100,110,120,130,140 ]

# We want to add a "1" to each number in the list:

print ("Original List: " + str(mylist))

for listposition in range(len(mylist)):
    mylist[listposition] += 1

print ("Changed List: " + str(mylist))

print ("")

# END
