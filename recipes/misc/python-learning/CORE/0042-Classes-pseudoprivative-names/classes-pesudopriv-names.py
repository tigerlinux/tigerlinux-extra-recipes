#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 16, 2016
# TigerLinux AT Gmail DOT Com
# Pseudoprivative names
#
#

print ("")

# In python, any variable or method name which is in the form
# __NAME, is converted at compile/run time to _CLASSNAME__NAME
# allowing some kind of unique names and avoiding possible
# colissions in classes tree, specially when a class is called
# by another (superclassing) and both have the same variable
# name or names:

class myclass:
    def __init__(self,value1):
        self.__value1 = value1
    def __mymethod(self,value2):
        return self.__value1 ** value2
    def __str__(self):
        return str(self.__dict__)

# Let's init a class instance:

myobject = myclass(23)

# For this object, the class __value1 variable becomes myobject._myclass__value1

print ("Value: " + str(myobject._myclass__value1) + ", Dictionary: ", myobject)

# And the same apply for the __mymethod method: myobject._myclass__mymethod(value)

myobject._myclass__value1 = 56

print ("The value of " + str(myobject._myclass__value1) + "^3 is: " + str(myobject._myclass__mymethod(3)))

print ("")

# END
