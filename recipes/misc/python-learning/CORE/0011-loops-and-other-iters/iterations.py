#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12, 2016
# TigerLinux AT Gmail DOT Com
# Iterations for dummies
#
#

mystring1 = "kiki!"
mystring2 = "rayita!"

# First loop. Let's go trough the characters of a string:

for char in mystring1:
    print (char.upper())

# Second loop, with a variable and a while

number = 10
while number > 0:
    print ( mystring2 * number )
    number -= 1

# Here, with a list comprehension, we can omit a loop like:
#mysquaredlist = []
#for number in [ 1, 2, 3, 4, 5, 6, 7 ]:
#    squares.append(x ** 2)
# ehh... we'll see comprehensions later with more detail !

mysquaredlist = [ number ** 2 for number in [1,2,3,4,5,6,7]  ]

print ( "My squared list is: " + str(mysquaredlist) )

# This sample loop, tests if a key on a dictionary is missing:

mydict1 = { "a": 1, "b": 2, "c": 3 }

print ( "My dict is: " + str(mydict1) )

# Now, let's try to print keys a, c and "f"... f does not exist...

for key in ["j","a", "c", "f"]:
    if not key in mydict1:
        print ("Key \"" + key + "\" is missing")
    else:
        print (key,"=>",mydict1[key])

# End
