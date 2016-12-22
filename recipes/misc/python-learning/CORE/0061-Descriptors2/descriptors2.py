#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 21, 2016
# TigerLinux AT Gmail DOT Com
# Descriptor1
# This is based on excersice 60, but, with multiple
# descriptors this time
#

print ("")

# In this excercise we'll define two descriptors to be used
# inside a class.

# First descriptor here:

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
        print ("*** Setting starship name ***")
        clientinstance._spaceshipname = spcname
    # __delete__ method will just destroy the variable inside the
    # descriptor. Need parameters: self and client instance:
    def __delete__(self,clientinstance):
        print ("*** Clearing starship name ***")
        del clientinstance._spaceshipname

# And, the second descriptor:

class SpaceshipFTLMaxSpeed(object):
    # Again, our __get__, __set__ and __delete__ classes:
    def __get__(self,clientinstance,ownerclass):
        print ("*** Obtaining starship maximun FTL Speed ***")
        # Ehhh... we are not using parsecs as StarWars does.. that's crazy !.
        # parsec is an distance unit no a speed unit... well... wtf !
        # We'll use lightyears per hour.. jejeje
        return clientinstance._lightyearsperhour
    def __set__(self,clientinstance,lyph):
        print ("*** Setting starship maximun FTL Speed ***")
        clientinstance._lightyearsperhour = lyph
    def __delete__(self,clientinstance):
        print ("*** Clearing starship FTL Speed ***")
        del clientinstance._lightyearsperhour

# We have then 2 descriptor classes. That's the main difference between excercise 60 and this one

# Now, let's define a class that will use the SpaceshipName and SpaceshipFTLMaxSpeed  as a descriptors:

class spaceship(object):
    def __init__(self,myspaceshipname,myspaceshipftlspeed):
        # The attributes from our descriptors:
        self._spaceshipname = myspaceshipname
        self._lightyearsperhour = myspaceshipftlspeed
    # And, the assignment to the descriptors:
    myspaceshipname = SpaceshipName()
    myspaceshipftlspeed = SpaceshipFTLMaxSpeed()
    # So, everytime a class object is instantiated, the descriptor
    # class is called !

# Ok ok... let's create a "flotilla and kill the Death Star"... jejeje:

xwing = spaceship("X-Wing",3.4)
ywing = spaceship("Y-Wing",10.2)
bwing = spaceship("B-Wing",20.5)

# With our 3 spachips... eeh.... object instances, we can play a little with set/get:

# This call "get" inside the xwing object, or more specifically, inside the descriptor:

# This will print X-Wing, by calling __get__ inside the descriptors for name and ftp speed:
print ("X-Wing name and speed:")
print (xwing.myspaceshipname)
print (xwing.myspaceshipftlspeed)
print ("")

# This will set the ywing name to "Y-Wing Heavy Bomber" by calling __set__ inside the name
# descriptor and set the speed to 16.3 calling the __set__ inside the FTP speed descriptor

ywing.myspaceshipname = "Y-Wing Heavy Bomber"
ywing.myspaceshipftlspeed = 16.3
print ("")

# And call get again:
print (ywing.myspaceshipname)
print (ywing.myspaceshipftlspeed)
print ("")

# And, let's call the __delete__ by deleting the name for the bwing and speed of the bwing:

del bwing.myspaceshipname,bwing.myspaceshipftlspeed
print ("")

# We can set it again. This will call the __set__ inside the descriptor classes for name and speed:

bwing.myspaceshipname = "B-Wing Space Superiority Fighter"
bwing.myspaceshipftlspeed = 40.23
print ("")
print (bwing.myspaceshipname)
print (bwing.myspaceshipftlspeed)
print ("")

# Remember the following tips here. Every time the main class using the descriptors (spaceship for
# this example) is generated, and the set/get/delete methods are called into the descriptor classes,
# the data received by the descriptors are:
# self: The descriptor class instance (SpaceshipName and SpaceshipFTLMaxSpeed classes)
# clientinstance: The class instance calling the descriptors (spaceship class)
# ownerclass: the instantiated object class (xwing, ywing, bwing)

print ("")
#END
