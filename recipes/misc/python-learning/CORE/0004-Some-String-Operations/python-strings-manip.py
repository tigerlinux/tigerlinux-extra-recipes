#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 09 2016
# TigerLinux AT Gmail DOT Com
# Some String Manipulations
#
#

# Let's define a string (the actual name of one of my 3 cats):

mystring = "Rayita"

print ( "" )
print ( "My String is " + mystring )

# Now, the lenght of the string:
# Because the "len" function returns an "int", we need to
# convert it to a "string" with a "str" function:

print ( "My string size is " + str(len(mystring)) + " bytes long" )

# Now, let's print the first and third letters of my string. Beware: Actual count
# begin in "0" as many other thins in computing. Also, we can se some "escaping":

print ( "The first letter of my string is \"" + mystring[0] + "\" and the third is \"" + mystring[2] + "\"" )

# Now, lt's print the last letter of my string:
# Using len, that give us the actual size of the string, and resting to it "1",
# actually give us the last position for our string, then, our last letter:

print ( "The last letter of my string is \"" + mystring[len(mystring)-1] + "\"" )

# Also, we can print a range of letters. This mean: From the index "1" (second letter) to
# the index 4, but not index 4). This basically "slicing" a string:

print ( "The second, third and fourth letters of my string are \"" + mystring[1:4] + "\"" )

# Now, using again the trick with "len(mystring)-1" we'll print the letters from
# the third to the penultimate letter:

print ( "The letters, from the third to the penultimate one are: \"" + mystring[2:(len(mystring)-1)] + "\"" )

# And the range from the second letter to the last one:

print ( "The letters, from the second letter to the last one are: \"" + mystring[1:] + "\"" )

# We can also print from the last one, using negative indexes. This next print's from the last

print ( "Now, backward. The penultimate letter is: \"" + mystring[-2] + "\"" )

# The last letter:

print ( "The last letter is: \"" + mystring[-1] + "\"" )

# The last two letter using negative indexes:

print ( "My string last two letters are: \"" + mystring[-2:] + "\"" )

print ( "" )
# End
