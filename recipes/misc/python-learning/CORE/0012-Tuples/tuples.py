#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12, 2016
# TigerLinux AT Gmail DOT Com
# Tuples
#
#

# Tuples are like lists, but they are immutable like string chars. Also, tuples
# are defined with () instead of []

# First sample tuple:

mytuple1 = ( 1, 3, 7, 12 )

print ( "My first tuple is: " + str(mytuple1) )

# Let's print the tuple odd and even numbers:

print ("")

for number in mytuple1:
    if number % 2 != 0:
        print ( "The number \"" + str(number) + "\" is an odd number" )
    else:
        print ( "The number \"" + str(number) + "\" is an even number" )

# Note that the tuples does not support as many methods like lists. Their only advantage is the
# persistence or immutability in their data. As soon as you first define a tuple, it cannot
# be changed:

print ("")

mytuple2 = ( "Kiki", "Rayita", "Negrito", 3.0, [2,4,6] )

for value in mytuple2:
    print ( str(value) )

print ("")
print (mytuple2[1])
print (mytuple2[4][1])
print ("")

# END
