#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 14, 2016
# TigerLinux AT Gmail DOT Com
# Filter and Reduce
#
#

print ( "" )

# Let's define a list using a range and print it:

mylist = range(-10,11)

print ( "My original list is: " + str(mylist) )

# Now, let's define a function that will get a list and filter out every
# and each value lower than 0, then return a new list:

def filterlowerthanzero(inputlist):
    outputlist=[]
    for number in inputlist:
        if number > 0:
            outputlist.append(number)
    return outputlist

# Print the newlist using the function:

print ( "" )

print ( "Our new list is (using looped function): " + str(filterlowerthanzero(mylist)) )

print ( "" )

# Using filter, we can reduce all of this to a simple line:

print ( "Our new list is (using simple filter call with a lambda function): " + str(filter((lambda number: number > 0),mylist)) )

print ( "" )

# Of course, the "filter" way is faster and simpler than the whole looped 
# function "filterlowerthanzero"

# Now, let's see what reduce does:

# Let's define a function which, from a list, return the sum of all items on the list:

def sumallitems(inputlist):
    result = inputlist[0]
    for number in inputlist[1:]:
        result = result + number
    return result

# Then, let's pass out function to a list:

mylist = [ 2, 4, 1, 3 ]

print ( "My sum is (using a sum function with the list: " + str(mylist) + "): " + str(sumallitems(mylist) ))

# NOTE: This will not work in python 3, as "reduce" has been removed in py3:
# Let's do the same, but this time using reduce with a lambda:

print ( "My sum is (using reduce with the list: " + str(mylist) + "): " + str(reduce((lambda val1,val2: val1+val2),mylist)) )

print ( "" )

# Filter, return an iterable, but reduce, return a single value. Reduce takes the value from the list in it's
# second argument and pass it to the function in the first argument (the lambda in this case). With each step,
# reduce accumulates the last value from the lambda function, and pass it to the next step until the list is
# competelly run.

# END
