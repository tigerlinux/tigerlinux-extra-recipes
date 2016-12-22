#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 22, 2016
# TigerLinux AT Gmail DOT Com
# Metaclasses part 1.
#
#

# Note: We'll force python 2.6-2.7 here, as metaclasses declarations between
# series 3 and 2.6/2.7 are different.

import sys

if sys.version_info.major == 2 and sys.version_info.minor >= 6:
    pass
else:
    print ("Unsupported python version. This script must run be run on python 2")
    sys.exit(1)

print ("")

# Ok.. First, metaclasses are similar to decorator as both can augment classes, but,
# metaclasses go a little further, by extending the way decorators insert or override
# code in classes. Metaclasses also allow the programmer to intercept/augment the code
# at class-creation time.

# To see this in a more practical way, let's define a class here. First note that our
# metaclass has a __new__ method. We'll explain later what is this for !.

# Or class must be declared from "type":

print ("Creating Metaclass \"metaclass1\". You'll see nothing here... yet !")

class metaclass1(type):
    def __new__(metaname, classname, supers, classdictionary):
        print ("Metaclass call to __new__. Data: ")
        print ("\tClassname: " + str(classname))
        print ("\tSupers: " + str(supers))
        print ("\tClass Dictionary: " + str(classdictionary))
        print ("\n")
        return type.__new__(metaname, classname, supers, classdictionary)

print ("")

# Ok, now let's define a class that will use "metaclass1" as metaclass:

# Just in the moment we define this class, we'll se the print's from the "__new__"
# declared on the metaclass "metaclass1":

print ("Creating myclass with __metaclass__ = metaclass1. You'll see some messages here")
print ("")

class myclass(object):
    __metaclass__ = metaclass1
    myclassvar = "Hello Cats!"
    def __init__(self):
        print ("Calling INIT in class \"myclass\"")
        print ("Object name: " + str(self.__class__.__name__) +"\n")
    def myfunctioninclass(self,anotherstring):
        print (self.myclassvar+anotherstring)

# Ok... now, let's create an instance of myclass:

print ("Creating an instance... again, no messages. Only some prints from the instance itself and the INIT from the class \"myclass\"")

print ("")

myinstance = myclass()

# And print some data and use some functions:

print (myinstance.myclassvar)

myinstance.myfunctioninclass(" ... and more Cats!!")

print ("")

# What happened here ?. Basically the metaclass called the __new__  at class creation time (not instance
# creation time). As you can see in the flow of messages, as soon as we create the class and give the
# __metaclass__ at the beginning of the class creation, the __new__ on the metaclass is called.

# Also, we can define a custom __init__ in the metaclass: Let's define another metaclass here:

print ("Creating Metaclass \"metaclass2\". You'll see nothing here... yet !")

class metaclass2(type):
    def __new__(metaname, classname, supers, classdictionary):
        print ("Metaclass call to __new__. Data: ")
        print ("\tClassname: " + str(classname))
        print ("\tSupers: " + str(supers))
        print ("\tClass Dictionary: " + str(classdictionary))
        print ("\n")
        return type.__new__(metaname, classname, supers, classdictionary)
    def __init__(aclass, classname, supers, classdictionary):
        # This attribute will be passed to any class which uses this class as metaclass:
        aclass.myvarininit = "The World is TWISTED but KIKI will... save it ???"
        # Printing some data:
        print ("Metaclass call to __init__. Data: ")
        print ("\tClassname: " + str(classname))
        print ("\tSupers: " + str(supers))
        print ("\tClass Dictionary: " + str(classdictionary))
        print ("Class Object name: " + str(aclass.__class__.__name__))
        print ("Class object initialization. Class data: " + str(list(aclass.__dict__.keys())))
        print ("\n")

print ("")

# And again, create a class "myclass2" using metaclass2 as metaclass:

print ("Creating myclass2 with __metaclass__ = metaclass2. You'll see some messages here from __new__ and __init__")
print ("")


class myclass2(object):
    # The __metaclass__ statement indicates the class that will use metaclass2 as metaclass:
    __metaclass__ = metaclass2
    myclassvar = "Hello Cats at myclass2!!"
    def __init__(self):
        print ("Calling INIT in class \"myclass2\"")
        print ("Object name: " + str(self.__class__.__name__) +"\n")
    def myfunctioninclass(self,anotherstring):
        print (self.myclassvar+anotherstring)
    # The following function uses the attribute "myvarinit", which was declared in the
    # __init__ section of the metaclass
    def myfunction2inclass(self):
        print ("Our string inherited from metaclass2 is: " + self.myvarininit)

# Ok... now, let's create an instance of myclass2:

print ("Creating an instance... again, no messages. Only some prints from the instance itself and the INIT from the class \"myclass2\"")

print ("")

myinstance2 = myclass2()

# And print some data and use some functions:

print (myinstance2.myclassvar)

myinstance2.myfunctioninclass(" ... or maybe not!!")
# Also, remember this statement in the metaclass ??:
# aclass.myvarininit = "The World is TWISTED but KIKI will... save it ???"
# See how the instance inherited the "myvarinit" attribute:
print (myinstance2.myvarininit)
# And in the function too:
myinstance2.myfunction2inclass()



print ("")
# END
