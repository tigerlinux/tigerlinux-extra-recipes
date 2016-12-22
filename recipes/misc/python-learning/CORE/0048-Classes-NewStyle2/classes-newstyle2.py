#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# More examples with new style classes
#
#

print ("")

# The next example show's the use of the "property" method to
# intercept get/set/del/docs assignments for attributes.

class mynewstyleclass(object):
    # Slots:
    __slots__ = [ "string1", "string2", "string4" ]
    # Constructor:
    def __init__(self):
        pass

    # Now, let's define some methods, called mysetstr3, mygetstr3 and mydelstr3:

    def mysetstr3(self,string):
        self.string4 = string
        print ("The new value for string4 is: " + self.string4)

    def mygetstr3(self):
        # The GET functions return a fixed value:
        return "I'm a DEFAULT !!"

    def mydelstr3(self):
        print ("The old value for string4 was: " + self.string4)
        self.string4 = ""
        print ("The new value for string 4 is now: " + self.string4)

    # And, by using "property" on the attribute, we override the normal functions
    # for get, set and del:

    string3 = property(mygetstr3,mysetstr3,mydelstr3,None)
        
    
# Let's play. First, instantiate an object:

myobject1 = mynewstyleclass()

# And, let's init all attributes, but string4:

myobject1.string1 = "Hello"
myobject1.string2 = "Crazy"

# This on will call the "mysetstr2" method, and
# set string 4 to World instead to string3
myobject1.string3 = "World"

# Now, let's try to get a value for string3:

print ("String 3 is: " + myobject1.string3)

# And, try to erase the old value for string 3. This calls mydelstr3:

del myobject1.string3

# This show's how we can override normal function properties for any attribute
# inside a class

print ("")

# END
