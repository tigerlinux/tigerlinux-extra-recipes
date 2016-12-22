#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 20, 2016
# TigerLinux AT Gmail DOT Com
# More about exceptions handling
#
#

print ("")

# We'll explore the "assert" statement. This statement is more used for debug
# conditions or trapping program/function/classes constrains. See the following
# function:

def myassertion(inputlist):
    for number in inputlist:
        print ("The actual number is: ",number)
        # Here, while the test is true, there is no assertion
        # If the test "number => 0" becomes False, the assertion
        # get's triggered !
        assert number >= 0, "ALERT: The number must be possitive, and %s is not positive" % number
        # Note again: The TEST MUST BE EVALUATED TO FALSE in order
        # to generate the assertion !!


mylist1 = [ 1,2,3,4,5,6,7,8 ]
mylist2 = [ 5,4,3,1,0,-1,-2 ]


# This list does not generate the assertion
myassertion(mylist1)
print ("")
# But, this does and our program will die with the assertion error text:
myassertion(mylist2)
print ("")

#END
