#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# More newclass style topics. This time, with
# staticmethods and classmethods
#
#

print ("")

# Let's define a class, new style:

class mymethods(object):
    # This variable will be used for our class in order
    # to keep a counter of all classes of this kind that
    # are instantiated.
    numberofmymethodsclasses=0
    # Our constructor:
    def __init__(self):
        # Every time a class object is instantiated, the
        # variable is added a "1", effectivelly counting
        # the number of instances for this class
        mymethods.numberofmymethodsclasses += 1

    
    # And, let's define a function which prints the class
    # global variable:
    # Note the absence of the "self" here:
    def HowMannyOfUsAreThere():
        print ("We are in total: " + str(mymethods.numberofmymethodsclasses) + " Instances !!")

    # Now, the trick. We'll use "staticmethod" to ensure the method for
    # printing the number of instances if local to the class, and not
    # changeable by the object:

    HowMannyOfUsAreThere = staticmethod(HowMannyOfUsAreThere)

    # Let's also update the variable when we die, by overloading the
    # "del" operator:

    def __del__(self):
        mymethods.numberofmymethodsclasses -= 1

# Ok play time. Let's define 3 objects for this class:

obj1 = mymethods()
obj2 = mymethods()
obj3 = mymethods()

# Now, let's print the variable by using the static method in more than one way:

mymethods.HowMannyOfUsAreThere()
obj1.HowMannyOfUsAreThere()
obj3.HowMannyOfUsAreThere()

# Now, let's kill one of our objects:

obj2 = ""

# And call the method again:

mymethods.HowMannyOfUsAreThere()

# Kill the other two:

obj1 = ""
obj3 = ""

# Call again:

mymethods.HowMannyOfUsAreThere()

# Let's do more here. This list comprehension will generate a list of
# 20 items:

mylist = [ number for number in range(20) ]

# Now, with the following loop we'll assign to each list item
# an individual object:

counter=0
for item in mylist:
    mylist[counter] = mymethods()
    counter += 1

# Print how many we are... in many ways:

mymethods.HowMannyOfUsAreThere()
mylist[3].HowMannyOfUsAreThere()
mylist[19].HowMannyOfUsAreThere()
mylist[0].HowMannyOfUsAreThere()

# And now, just by redefining our list, we'll just kill every instance object
# we just created in the loop !!

mylist = []

mymethods.HowMannyOfUsAreThere()


print ("")

# END

