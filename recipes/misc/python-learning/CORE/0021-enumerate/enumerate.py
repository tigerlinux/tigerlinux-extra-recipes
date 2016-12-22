#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 13, 2016
# TigerLinux AT Gmail DOT Com
# Enumerate function
#
#

# Let's see the following case:

print ("")

mylist = [ "Kiki", "Rayita", "Negrito", "Kisa", "Gatiburu" ]

counter = 1

for cat in mylist:
    print ("\"" + cat + "\" is the cat number: " + str(counter))
    counter += 1

print ("")

# Now, let's see the same using enumerate function:

mylist = [ "Kiki", "Rayita", "Negrito", "Kisa", "Gatiburu" ]

for (position, cat) in enumerate(mylist):
    print ("\"" + cat + "\" is the cat number: " + str(position+1))

print ("")

# Using enumerate let's you get rid of positional or counter variables. Just
# use both the "position/counter" variable and the item variable inside the
# parenthesis before the "for", and "enumerate" for the iterable item (list, dict,
# range, etc,)

# END
