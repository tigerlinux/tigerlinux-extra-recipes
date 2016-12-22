#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 13, 2016
# TigerLinux AT Gmail DOT Com
# Zip and Map
#
#

# Let's define the following lists of numbers:

print ("")

list1 = [ 1, 2, 3, 4 ]
list2 = [ 2, 3, 4, 5 ]

# The following loop using zip, instruc the zip function to create a list of tuples
# from both lists:

for (value1, value2) in zip(list1,list2):
    print (str(value1) + "^" + str(value2) + "=" + str(value1**value2))

print ("")

# Also, with map instead of zip:

# ALERT: This will generate an error in PYTHON3 so we'll show the map only
# in py2

import sys

if sys.version_info.major == 2:
    for (value1, value2) in map(None,list1,list2):
        print (str(value1) + "^" + str(value2) + "=" + str(value1**value2))
else:
    pass

print ("")

# Note that map requires the "None" as first option in order to fill different sized lists.
# See the following examples of the results of different sized lists with zip and map:

list1 = [ "a", "b", "c", "d" ]
list2 = [ 1, 2, 3 ]
list3 = zip(list1,list2)
list4 = map(None,list1,list2)

print ("Original lists: " + str(list1) + " and " + str(list2))
print ("List with zip : " + str(list3))
print ("List with map : " + str(list4))

# As you can see in the prints, while zip truncate's to the shorten lenght, map fill's the
# missing values with "None"

print ("")

# Let's do something more usefull. Using zip, we can create a dictionary from a pair of lists,
# one containing the keys, the other the values:

# First, let's define our lists:

listkeys = [ "gato1", "gato2", "gato3" ]
listvalues = [ "Kiki", "Rayita", "Negrito" ]

mydict = dict(zip(listkeys,listvalues))

print ("My first list is: " + str(listkeys))
print ("My second list is: " + str(listvalues))
print ("The dictionary resulting from using zip is: " + str(mydict))

print ("")

# END
