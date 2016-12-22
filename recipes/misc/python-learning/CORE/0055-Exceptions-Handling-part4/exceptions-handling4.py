#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 20, 2016
# TigerLinux AT Gmail DOT Com
# More topics about exception handling
# Usage of with/as context managers
#
#

print ("")

# Remember excercise 13 about files ?. We always need to ensure the
# file is properlly closed !. Well, this time, with the usage of the
# with/as form, the context manager, the file get's closed as soon
# as the statement is finished.

# Let's define a file name and import our "os" library. We'll do the same
# we did in excercise 13, but using "with/as" context management:

import os

# Let's define a filename:

myfilename = "data.txt"
myfilenamerenamed = "data2.txt"

# And, open the file:

with open(myfilename, "w") as myfile:
    myfile.write("Kiki\n")
    myfile.write("Rayita\n")
    myfile.write("Negrito\n")

# As soon as the code block in the with/as statement ends, the context
# manager closes the file, so no "close" operation is needed here.

print ("")

# Let's continue playing:

with open(myfilename, "r") as myfile:
    print (myfile.read())

# And play even more:

with open(myfilename, "a") as myfile:
    myfile.write("Kiki Ratonila\n")
    myfile.write("Rayoncita de Rayon\n")
    myfile.write("Negrurismo de Renegro\n")

# Every time we use the with/as combo, the file it's closed when the code
# block is finished

# Clean up here:

os.remove(myfilename)

# Other use cases for with/as include the decimal context:

# Let's import the decimal module first:

import decimal

# And, use with/as in order to define a local precision context:

with decimal.localcontext() as mylocalcontext:
    mylocalcontext.prec = 4
    mydivision = decimal.Decimal("23.45") / decimal.Decimal("2.56")
    print ("My result with precision = 4 is ", mydivision)

print ("")

# Context managers can be used with custom classes... For that, you
# should include a "__enter__" and "__exit__" methods in your class.
# Those methods are called when the class is instantiated in the with/as
# statement(__enter__) and when the code block finish (__exit__). Also,
# when an exception is raised, the __exit__ code block is called too.
# See the following example:

# First, let's define a class which will have 3 methods, one for just
# printing a message, another two for the __enter__ and __exit__ the
# with/as code block requires !.

class mywithasclass:
    # Generic method for just printing something
    def printmessage(self,string):
        print ("This is a generic message: " + string + "\n")
    # The __enter__ method. This will be called at the
    # entry point of with/as statement
    def __enter__(self):
        print ("The \"with/as\" block has started !!\n")
        # If we return a value, this is assigned to the
        # variable after the "as" statement. Because this
        # is actually a class, we just return "self":
        return self
    # OK... let's see the more complex part of this. If
    # the "__exit__" was called as a part of an exception,
    # 3 arguments are passed:
    # __exit__(error_type,error_value,error_traceback).
    # If the "__exit__" was called in the end of the block,
    # those 3 values are None
    def __exit__(self,error_type,error_value,error_traceback):
        if error_type == None:
            print ("Normal \"with/as\" code block termination\n")
        else:
            print ("Ooopssss happened: ", error_type,error_value,error_traceback)
            # Continue execution, propagating the error and causing the program
            # to finish
            return False


# Ok.. with our class ready, let's play with this:

print ("STARTING A WITH/AS BLOCK:\n")

with mywithasclass() as generic:
    # Let's call the print:
    generic.printmessage("The world is twisted but KIKI will save it !!")
    
# And, let's call it again, but this time let's raise an error:

# with mywithasclass() as generic2:
#     generic2.printmessage("I insist !!. KIKI will save the world !!")
#     raise TypeError

# Now, combined with the try/except/finally. In this case, because the
# exception is caught inside the code, we'll don't call the "__exit__"
# due the raise condition, but, we'll call it when the "finally" is
# reached

print ("STARTING A WITH/AS BLOCK:\n")

with mywithasclass() as generic3:
    try:
        generic3.printmessage("You don't really get it do you ??. KIKI is the only thing (cat) what can save the world :-) !!")
        raise TypeError
    except TypeError:
        print ("Whoaaaa... a TypeError happened here\n")
    finally:
        print ("We are done here !\n")

# And, let's call it again, but this time let's raise an error that will call the __exit__ with
# the error variables: __exit__(error_type,error_value,error_traceback):

print ("STARTING A WITH/AS BLOCK:\n")

with mywithasclass() as generic2:
    generic2.printmessage("I insist !!. KIKI will save the world !!")
    raise TypeError("Ohh myyy... another programmer breaking python on purpose ??.. please get a life !!")

print ("")
#END
