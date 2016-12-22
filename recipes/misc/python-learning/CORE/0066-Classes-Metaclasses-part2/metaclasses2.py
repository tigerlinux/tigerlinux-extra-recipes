#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 22, 2016
# TigerLinux AT Gmail DOT Com
# Metaclasses 2
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

# Metaclasses can be functions too. See the next function:

globalvar = 0
def mymetaclassfunction(classname, supers, classdictionary):
    global globalvar
    globalvar += 1
    print ("\nCalled by class: " + str(classname))
    print ("This metaclass has been called %s times\n" % (globalvar))
    return type(classname, supers, classdictionary)

# Now, let's define two classes using the same function as metaclass:

class myclass1(object):
    __metaclass__ = mymetaclassfunction
    myclassstr1 = "Welcome to the Jungle !!"
    def __str__(self):
        return self.myclassstr1

class myclass2(object):
    __metaclass__ = mymetaclassfunction
    myclassstr1 = "Welcome to Python !!"
    def __str__(self):
        return self.myclassstr1

# See how the global variable "globalvar" is updated each time the function is called for each
# class that uses the function as metaclass.

# Let's create instances:

instance1 = myclass1()
instance2 = myclass2()

print (instance1)
print (instance2)

print ("")

# In this excercise, the function is added to the __call__ operator in the classes "myclass1"
# and "myclass2". Again, this happens at class creation, not instance creation.

# Call creation in classes can be overloaded too with metaclasses. See the following class, which
# will define a __call__ overload operator. Note that the protocolo is a little bit more complex,
# as we need to first define a metaclass (metaclass2 here) that will be a "Super Class" of another
# class, which will be used as metaclass for the final "client" class:

print ("")
print ("Creating the SuperClass \"metaclass2\"")

# Superclass "metaclass":
class metaclass2(type):
    def __call__(metaname, classname, supers, classdictionary):
        print ("Metaclass call to __call__ in \"metaclass2\" SuperClass. Data: ")
        print ("\tClassname: " + str(classname))
        print ("\tSupers: " + str(supers))
        print ("\tClass Dictionary: " + str(classdictionary))
        print ("\n")
        return type.__call__(metaname, classname, supers, classdictionary)

print ("")
print ("Creating the subclass \"submetaclass1\"")

# Subclass "metaclass" using metclass2 as metaclass:
class submetaclass1(type):
    __metaclass__ = metaclass2
    def __new__(metaname, classname, supers, classdictionary):
        print ("Calling __new__ in \"submetaclass1\" sub-metaclass by class:" + str(classname))
        return type.__new__(metaname, classname, supers, classdictionary)
    def __init__(myclass,classname,supers,classdictionary):
        print ("Calling __init__ in \"submetaclass1\" sub-metaclass by class:" + str(classname))

# WOW... Finally, the class using submetaclass1 as metaclass... crazy..

print ("")
print ("Creating the class \"myclass3\"")

class myclass3(object):
    __metaclass__ = submetaclass1
    myclassstr1 = "Welcome to Python !!"
    def __str__(self):
        return self.myclassstr1

# let's instantiate an Instance

print ("")
print ("Creating a class instances from \"myclass3\" and printing it's value by calling __str__\n")

instance3 = myclass3()

print (instance3)

print ("")

# This excersice show's also that metaclasses can have metaclasses !

# Note also that classes which uses another classes that are using metaclasses, inherit
# the metaclasses override's too. Example here, we'll subclass from "myclass3":

print ("")
print ("Creating the class \"myclass4\" subclassed from \"myclass3\"\n")

class myclass4(myclass3):
    pass

# Then, an instance:

print ("")
print ("Creating an instance from \"myclass4\" and print it's value by calling __str__\n")

instance4 = myclass4()
print (instance4)

# If you followed the print's, you could see how the class "myclass4" definition called the
# init's and call's from the metaclasses !

# VERY VERY VERY IMPORTANT WARNING: Metaclasses does not inherit to it's client class any
# of it's attributes. While is true that metaclasses can (like any other thing) use global
# variables and has it's own defined variable/attribute/functions, they DOES NOT inherit
# those variables/attributes/functions to their client classes. Please be aware of that !!
# SuperClasses can inherit their attributes/functions (as we saw before), but this does not
# happens with metaclasses.

print ("")
# END
