#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 13, 2016
# TigerLinux AT Gmail DOT Com
# Special Branching Cases
#
#

# See the following if/elif/else case:

gato = "kiki"

if gato == "negrito":
    print ("Black cat with white spots and very beautifull")
elif gato == "rayita":
    print ("Base creamy-white with gray-listed spots")
elif gato == "kiki":
    print ("Base white with black spots and funny mouse face")
else:
    print ("Bad Choice")

# The former code can be changed to a dictionary-based form:

myoptions = {
        "negrito": "Black cat with white spots and very beautifull",
        "rayita": "Base creamy-white with gray-listed spots",
        "kiki": "Base white with black spots and funny mouse face"
        }

# Now, see the effect of using a good and a bad choice:

# Good choice, with former variable gato = "negrito" this time:

gato = "negrito"

print (myoptions.get(gato,"Bad Choice"))

# Bad choice now:

gato = "miaumiau"

print (myoptions.get(gato,"Bad Choice"))

# Also, we can do the same the following way:

gato = "rayita"

if gato in myoptions:
    print (myoptions[gato])
else:
    print ("Bad Choice")

gato = "nonecathere"

if gato in myoptions:
    print (myoptions[gato])
else:
    print ("Bad Choice")

# Now, let's look at a third way to skin a cat. Se the following if/else form:

gato = "kiki"

if gato == "kiki":
    caraderaton = True
else:
    caraderaton = False

print ("Cara de raton: " + str(caraderaton))

# You can express the if/else form the following way:

gato = "negrito"

caraderaton = True if gato == "kiki" else False

print ("Cara de raton: " + str(caraderaton))

# That way, you can compress a if/else form in a single line and with more efficient code.


# END
