#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 21, 2016
# TigerLinux AT Gmail DOT Com
# More about decorators
#
#

print ("")

# Decorators are used to augment what normally a function or class does
# Let's see a sample here:

# First, define a function that we'll use as decorator:
# Note: This is based on a book's sample, with some extra
# modifications:

# This will be our "decorator" class:
# This function get a class as input: myclass
def classaugmentor(myclass):
    # Inside the function, we define a class:
    class attributeadd:
        # This variable will be updated with every call to the augmentor
        shipsinfleet = []
        howmanytimesweuseget = 0
        # The class, at init time, receives a list of arguments:
        def __init__(self,*arguments):
            # Just to trace what the class does, we print the received
            # arguments:
            print ("Arguments received:" + str(arguments))
            # Here, we "wrap" all our arguments, from the original class
            # "myclass".
            self.wrappedattributes = myclass(*arguments)
            # And, the attribute "shipsinfleet" is updated by adding to the list
            # the third argument in the list "arguments". In our calling class,
            # this argument is the "Ship Name"
            self.shipsinfleet.append(str(arguments[2]))
        # When we want to see any argument, we intercept the "__getattr__"
        # in the calling class using the decorator, effectivelly "augmenting"
        # the original calling class.
        def __getattr__(self,attrname):
            # Again, to see the trace, we print a message:
            print ("Returning Attribute " + str(attrname))
            # and return, with the getattr function, the
            # argument value. Also, before returning, we
            # will update the attribute "howmanytimesweuseget"
            # in order to keep a count of the times the decorator
            # __getattr__ is called:
            self.howmanytimesweuseget += 1
            print ("We have used get %s times in the class instance" % (str(self.howmanytimesweuseget)))
            return getattr(self.wrappedattributes, attrname)
    # Then, we return the class object as the result of the classaugmentor function
    return attributeadd

#
# Here, we define a "federationship" class that will use
# classaugmentor as "decorator", augmenting the __getattr__
# function in the "federationship" class with the one
# defined in the "classaugmentor" function
@classaugmentor
class federationship:
    def __init__(self, shipclass, shipcrew, shipname):
        # This attribute, is passed to the decorator and
        # stored in the wrappedattributes attribute structure
        self.planet = "Earth"
        self.shipclass = shipclass
        self.shipcrew = shipcrew
        self.shipname = shipname


# We instantiate the class. In this moment, the attributes
# "Exploration Ship" and "300" are passed as arguments to the
# decorator function, and more specifically, to the "attributeadd"
# class inside the decorator function.
enterprise = federationship("Exploration Ship",300,"Enterprise")

# This attribute, defined inside the calling class, is passed to
# the __getattr__ overload defined in the decorator function

print (enterprise.planet)

# Also,

print (enterprise.shipclass)
print (enterprise.shipcrew)
print (enterprise.shipname)

# And the ships in the fleet, by the moment, only one:
print (enterprise.shipsinfleet)

# Now, let's create another two ships.

vengeance = federationship("Juggernaut Class", 20, "Vengance")
timur = federationship("Surook Class Science and Combat Vessel", 120, "Ti'Mur")

# Set timur ship planet:

timur.planet = "Vulcan"

# And, print:

print (enterprise.shipsinfleet)
print (timur.shipsinfleet)
print (timur.planet)

print (timur.shipname)
print (vengeance.shipcrew)

print ("")

# The attribute "shipsinfleet" is also inherited from the decorator class, and,
# updated by the decorator class initialization code each time a new "federationship"
# object class is instantiated.

# And... do you remember the "howmanytimesweuseget" attribute that counts the time
# we get an attribute ?. See this:

# The "howmanytimesweuseget" attribute is local to the class instance, not global
# to the decorator class.. why this ???. Simple:
# The "shipsinfleet" is updated on every "__init__" of the decorator class with the
# name of the ship (third element in the argument list).
# The "howmanytimesweuseget" is updated on each call to the specific __getattr__ in
# the class instance, so the attribute is local to the class instance.

print (enterprise.howmanytimesweuseget)
print (timur.howmanytimesweuseget)
print (vengeance.howmanytimesweuseget)

# We can see the global get's by:

print ("Get's used by the system for all our class objects:" + str(enterprise.howmanytimesweuseget+timur.howmanytimesweuseget+vengeance.howmanytimesweuseget))

print ("")
# END
