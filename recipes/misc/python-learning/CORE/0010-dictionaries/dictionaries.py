#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12, 2016
# TigerLinux AT Gmail DOT Com
# Dictionaries
#
#

# first, let's create a simple dictionary:

kiki = {
        "race": "cat",
        "color": "base white with black spots",
        "weight Kg": 4.5,
        "Mouse face": True,
        "Name": "Kiki",
        "Callsign": "Ratonila" 
        }

# let's print it:

print ( "Kiki data complete: " + str(kiki) )

# And parts of the kiki's data:

print ( "Kiki is a \"" + str(kiki["race"]) + "\", and her color is \"" + str(kiki["color"]) + "\"" )

# Dictionary are, like lists, mutable. Let's change kiki's weight:

kiki["weight"] = 3.2

print ( "Kiki's weigth is: " + str(kiki["weight"]) + " Kg" )

# We can also add items to the dictionary, and nest lists or dictionaries into too:

kiki["complete name"] = { "first": "Kiki", "last": "Ratonila" }

print ( "Kiki complete name is \"" + str(kiki["complete name"]["first"]) + " " + str(kiki["complete name"]["last"]) + "\"" )

# Now, we can print the complete Kiki's record:

print ( "Kiki data complete: " + str(kiki) )

# We can reclaim the memory space by erasing all Kiki's data:

kiki = ""

print ( "Kiki data after clean up: " + str(kiki) )

# Now, let's create anothe dictionary:

rayita = {
        "race": "cat",
        "color": "base cream-white with gray-listed spots",
        "weight Kg": 3.5,
        "mouse face": False,
        "name": "Rayita",
        "callsign": "Rayoncita de Rayon",
        "complete name": { "first": "Rayita", "last": "De Rayon" }
        }

print ( "Rayita data is: " + str(rayita) )

# Now, we can sort the keys, and print the keys and it's data using a loop.
# First, we define a list containing the keys, and sort it out:

mykeys = list(rayita.keys())

# Sort it out:
mykeys.sort()

# And loop trough it:

print ("")
print ("Print a sorted dict using old methods:")
for mykey in mykeys:
    print (mykey,"=>",rayita[mykey])
print ("")

# Using sorted function too:

print ("Now the same, but using \"sorted()\" function")
for mykey in sorted(rayita):
    print (mykey,"=>",rayita[mykey])

# End
