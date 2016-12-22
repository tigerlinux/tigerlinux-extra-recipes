#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 14, 2016
# TigerLinux AT Gmail DOT Com
# More maps and iterations
#
#

print ("")

# Let's define a string:

mystring1 = "Panopticon"

# And a function that will create a list based on the string. For that,
# we'll use the "ord" builtin function that will return the ASCII code
# for the letters on the string:

def asciilist(string):
    retlist=[]
    for mychar in string:
        retlist.append(ord(mychar))
    return retlist

print ("Original string: " + mystring1 + ", ASCII Codes: " + str(asciilist(mystring1)))

# This can be reduces to a MAP function which will iterate trough the string
# and fill out the list:

print ("Original string: " + mystring1 + ", ASCII Codes - using MAP: " + str(list(map(ord,mystring1))))

# Note: Remember that MAP first argument is a function, so, you can use a lambda or a defined function

# Also, we can do the same using a comprehension:

print ("Original string: " + mystring1 + ", ASCII Codes - using a comprehension: " + str([ord(char) for char in mystring1]))

print ("")

# Another sample: Let's define a list using range. This list will include any number from 1 to 10:

mylist = range(1,11)

print ("My list is: " + str(mylist))

# Now, let's see the many ways to skin a cat we hace in python. Let's create 3 new lists that will
# include only the even numbers, using different methods:

# Method 1: A function:

def myevens(fromlist):
    outlist = []
    for number in fromlist:
        if number % 2 == 0:
            outlist.append(number)
    return outlist

mylistmethod1 = myevens(mylist)

# Method 2: A comprehension:

mylistmethod2 = [ number for number in mylist if number % 2 == 0 ]

# Method 3: A filter:

mylistmethod3 = list(filter((lambda number: number % 2 == 0),mylist))

# Let's print the results:

print ("Using a function: " + str(mylistmethod1))
print ("Using a comprehension list: " + str(mylistmethod2))
print ("Using a filter with a lambda: " + str(mylistmethod3))

print ("")

# The results are the same using all 3 methos. Of course, the comprehension and the filter
# are the most efficients and short

# You can use nesting in comprehensions:

newnestedlist = [ str1+str2 for str1 in ["red","blue","black"] for str2 in [ "-one", "-two", "-three" ]  ]

print ("My nested list: " + str(newnestedlist))

# jejeje... the case above somehow reminds me star war's x-wing/y-wing fighters !

print ("")

# END
