#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 14, 2016
# TigerLinux AT Gmail DOT Com
# Iterators and yield
#
#

print ("")

# IMPORTANT NOTE: THIS EXCERSICE IS FOR PYTHON 2.6/2.7

# When you define a iterating function, and instead of return the value
# with "return", you use "yield", python treats this function as a iterator,
# which also supports specific methods for controlling the iteration. The
# interesting parte is, the function returns the value wich each iteration, 
# but retains its data and memory state until finish.

# Let's define a list:

myvalue = 3

# And a iterating function, which will return the square of the value, but
# instead of using return, we'll use yield:

def iteratinghere(fromvalue):
    for number in range(fromvalue):
        yield number ** 2

# First call to the function using a variable:

myvar = iteratinghere(myvalue)

# See the results here:

print (myvar.next())
print (myvar.next())
print (myvar.next())

print ("")

# Also, we can use the function inside a loop:

for mynumber in iteratinghere(10):
    print ("My value is: " + str(mynumber))


print ("")

# You can clearly see that the state of the function "iteratinghere" is maintained
# over each call of the "next" method (__next__ in python 3).

# Note that generators are more efficient in terms of performance when they need to
# work with large data sets. Also, it provides you a finer control over what a iteration
# can do !

# Note that you can send values to a generator with the "send" method. Let's see this
# example:

def anotheriter(fromvalue):
    for number in range(fromvalue):
        retval = yield number
        # If we used a .send(77), we'll stop, yield "None"
        # and finish the generator with a return !
        if retval == 77:
            print ("Generator Finished by User Request !!")
            yield None
            return

# Initialize the generator:

myvar2 = anotheriter(20)

# The 4 first ".next" calls iterates trough the function:

print (myvar2.next())
print (myvar2.next())
print (myvar2.next())
print (myvar2.next())

# This sends code 77, which in the generator function code means to
# print "Generator Finished by User Request !!", yield "None" and
# finish with a return 

print (myvar2.send(77))

print ("")
# END
