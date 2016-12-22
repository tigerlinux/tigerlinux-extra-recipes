#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# Exception Handling - Part 1
#
#

print ("")

# Let's play with exception handling.

# First, let's define a simple function which will return the
# object value of a list by index:

def mylistvalue(mylist,myindex):
    return mylist[myindex]

# now, define a list of 4 elements:

list1 = [ 1,2,3,4 ]

print ("My original list: ", list1)
print ("")

# use the function in order to get the value of index = 2:

print (mylistvalue(list1,2))
print ("")

# Ok.. if you call the function with any out-of-index value, you'll
# generate a IndexError exception.

# Now, see the following code:

try:
    # This is obviouslly out of index:
    mylistvalue(list1,8)
except IndexError:
    print ("Heyy yooooo... are you nuts ???")

print ("")

# We can define this inside a function too:

def mylistvalue2(mylist,myindex):
    try:
        return mylist[myindex]
    except IndexError:
        return -1

# See the effect:

print (mylistvalue2(list1,1))
print (mylistvalue2(list1,99))

print ("")
# The second print, returned -1 as expected

# Note that you can continue after a "catched" exception. See this:

def mylistvalue3(mylist,myindex):
    try:
        return mylist[myindex]
    except IndexError:
        print ("Jejej... yo insist on being nuts are you not ??")
    # The return happens outside the try/execpt. If the try/execpt
    # does not trigger a IndexError, then the function returns the
    # expected value, otherwise it prints a message and returns a
    # value the the try/except finish to be evaluated
    return -9999

# Again, see the effect:

print (mylistvalue3(list1,0))
print (mylistvalue3(list1,99))

print ("")

# Note that you can raise exceptios manually with "raise". Let's see this
# function:

def mylistvalue4(mylist,myindex):
    errorcode = -77
    try:
        if mylist[myindex] < 0:
            errorcode = -99
            raise IndexError
        else:
            return mylist[myindex]
    except IndexError:
        print ("Index out of range or negative value obtained")
        return errorcode

# The last function, will raise an error if the value obtained is
# negative, or, if the index is out og range.

# Another list:

list2 = [ 1, -1, 2, -2, 3, -3 ]

# The former list has it's indexes 1,3 and 5 with negative numbers.

# Let's play again:

# This will print the value "1"
print (mylistvalue4(list2,0))

# This will raise an index error, with errorcode = -77
print (mylistvalue4(list2,800))

# and this, will raise a negative-number error, with errorcode = -99
print (mylistvalue4(list2,1))

print ("")
# END
