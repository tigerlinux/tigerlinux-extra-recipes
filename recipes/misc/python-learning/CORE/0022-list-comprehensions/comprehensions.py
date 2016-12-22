#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 13, 2016
# TigerLinux AT Gmail DOT Com
# List Comprehensions
#
#

# We'll need some functions from os library:

import os

print ("")

# Let's play with list comprehensions

# First sample. This generates a list of squared numbers using as}
# base numbers 1 to 7

list1 = [ number ** 2 for number in [1,2,3,4,5,6,7]  ]

print ("First list: " + str(list1))

print ("")

# Same, but combined with range:

list2 = [ number ** 2 for number in range(1,8) ]

print ("First list: " + str(list2))

print ("")

# Another list, based on this script:

scriptname = "comprehensions.py"

list2 = [ line for line in open(scriptname,"r") ]

print (list2)

print ("")

# Another one, with even more manipulation

list3 = [ line.rstrip().upper() for line in open(scriptname,"r") ]

print (list3)

print ("")

# Like the last one, but ommiting all lines beggining with "#"

list4 = [ line.rstrip().upper() for line in open(scriptname,"r") if line[0] != "#" ]

print (list4)

print ("")

# This like the last, but also removes blank lines

list5 = [ line.rstrip().upper() for line in open(scriptname,"r") if line[0] != "#" and line.strip() ]

print (list5)


print ("")

# The next is a tipical permutation of string chars:

text1 = "kiki"
text2 = "rayita"

list6 = [ char1 + char2 for char1 in text1 for char2 in text2 ]

print (list6)

print ("")

# And with numbers and operations:

numbers1 = [ 1, 2, 3, 4 ]
numbers2 = [ 1, 2, 3 ]

list7 = [ num1*num2 for num1 in numbers1 for num2 in numbers2 ]

print (list7)

print ("")

# END
