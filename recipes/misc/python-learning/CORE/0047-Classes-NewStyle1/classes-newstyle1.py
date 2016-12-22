#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# Classes new style - part 1
#
#

print ("")

# The new styles for classes (that's is a default on 3.x), need
# to be defined in 2.x with the "object" superclass. See this:

class mynewstyleclass1(object):
    def __init__(self,mystring1):
        self.mystring1 = mystring1

    def __str__(self):
        return "My string is: " + self.mystring1

# Let's call an instance:

print (mynewstyleclass1("Kiki is a CAT"))

print ("")

# One of the new things you can do with newstyle classes is the use
# os "slots", which allow you to declare attributes that will be used by
# the class, but, does not allow other attributes to be dynamically
# created:

class mynewstyleclass2(object):
    # This class can only have the following attributes:
    __slots__ = [ "string1", "num1", "list1" ]
    # Let's init our class:
    def __init__(self):
        # Because there is no code, we must use "pass" here:
        pass
        # Note that, because you already forced the list of possible
        # attributes by using __slots__, there's no way to define
        # other self.X variables. The following statement will incur
        # in a programming error:
        # self.myvariable = "Hello World"
        # But, instead, you can use any variable defined in the __slots__
        # attribute list. Example:
        # self.mystring1 = "Hello World"

    def __str__(self):
        return "My string is: " + self.string1 + ", my number is: " + str(self.num1) + ", and my list is: " + str(self.list1)


# Now, we can create the object:

myobject1 = mynewstyleclass2()

# And set the attributes: WARNING HERE !. We cannot reference the attributes if they are not defined first.
# If you try to do something like "print myobject1.string1" without having defined the attribute first,
# you will get a programming error !!!

myobject1.string1 = "Kiki is a CAT"
myobject1.num1 = 3.5
myobject1.list1 = [ 1, 2, 3, 4, 5]

# Now, with all 3 objects referenced, we can use them:

print (myobject1)
print ("")

# Note that by the use of __slots__, we cannot use dynamic attributes like:
# myobject.variablex = "jajajaj"
# This will end in an exception !!

# myobject1.jaja = "jeje"
# The error you'll see: AttributeError: 'mynewstyleclass2' object has no attribute 'jaja'

# Note that you can, if you want, allow extra attributes to be dynamycally created when
# using the __slots__ thing, if you include in your list a __dict__. See this example:

class mynewstyleclass3(object):
    __slots__ = [ "string1", "number1", "list1", "__dict__" ]
    def __init__(self,string="Hello World",number=10,thelist=[1,2,3,4,5]):
        self.string1 = string
        self.number1 = number
        self.list1 = thelist
        # And, this is not included on __slots__, but thanks to __dict__,
        # will be allowed:
        self.mybool = True

    def __str__(self):
        return "My string is: " + self.string1 + ", my number is: " + str(self.number1) + " the list is: " + str(self.list1) + " and extras: " + str(self.__dict__)

# Let's instantiate an object:

myobject2 = mynewstyleclass3("Hola Kiki!!",2.3,[1,4,8,16,32])
print (myobject2)

# And, let's add an attribute:

myobject2.mybool2 = False
# Then, print it again:
print (myobject2)

print ("")

# You can see how the presence of __dict__ change things and allow them
# to be more dynamic !

# See how you can obtain all the attribute list, both the ones on __slots__
# and the dynamic from __dict__:

for myattr in list(myobject2.__dict__) + myobject2.__slots__:
    print (myattr," => ", getattr(myobject2,myattr))
    

print ("")

# END
