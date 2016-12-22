#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# Some list manipulation sample, with overloading
# This is based on the example in a book
#

print ("")

# Firts, let's define a class, called "listmanipulation":

class listmanipulation:
    # The class constructor
    def __init__(self,inputlist=[]):
        # First, we define our main variable, which is an empty list:
        self.mylist = []
        # And, concatenate to it the inputlist using the concatenante
        # method, defined later in the class
        self.concatenatelist(inputlist)

    # The concatenante function:
    # Add non-existent items in the original list
    # self.mylist list from the inputlist
    def concatenatelist(self,inputlist):
        # Run the loop trough all the inputlist:
        for item in inputlist:
            # And, if the item is not in the master class
            # attribute "self.mylist", then append the value
            # "item" to self.mylist. Mean, no duplicates
            if not item in self.mylist:
                self.mylist.append(item)

    # The unionlists function:
    def unionlists(self,otherlist):
        # fist, make a copy or the master class list
        returnlist=self.mylist[:]
        # Run a loop trough the otherlist, and for each item
        # not in the returnlist (the copy of the master list),
        # we append the item to the returnlist:
        for item in otherlist:
            if not item in returnlist:
                returnlist.append(item)
        # Then, return the class initialized with the returnlist:
        return listmanipulation(returnlist)

    # The intersectlists function:
    def intersectlists(self,otherlist):
        # Init a blank list:
        returnlist=[]
        # Then, run a loop trough the class attribute "self.mylist",
        # and if the item is also on the otherlist, then append it
        # to our blank "returnlist":
        for item in self.mylist:
            if item in otherlist:
                returnlist.append(item)
        # Then, return the class initialized with the returnlist:
        return listmanipulation(returnlist)

    # Now, let's assign overload operators to some of our functions,
    # and create some new overload's:

    # The lenght of our list:
    def __len__(self):
        return len(self.mylist)

    # Get an specific item by index on our list
    def __getitem__(self,mykey):
        return self.mylist[mykey]

    # Set an item by index and value on our list
    def __setitem__(self,mykey,myvalue):
        self.mylist[mykey] = myvalue

    # This is an "and" operation between our list and other list
    def __and__(self,otherlist):
        return self.intersectlists(otherlist)

    # This is an "or" operation between our list and other list
    def __or__(self,otherlist):
        return self.unionlists(otherlist)

    # Let's print our list
    def __str__(self):
        return "My list contents: " + str(self.mylist)


# Now, let's do some playtest

# Define 3 lists:

list1 = [ 1,2,3,4,5,6 ]
list2 = [ 1,2,3,7,8,9,10,11,12 ]
list3 = [ 1,3,5,9,11 ]

# First, print our lists:

print ("Our lists are:", list1, list2, list3)

# Instantiate a new object:

mylistobject1 = listmanipulation(list1)

# And print it. This will call the __str__ overload operator:

print (mylistobject1)

print ("")

# Now, let's do an "and" operation and print the new object:
# This show the "__and__" overload in action:

mylistobject2 = mylistobject1 & listmanipulation(list2)

print ("The \"and\" (intersection, no duplicates) operation between objects:", mylistobject1, listmanipulation(list2), " is: ")
print (mylistobject2)

print ("")

# Now, let's to an "or" operation and print the new object:
# This show the "__or__" overload in action:

mylistobject3 = mylistobject1 | listmanipulation(list2)

print ("The \"or\" (union) operation between objects:", mylistobject1, listmanipulation(list2), "is: ")
print (mylistobject3)
print ("")

# Let's create another opbject:

mylistobject4 = listmanipulation(list3)

# And print it, showing the __str__ overload in action

print (mylistobject4)

# Now, let's get the list, and change all it's members for squared versions or the
# former values.
# This shows the __getlist__ and __setlist__ overload in action:

index = 0
for value in mylistobject4:
    print ("Original Value: ", mylistobject4[index])
    mylistobject4[index] = value ** 2
    print ("New value is: ", mylistobject4[index])
    index += 1

print ("Now my list object is: ")
print (mylistobject4)

# And finally, to see the __len__ overload in action:

print ("My object lenght is: ", len(mylistobject4))

print ("")

# END
