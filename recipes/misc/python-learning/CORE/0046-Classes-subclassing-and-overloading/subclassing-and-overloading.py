#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# Some list manipulation sample, with overloading, but
# subclassing from the "list" class.
# This is based on the example in a book, with some extra
# little things
#

print ("")

# Firts, let's define a class, called "MyTigerList", which inherits from
# superclass "list"... a python builtin class:

class MyTigerList(list):
    # The class constructor
    def __init__(self,inputlist=[]):
        # Initialize the superclass:
        list.__init__([])
        # And, concatenate to it the inputlist using the concatenante
        # method, defined later in the class
        self.concatenatelist(inputlist)

    # The concatenante function:
    # Add items "not already existen" in the original
    # self.mylist list from the inputlist
    def concatenatelist(self,inputlist):
        # Run the loop trough all the inputlist:
        for item in inputlist:
            # And, if the item is not in the master class
            # variable "self", then append the value
            # "item" to self. Mean, no duplicates
            # Note that "self" if the main object itself, due the
            # fact that we are subclassing from "list" class:
            if not item in self:
                self.append(item)

    # The unionlists function:
    def unionlists(self,otherlist):
        # We define a "returnlist" that is a class
        # instance of our main class with the "self" main
        # variable. Then, we just use our concatenatelist
        # method with the otherlist and return the "returnlist"
        # object:
        returnlist = MyTigerList(self)
        returnlist.concatenatelist(otherlist)
        return returnlist

    # The intersectlists function:
    def intersectlists(self,otherlist):
        # Init a blank list:
        returnlist=[]
        # Then, run a loop trough the class main var "self"
        # and if the item is also on the otherlist, then append it
        # to our blank "returnlist":
        for item in self:
            if item in otherlist:
                returnlist.append(item)
        # Then, return the class initialized with the returnlist:
        return MyTigerList(returnlist)

    # Now, let's assign overload operators to some of our functions:

    # This is an "and" operation between our list and other list
    def __and__(self,otherlist):
        return self.intersectlists(otherlist)

    # This is an "or" operation between our list and other list
    def __or__(self,otherlist):
        return self.unionlists(otherlist)

    # Let's print our list
    def __str__(self):
        return "My list contents: " + list.__repr__(self)

    # The difference bewteen this sample and the exercise 45, is that
    # due the fact we are subclassing from the "list" class, some of
    # our previouslly defined builtin overload operators are no longer
    # needed, as they are part of the "list" superclass


# Now, let's do some playtest

# Define 3 lists:

list1 = [ 1,2,3,4,5,6 ]
list2 = [ 1,2,3,7,8,9,10,11,12 ]
list3 = [ 1,3,5,9,11 ]

# First, print our lists:

print ("Our lists are:", list1, list2, list3)

# Instantiate a new object:

mylistobject1 = MyTigerList(list1)

# And print it:

print (mylistobject1)

print ("")

# Now, let's do an "and" operation and print the new object:
# This show the "__and__" overload in action:

mylistobject2 = mylistobject1 & MyTigerList(list2)

print ("The \"and\" (intersection, no duplicates) operation between objects:", mylistobject1, MyTigerList(list2), " is: ")
print (mylistobject2)

print ("")

# Now, let's to an "or" operation and print the new object:
# This show the "__or__" overload in action:

mylistobject3 = mylistobject1 | MyTigerList(list2)

print ("The \"or\" (union) operation between objects:", mylistobject1, MyTigerList(list2), "is: ")
print (mylistobject3)
print ("")

# Let's create another opbject:

mylistobject4 = MyTigerList(list3)

# And print it, showing the __str__ overload in action

print (mylistobject4)

# Now, let's get the list, and change all it's members for squared versions or the
# former values.
# This shows the original __getattr__ and __setattr__ inherited from "list" superclass:

index = 0
for value in mylistobject4:
    print ("Original Value: ", mylistobject4[index])
    mylistobject4[index] = value ** 2
    print ("New value is: ", mylistobject4[index])
    index += 1

print ("Now my list object is: ")
print (mylistobject4)

# And finally, to see the __len__ in action, inherited from original "list" superclass:

print ("My object lenght is: ", len(mylistobject4))

print ("")

# END
