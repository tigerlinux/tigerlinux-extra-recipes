#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12, 2016
# TigerLinux AT Gmail DOT Com
# More-Maths. This time we'll explore the "decimal" module
#
#

# Let's play a little with maths and operations.

# We'll import the "decimal" module in order to work out with fixed precision later:

import decimal

# First, let's define some numbers:

# An integer:

myinteger1 = 1

# And exponential

myexponential1 = 1.234e+50

# A negative number:

mynegativenumber1 = -24

# Another exponential and negative

myexpnegative1 = -1.23e-5

# Let's print them:

print ("")
print ("Our original numbers here:")
print (myinteger1)
print (myexponential1)
print (mynegativenumber1)
print (myexpnegative1)
print ("")

# Now, let's convert the integer to float and the negativeexp to int. Also, print the absolute of the negative number:

print("Our numbers after some conversions:")

print (int(myexpnegative1))
print (float(myinteger1))
print (abs(mynegativenumber1))

print ("")

# Now, some divisions. Normal and floor:

print ("Normal division: 4.0/3.0: ", 4.0/3.0)
print ("The same, but with integers 4/3: ", 4/3)
print ("Now, the same, but as floor division 4.0//3.0: ", 4.0//3.0)
print ("Let's divide 23.45/5.6 and ensure it's a float result: ", float(23.45)/float(5.6) )
print ("Let's round the result of 23.45/5.6: ", round(23.45/5.6) )
print ("")

# Ok, let's try now some fixed precision

print ("Let's divide 23.4532342/5.2983929: ", 23.4532342/5.2983929)

# Now, the same, using decimal library

print ("The same, using decimal lib, default decimal context: ", decimal.Decimal(23.4532342)/decimal.Decimal(5.2983929))

# Let's adjust ourself globally to 6 decimals:

decimal.getcontext().prec = 6

print ("The same, using decimal lib, 6 digits decimal context: ", decimal.Decimal(23.4532342)/decimal.Decimal(5.2983929))
print ("Divide 74/5.2, decimal way, with 6 digits precision: ", decimal.Decimal(74)/decimal.Decimal(5.2))
print ("")

# NOTE SOMETHING HERE: The actual precision includes ALL digits, not only what's right of the "."
# If you want to format the print to include only the specific digits after the ".", use "{:.NUM-DIGITSf}".format(number)
# Sample::

print ("Let's divide 23.4532342/5.2983929 using decimal lib, and format the print to 2 decimal digits: ", "{:.2f}".format(decimal.Decimal(23.4532342)/decimal.Decimal(5.2983929)))
print ("")

# END
