#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 16, 2016
# TigerLinux AT Gmail DOT Com
# Bound Methods
#
#

print ("")

# Let's define a simple class:

class myclass:
    def __init__(self,string):
        self.__string = string
    def __printstring(self,message):
        print (str(message) + " " + str(self.__string))

# Now, let's call an instance of the class:

myobject1 = myclass("Kiki")

# And the call the method:

myobject1._myclass__printstring("Hello")

# Now, see this:

myobject2 = myclass("Rayita")
myobject3 = myobject2._myclass__printstring

# Andddddddd.....:

myobject3("Helloooo")

# myobject3 was set directly to the method in myobject2. This is a direct
# application of a "bound method" as myobject3 instance is directly associated
# with the method on myobject2, and also uses the variables already instantiated
# when object2 was created. The result of this method is:
# Helloooo Rayita

print ("")

# END
