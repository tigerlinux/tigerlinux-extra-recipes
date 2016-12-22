#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# More about decorators - still basic
#
#

print ("")

# Decorators can be used for classes too. Let's define a function here:

# This function takes a generic name "classname", which later is expected
# to be a class, then, augment the class with the variable defined here,
# which for our example, a counter of classes

mycounter = 0
def myclasscounter(classname):
    # we add "1" to the global variable with each call to myclasscounter
    global mycounter
    mycounter += 1
    print ("Called here myclasscounter with classname: ",classname)
    print ("We have %s calls to this function !" % mycounter)
    return classname

# Now, let's define a class, but use before the decorator for the function:

@myclasscounter
class myclass(object):
    numberofmymethodsclasses = 0 
    # The constructor
    def __init__(self):
        # Global variable:
        myclass.numberofmymethodsclasses += 1
        print ("Constructed the instance number %s for myclass" % (myclass.numberofmymethodsclasses))

    # The static
    @staticmethod
    def HowMannyOfUsAreThere():
        print ("We are in total: " + str(myclass.numberofmymethodsclasses) + " Instances of myclass !!")

# And another class

@myclasscounter
class myclass2(object):
    numberofmymethodsclasses2 = 0
    # The constructor
    def __init__(self):
        # Global variable:
        myclass2.numberofmymethodsclasses2 += 1
        print ("Constructed the instance number %s for myclass2" % (myclass2.numberofmymethodsclasses2))
        
    # The static
    @staticmethod
    def HowMannyOfUsAreThere():
        print ("We are in total: " + str(myclass2.numberofmymethodsclasses2) + " Instances of myclass2 !!")


# Let's instantiate. You'll see the "myclasscounter" function called:
# Also, you'll see the "Constructed" message

myobject1 = myclass()
myobject2 = myclass()

myobject3 = myclass2()
myobject4 = myclass2()

myobject5 = myclass()
myobject6 = myclass()

# See the counter of each class:

print ("")

myclass.HowMannyOfUsAreThere()
myclass2.HowMannyOfUsAreThere()

print ("")

# And, see this:

print ("How many times the function was called: ", mycounter)

print ("")

#END
