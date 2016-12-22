#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sep 12, 2016
# TigerLinux AT Gmail DOT Com
# String Operations
#
#

# Let's define some strings:

string1 = "Kiki"
string2 = "Rayita"
string3 = "Negrito"
string4 = "Kiki,Rayita,Negrito"
string5 = "Kiki,Rayita,Negrito\n"

# From the first string, find the offset position of the substring "ik":

print ( "The offset of substring \"ik\" from string \"" + string1 + "\" is: " + str(string1.find("ik")))

# From string 2, let's replace the "yi" ocurrence with "yonci". Note that string types are immutables, but, the
# actual print can be modified while the original variable remains the same:

print ( "The alternate name of \"" + string2 + "\" is: \"" + string2.replace("yi","yonci")  + "\"" )

# Also, we can change to capital or lower using string.upper() or string.lower(). Sample:

print ( "The black and beautifull cat name is \"" + string3.upper() + "\"" )

# We can test is a variable is "alpha" or "digit". Sample:

print ( "The variable string 1 is alpha ?: " + str(string1.isalpha()) )
print ( "The variable string 2 is digit ?: " + str(string2.isdigit()) )

# Let's manipulate the ending new-line of a string:

print ( "The cat's names with a new line at the end: " + string5 + " and without new line...: " + string5.rstrip() )

# Let's convert a string into a list. The original string is "Kiki,Rayita,Negrito" and is made of 3 string concatennated
# using ",". Let's split by using the ",":

list1 = string4.split(",")

print ( "The cat's name's, converted into a list: " + str(list1) )

# We can use advanced formatting with strings too:

print ( "I have 3 cats and their names are %s, %s and %s" % (string1, string2, string3)  )

# Anther way to use formatting:

print ( "Our cats are {0}, {1}, and {2}".format(string1,string2,string3) )

# End
