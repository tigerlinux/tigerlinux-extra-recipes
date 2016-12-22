#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 14, 2016
# TigerLinux AT Gmail DOT Com
# Lambda functions
#
#

print ("")

# Lambda's allow you to embed single-line functions without the need of
# a "def". Sample here:

funvar = lambda val1,val2: val1**val2

print (funvar(2,3))

print ("")

# The last example show's a simple lambd usage. Let's see some more
# complex:

def mystring(string):
    myret = lambda str1: str(str1) + " is a string"
    return myret(string)

print (mystring("LOS GATOS"))
myvar = mystring("LOS PERROS")
print (myvar)

print ("")

# Another sample, with a simple test of greater/smaller number:

whosbigger = ( lambda num1,num2: num1 if num1 > num2 else num2 )

print ("Who is bigger ?... 20 or 10: " + str(whosbigger(20,10)))
print ("Who is bigger ?... 1 or 30: " + str(whosbigger(1,30)))
print ("Who is bigger ?... -1 or -20: " + str(whosbigger(-1,-20)))

print ("")

# Now, let's see some combinations with map and lambdas:

# See the following map sample using a function to modify a list:

mylist = [ 1, 2, 3, 4 ]

# Then, define a function that will add 100 to each number passed to it:

def addfunction(number):
    return number + 100

# Now, using a "map", let's modify the original list with the function:

print ("Original list: " + str(mylist))
mylist2=list(map(addfunction,mylist))
print ("New list: " + str(mylist2))

print ("")

# Let's use a lambda instead in order to get rid of the "addfunction" function:

print ("Original list: " + str(mylist))
mylist2=list(map((lambda number: number + 100),mylist))
print ("New list: " + str(mylist2))

# In the last example, we could get rid of the function "addfunction" and instead used a lambda to shorten
# our code.

print ("")

# END
