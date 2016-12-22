#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 20, 2016
# TigerLinux AT Gmail DOT Com
# More exception handling. This time, with exception classes
#
#

print ("")

# Normally, complex (and not-so-complex) programs tends to use
# it's own exception class, subclassed from the "Exception" class
# Let's see a simple example of this:

# Define a class for handling our wrongdoings !!:

# For the moment, we'll just inherit everything without
# adding or overloading anything:
class myhandler(Exception):
    pass

# Now, let's do some playtesting:

try:
    # Let's force an exception with a raise statement:
    raise myhandler("Wooaaa... I broke something here")
# And, declare a "except" with the class as a name, then,
# call the "name" in a print statement. The name, here "error",
# is a class instance of "myhandler", which inherits all from
# "Exception" superclass:
except myhandler as error:
    print (error)

print ("")

# Now let's begin to redefine things. Let's subclass another
# class from Exception, but, this time we'll re-do the __str__
# printing method:

class myhandler2(Exception):
    def __str__(self):
        # Heyy... use return, not print !. BEWARE !!
        return ("The world is terrible wrong, specially when programmers do bad things !!")

# And use this:

try:
    # Again, let's raise the exception, but whithout any argument
    raise myhandler2()
# Define and call the class:
except myhandler2 as anothererror:
    print (anothererror)

print ("")

# You can use your own variables for the error handler initialization. See
# the following class:

class myhandler3(Exception):
    # This time, the class will define an error code and a error message
    def __init__(self,errornumber,errormessage):
        self.errornumber = errornumber
        self.errormessage = errormessage

# And, now let's use it:

try:
    # This will call our handler, and set's the self.errornumber and self.errormessage variables
    # inside the class
    raise myhandler3(-44,"KIKI going crazy error.. jail KIKI inside a cage and wait 'till she's normal")
except myhandler3 as moreerrors:
    print ("Error CODE: ", moreerrors.errornumber)
    print ("Error TEXT: ", moreerrors.errormessage)

print ("")

# To finish this part of the handling error excersices, we'll include a method that will
# log all errors to a file

class myhandler4(Exception):
    # We proceed to define a class global variable for the log filename
    logfile = "mylogfile.log"
    # Then, call the __init__ with the error code and error message
    def __init__(self,errornumber,errormessage):
        self.errornumber = errornumber
        self.errormessage = errormessage
    # And, we proceed to define a method for writing the error to the log file:
    def logtofile(self):
        with open(self.logfile, "a") as myfile:
            myfile.write("Error caught. Code: " + str(self.errornumber) + ", String: " + self.errormessage + "\n")

# And play:

try:
    # Again, let's call the handler with a raise:
    raise myhandler4(-99,"Opppsss... something very wrong happened here")
except myhandler4 as myerror:
    myerror.logtofile()
    print ("Error logged to file !!")

print ("")
# END
