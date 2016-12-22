#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12, 2016
# TigerLinux AT Gmail DOT Com
# List Operations
#
#

# Let's define a pair of LISTS:

mylist1 = ["Oranges","Pineapples","Bananas"]
mylist2 = ["Gourds", "Blueberries"]

# Print my list:

print ( "My favourite fruits are: " + str(mylist1) )

# Let's count the items on the list:

print ( "My list has \"" + str(len(mylist1)) + "\" items" )

# We can have a new list, by concatenating list's:

mylist3 = mylist1 + mylist2

print ( "This is another list: " + str(mylist3) )

# Let's add items to a list:

mylist3.append("Strawberries")

print ( "I added a new fruit and my new list is: " + str(mylist3) )

# We can sort the list, forward and reverse:

mylist3.sort()

print ( "My fruit list sorted: " + str(mylist3) )

mylist3.reverse()

print ( "My fruit list reverse-sorted: " + str(mylist3) )

# Let's delete the item in index 3 (the fourth one) to the list:

mylist3.pop(3)

# Note that you can also remove by name, using list.remove(name)

print ( "My fruit list without a fruit at index 3 is: " + str(mylist3) )

# Convert the chars on a string to a items on a list:

mystring1 = "RAYITA"
mylist4 = list(mystring1)

print ( "My original string is ",mystring1," and my new list is ",mylist4 )

# Let's create a string from a list:

mystring2 = "".join(mylist3)

print ( "My new string2 is ", mystring2, " and it's derived from the list: ",mylist3 )

# End
