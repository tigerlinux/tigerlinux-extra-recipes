#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# More newclass style topics. This time, with
# staticmethods and decorators
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
    # Note the absence of the "self" here, and, the use of the
    # @staticmethod decorator, which ensures this method is
    # static:
    @staticmethod
    def HowMannyOfUsAreThere():
        print ("We are in total: " + str(mymethods.numberofmymethodsclasses) + " Instances !!")

    # Because we called @staticmethod before, the following line
    # is no longer needed
    # HowMannyOfUsAreThere = staticmethod(HowMannyOfUsAreThere)

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

# Now, let's define a class which will use the __call__ overloading operator and
# a decorator (this example is based on a book):

# First, define a class, new style:
class functiontracer(object):
    # The constructor just allows the argument "function"
    def __init__(self,function):
        # init the global mycalls variable, and the name of the function
        self.mycalls = 0
        self.function = function

    # This is the overload operator __call__. First, the overload changes
    # the class initialization so we can use a variable list of arguments
    def __call__(self, *arguments):
        # When the overload is called, we add "1" to the mycalls global
        # attribute
        self.mycalls += 1
        # print the number of the call to the function, and the name of
        # the function
        print ("Call %s to %s" % (self.mycalls, self.function.__name__))
        # then, call the function with the arguments. Note the function is
        # not defined yet, not into the class
        self.function(*arguments)

# Now, the tricky tric !!.
# the name of the class as a decorator, we are defining the function name here
# and the function code, and relating the function to the original class.
# When the function is called, the code of the function is executed along the
# code in the class which uses the "__call__" overload method

# The @functiontracer is the same in this case as calling:
# myfunctionfromaclass=functiontracer(myfunctionfromaclass)

@functiontracer
def myfunctionfromaclass(value1, value2, value3, value4):
    print ("My values are: ", value1, value2, value3, value4)

# And now the magic:

myfunctionfromaclass(1,5,6,30.2)
print ("")
myfunctionfromaclass("Kiki", "Rayita", "Negrito", "Kisa")
print ("")

# Se more here:

@functiontracer
def myotherfunctionfromclass(valuex1,valuex2):
    print ("Here again: My values are: ", valuex1, valuex2)

# And

myotherfunctionfromclass([2,4,6,8,10],"Hello Guys and Gals")
print ("")
myotherfunctionfromclass("The World is Twisted","But everything is O.K.")
print ("")

print ("")

# END

