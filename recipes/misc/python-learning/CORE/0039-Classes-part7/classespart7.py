#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 16, 2016
# TigerLinux AT Gmail DOT Com
# Superclasses, subclasses and method reutilization
# And storing objects in files !
#
#

# This class excersice will show how to store objects in files

print ("")

# Let's define a generic class for cat or dogs called "pet":

class pet:
    def __init__(self,name,color,race,catordog):
        self.name = name             # The animal name
        self.color = color           # The animal color
        self.race = race             # The animal race
        self.catordog = catordog     # cat or dog string

    def printalldata(self):
        print ("\"" + self.name + "\" is a " + self.color + ", " + self.race + " " + self.catordog)

# Now, let's define a "dog" class that subclasses from the pet class, and init
# some of it's data:

class dogpet(pet):
    def __init__(self,name,color,race,dogspecialdata):
        # We pre-init the pet class, with the
        # "dog" string
        pet.__init__(self,name,color,race,"dog")
        # And set's the special extra variable
        self.dogspecialdata=dogspecialdata

    def printalldata(self):
        # We use the original pet "printalldata" method, and add more:
        pet.printalldata(self)
        print ("Special info on this dog: " + self.dogspecialdata)

# We can do the same with a "cat" special class, which also uses the pet class
# as superclass:

class catpet(pet):
    def __init__(self,name,color,race,catmouseface=False):
        # Again, we proceed to pre-init the pet class, with
        # the "cat" string:
        pet.__init__(self,name,color,race,"cat")
        # and set's the extra variable:
        self.catmouseface = catmouseface

    def printalldata(self):
        # Once again, we use the original printdata method from pet, and
        # add more data related to the extra variable on catpet class:
        pet.printalldata(self)
        if self.catmouseface:
            print ("Also, the Cat \"" + self.name + "\" has a mouse face !! :-)")
        else:
            print ("Also, the Cat \"" + self.name + "\" does not has a mouse face !! :-)")

# Ok, let's declare two objects, one will be a cat, the other a dog:

nash = dogpet("Nash","Two Brown tones","Yorkshire","Very good manners !!")
kiki = catpet("Kiki","White with black spots","Cacri (callejero criollo)",True)

# Now, let's store this in a file:

# First, import the needed module, for this: shelve:

import shelve

# And define a database filename. Note that our database will be a
# berkeley db in python 2.x, but can be more files in series 3.x

mydbfilename = "myshelve.db"

# Let's ply:

mydb = shelve.open(mydbfilename)

# Then, let's store our objects:

for myobject in (nash, kiki):
    mydb[myobject.name] = myobject

# Finally, let's close the file:

mydb.close()

# Let's open it again:

mydb = shelve.open(mydbfilename)

# How many records on it ?:

print (len(mydb))

# Now, let's read the thins:

# See the keys ??:

print (list(mydb.keys()))

# From the last statement, we should see our original two objects: kiki and nash. Let's print
# the complete dictionary:

print (mydb.dict)

print ("")

# Now, see this:

kikicloned = mydb["Kiki"]

# And this.

kikicloned.printalldata()

print ("")

# Yes !. We retrieved the original object from the database, then made a copy
# of the object called "kikicloned" from original object "kiki", and this new
# object inherited everything from the original object.

# Note that you can update any data from a database:

# Change the "name" attribute in the cloned object:

kikicloned.name = "Kiki Ratonila"

# And, let's update the database object from the cloned with the chane

mydb["Kiki"] = kikicloned

# Finally, let's close out db:

mydb.close()

# Open it again:

mydb = shelve.open(mydbfilename)

# Clone another object:

anotherclonofkiki = mydb["Kiki"]

# And print it's data:

anotherclonofkiki.printalldata()

# Close the database:

mydb.close()

# And let's do some cleaning:

import os

os.remove(mydbfilename)

print ("")

# END
