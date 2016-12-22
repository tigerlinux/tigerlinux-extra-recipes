#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12 2016
# TigerLinux AT Gmail DOT Com
# INPUT TEXT FROM CONSOLE - Complex Version
#
#

# This sampe will show how to use a while loop in order to filter
# out some undesired inputs !

import sys

# print ( "Python version is:", sys.version_info )

print ("")

while True:
    # First, we ensure the proper input function for either python 2 or 3.
    if sys.version_info.major == 2:
        mytext = raw_input("Please enter any string and then press ENTER: ")
    elif sys.version_info.major == 3:
        mytext = input("Please enter any string and then press ENTER: ")
    else:
        print ("Unsupported python version")
        mytext = "UNSUPPORTED"
        break
    # If you does not enter any text, we continue the loop. If you do entered
    # a text, we break
    if mytext != "":
        break

print ( "Your entered the following text:" )
print ( mytext )
print ("")

while True:
    # First, we ensure the proper input function for either python 2 or 3.
    if sys.version_info.major == 2:
        mydigit = raw_input("Please enter any number between 1 and 10 and then press ENTER: ")
    elif sys.version_info.major == 3:
        mydigit = input("Please enter any number between 1 and 10 and then press ENTER: ")
    else:
        print ("Unsuported python version")
        mydigit = -1
        break
    # This try/except block is made to ensure an integer is entered. If we enter a string,
    # a float or anything not an integer, the ValueError exception will trigger and we'll
    # set the variable "mydigit2" to -1
    try:
        mydigit2 = int(mydigit)
    except ValueError:
        mydigit2 = -1
    # Here, we check if our "mydigit2" number is between 1 and 10 both inclusive. If not,
    # we print a warning. If true, we break the loop
    if (int(mydigit2) >= 1) and (int(mydigit2) <= 10):
        break
    else:
        print ("WRONG !!!. The number must be between 1 and 10, both inclusive")

print ("")
print ( "You entered the number: " +  str(mydigit) )
print ("")

# END
