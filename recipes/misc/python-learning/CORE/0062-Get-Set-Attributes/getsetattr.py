#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 21, 2016
# TigerLinux AT Gmail DOT Com
# __getattr__ and __setattr__ in classes
#
#

print ("")

# the __getattr__ and __setattr__ are overloading methods used
# in classes for attributes not defined into the class

# Let's define a class using those methods:

class myattrdemo:
    # __getattr__
    # self is the class object.
    # name is the name of the non-existent attribute we are trying to get
    def __getattr__(self,name):
        print ("You are trying to get the unexistent attribute name: " + str(name))
    # __setattr___
    # self is the class object.
    # name is the name of the non-existent attribute we are trying to set
    # value is the value of the attribute we want to set:
    def __setattr__(self,name,value):
        print ("Setting attribute %s to value %s" % (name,str(value)))

# And, let's play:

kiki = myattrdemo()

# This will print the warning from the __getattr__ in the class
print (kiki.catname)

# Now, setting the attribute we'll see the __setattr__ message:

kiki.catname = "Kiki Ratonila"

# But, if you try to see thr attributes (calling the dictionary):

print (kiki.__dict__)

# Nothing. As a matter of facts, the attributes are not really set. We just intercepted
# the call to create/get non existent attributes, but, we actually did not created in the
# class

print ("")

# For this to be practical, we need to enter the concept of "managed attributes":

# Now, see this class:

class MyCat:
    def __init__(self,catname,catrace,catcolor):
        # We'll define 3 attributes in the constructor:
        self._catname = catname
        self._catrace = catrace
        self._catcolor = catcolor

    # And call the __getattr__/__setattr__:
    def __getattr__(self,attrname):
        # If our attribute is any of the valid names, we
        # return it and print a message. Otherwise, we
        # raise an exception !!
        if attrname == "catname":
            print ("Returning Cat Name")
            return self._catname
        elif attrname == "catrace":
            print ("Returning Cat Race")
            return self._catrace
        elif attrname == "catcolor":
            print ("Returning Cat Color")
            return self._catcolor
        else:
            raise AttributeError(attrname)
    def __setattr__(self,attrname,attrvalue):
        if attrname == "catname":
            attrname = "_catname"
        elif attrname == "catcolor":
            attrname = "_catcolor"
        elif attrname == "catrace":
            attrname = "_catrace"
        else:
            print ("")
        print ("Setting attribute " + str(attrname) + " to: " + str(attrvalue))
        self.__dict__[attrname] = attrvalue
    # And, __delattr__
    def __delattr__(self,attrname):
        if attrname == "catname":
            attrname = "_catname"
        elif attrname == "catcolor":
            attrname = "_catcolor"
        elif attrname == "catrace":
            attrname = "_catrace"
        else:
            print ("")
        del self.__dict__[attrname]
            
# Ok.. Let's call a class object:

rayita = MyCat("Rayita","Callejera Criolla","Base creamy white with grey-listed patches")

# See the complete dictionary:
print (rayita.__dict__)
# Name:
print (rayita.catname)
# Race:
print (rayita.catrace)
# Color:
print (rayita.catcolor)

# Let's change an attribute and print it again:

rayita.catname = "Rayita de Rayon"
print (rayita.catname)

# Now, set a "non-existent" attribute:

rayita.mouseface = False

# And print it:

print (rayita.mouseface)

# The dictionary:

print (rayita.__dict__)

# Ahh worked. Attributed "catname", "catrace" and "catcolor" are managed, as they have code
# associated to them inside __getattr__, __setattr__ and __delattr__ overload operators. Other
# attributes are permited to exist, as long as they are defined first.
# If you try to do something like:
# print rayita.nonexistent
# The exception in the __getattr__ will trigger !
# Instead if you do:
# rayita.nonexistent = "Hello"
# you can do without error:
# print rayita.nonexistent
#
# Note that we force the attributes by either using __slots__ or, by chaning the __setattr__ to
# call a "raise AttributeError(attrname)" in the "else" part, as __getattr__ does !.

# In more practical and advanced terms, you can use __getattr__/__setattr__ to include computation
# and/or validation code for your attributes too.

print ("")
# END
