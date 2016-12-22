#!/usr/bin/python3
#
# By Reynaldo R. Martinez P.
# Sept 09 2016
# TigerLinux AT Gmail DOT Com
# Sa sample with some operations including usage of
# a library import and some operations
#
#

#
# Here, weproceed to import the "SYS" library
import sys                  

# Next, we print the "sys.platform" information. This comes from the "sys" library
# previouslly imported
print("We are running in:")
print(sys.platform)
print ("")

# Now, some basic operations:

# A sum:
print( "This is a SUM: 5 + 200" )
print( 5 + 200 )
print ("")

# A rest:
print( "This is a REST: 205 - 5" )
print ( 205 - 5 )
print ("")

# A multiplication:
print ( "This is a multiplication: 34 x 6" )
print ( 34 * 6 )
print ("")

# A Division
print ( "This is a Division: 342 / 20" )
print ( 342 / 20 )
print ("")

# This is a MODULE
print ( "This is a MODULE from the last division: 342 Module 20" )
print ( 342%20 )
print ("")


# This is an exponential:
print ( "This is an exponential: 2 ^ 200" )
print(2 ** 100)
print ("")

# Define two string variable and concatenate them in the print statement
var1 = "The Life is "
var2 = "Strange....."
print ( "We define two strings, and concatenate them in a single print:")
print ( var1 + var2 )
print ("")

# Define 3 strings and print them in the same line:
var3 = "Kiki"
var4 = "Rayita"
var5 = "Negrito"
print ( "My 3 cats are named:" )
print ( var3, var4, var5 )
print ( "" ) 

# Next, we define a string variable, and print it eight times:
mystring = " !String! "
print ( "Let's print a string 10 times... Just because we can...jejeje:" )
print( mystring * 10 )
print ("")
print ("")
# END
