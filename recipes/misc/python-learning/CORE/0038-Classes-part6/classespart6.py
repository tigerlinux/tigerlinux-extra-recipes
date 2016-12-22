#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 16, 2016
# TigerLinux AT Gmail DOT Com
# Superclasses, subclasses and method reutilization
#
#

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

# And, let's call the method on both pet's:

nash.printalldata()
print ("")
kiki.printalldata()
print ("")

# The whole point of this excersice is demostrate the ways we can recicle code and
# superclass classes !

# To finish this excersice, let's see some builtins normally available in classes:

# This print the class used by the object instance
print (nash.__class__)
# This, the name of the class
print (kiki.__class__.__name__)
# Here, we'll all variables inside the object. Variables inside an object class are
# part of a dictionary:
print (kiki.__dict__)
# And like any dictionary, we can see the keys:
print (kiki.__dict__.keys())
# Let's loop trough it:
for mykey in nash.__dict__.keys():
    print (mykey," -> ",nash.__dict__[mykey])

print ("")

# END
