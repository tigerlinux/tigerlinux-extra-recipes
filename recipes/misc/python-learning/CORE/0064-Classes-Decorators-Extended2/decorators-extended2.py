#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 21, 2016
# TigerLinux AT Gmail DOT Com
# Decotarors extended - part 2
#
#

print ("")

# This time, we'll se a more practical decorator usage. A timer.

# We'll create a timer decorator which will just intercept the __call__
# o a class and time it takes to run:

# First, the decorator timer class (we need the time module first):

import time

class timer:
    # Constructor: We get as input a function
    def __init__(self,function):
        self.function = function
        # The total time for all calls of the function class, not the
        # function class object instance
        self.totaltime = 0
        # We'll print when the decorator init is called. You'll able to
        # see that the __init__ is called WHEN the @decoratorname is actually
        # used !!. We are init'ng a class after all !!
        print ("")
        print ("Decorator __init__ called on object named: " + self.function.__name__ + "\n")

    # When the calling function is started, the decorator uses the
    # "__call__" overload operator, getting all arguments from the
    # function
    def __call__(self,*arguments,**dictarguments):
        print ("Decorator __call__ called on object named: " + self.__class__.__name__)
        # We set our start time:
        starttime = time.clock()
        # Here, we run the function received as "self", mean, the
        # class instance, and run it with their arguments intercepted
        # in the __call__ operator. When the function is done, its
        # result is set to the functionresult attribute
        functionresult = self.function(*arguments,**dictarguments)
        # Here, we calculate total and elapsed time for the specific
        # function call:
        elapsedtime = time.clock() - starttime
        self.totaltime += elapsedtime
        # print the results
        print("Times for function %s: Elapsed time: %.9f, Total function accumulated time:  %.9f \n" % (self.function.__name__, elapsedtime, self.totaltime))
        # and finally, return the function result
        return functionresult
    
# And now, let's call the decorator

print ("Calling the @decorator on function computatesquaresofevens")

@timer
def computatesquaresofevens(maxrange):
    return [ number ** 2 for number in range(maxrange) if number % 2 == 0 ]

print ("Calling the @decorator on function mapofsquares")

@timer
def mapofsquares(maxrange):
    return map((lambda number: number ** 2),range(maxrange))

# If you observed the flow of things, the message indicating the __init__ function
# called has been printed

print ("")

# Ok.. let's play with the functions:

print ("Creating two \"computatesquaresofevens\" objects:")
print ("")

mysquares20 = computatesquaresofevens(20)
mysquares30 = computatesquaresofevens(30)

print ("")

print (mysquares20)
print (mysquares30)

print ("")

# And, the total time for all calls to all instances of the function:

print ("Complete time for all calls to the function computatesquaresofevens: %.9f" % (computatesquaresofevens.totaltime))

print ("")

# And for the second function:

mymap1 = mapofsquares(20)
mymap2 = mapofsquares(30)

print ("")

print (mymap1)
print (mymap2)

print ("")

# Total time:

print ("Complete time for all calls to the function mapofsquares: %.9f" % (mapofsquares.totaltime))

# Here is very very very important to see when the __init__ is actually called, and when the __call__
# is also called. As you could see, the __init__ is only called when the decorator is applied to the
# function or class object, instead of the __call__ that is called everytime the instance is called.

print ("")
# END
