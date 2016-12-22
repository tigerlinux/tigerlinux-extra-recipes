#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 20, 2016
# TigerLinux AT Gmail DOT Com
# Descriptors
#
#

print ("")

# Descriptors are classes which intercepts certain attribute
# operations, specifically __set__, __get__ and __delete__
# operations. They are conceived as a way to provide
# attribute access inside "client" classes.

# For explaining this better, let's create a descriptor class. Note
# that this kind of class NEED to be defined as "new style":

class SpaceshipName(object):
    # Descriptor classes need __get__, __set__ and __delete__
    #
    # __get__ method. It needs self, instance and owner as parameters.
    # The instance is the "client instance" using the descriptor, and
    # the owner is the "owner class" from which the client instance was
    # instantiated:
    def __get__(self,clientinstance,ownerclass):
        print ("*** Obtaining starship name ***")
        return clientinstance._spaceshipname
    # __set__ method. It needs self, clientinstance and spcvalue parameters.
    # The instance is, again, the "client instance" using the descriptor
    # class, and value is just the value we want to assign to a specific
    # variable inside the descriptor class:
    def __set__(self,clientinstance,spcname):
        print ("** Setting starship name ***")
        clientinstance._spaceshipname = spcname
    # __delete__ method will just destroy the variable inside the
    # descriptor. Need parameters: self and client instance:
    def __delete__(self,clientinstance):
        print ("*** Clearing starship name ***")
        del clientinstance._spaceshipname

# Now, let's define a class that will use the spaceshipname as a descriptor:

class spaceship(object):
    def __init__(self,myspaceshipname):
        # Boing !!!. Here, we assign the variable
        # to the class descriptor. Note that the name
        # of the attribute, in this case, _spaceshipname
        # is the same defined inside the descriptor:
        self._spaceshipname = myspaceshipname
    # Class descriptor assignment !!
    # Here is where the descriptor do its job.
    # The call assign the "myspaceshipname" attribute
    # to the SpaceshipName descriptor
    myspaceshipname = SpaceshipName()
    # So, everytime a class object is instantiated, the descriptor
    # class is called !

# Ok ok... let's create a "flotilla and kill the Death Star"... jejeje:

xwing = spaceship("X-Wing")
ywing = spaceship("Y-Wing")
bwing = spaceship("B-Wing")

# With our 3 spachips... eeh.... object instances, we can play a little with set/get:

# This call "get" inside the xwing object, or more specifically, inside the descriptor:

# This will print X-Wing, by calling __get__ inside the descriptor:
print (xwing.myspaceshipname)
print ("")

# This will set the ywing name to "Y-Wing Heavy Bomber" by calling __set__ inside the descriptor:

ywing.myspaceshipname = "Y-Wing Heavy Bomber"
print ("")

# And call get again:
print (ywing.myspaceshipname)
print ("")

# And, let's call the __delete__ by deleting the name for the bwing:

del (bwing.myspaceshipname)
print ("")

# We can set it again. This will call the __set__ inside the descriptor class:

bwing.myspaceshipname = "B-Wing Space Superiority Fighter"
print ("")
print (bwing.myspaceshipname)
print ("")

print ("")
#END
