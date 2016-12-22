#!/usr/bin/env python
# coding: latin-1
#
# By Reynaldo R. Martinez P.
# Sept 20, 2016
# TigerLinux AT Gmail DOT Com
# Some unicode strings manipulation
#
#

# IMPORTANT WARNING. THIS EXCERSICE IS FOR PYTHON 2.6/2.7 ONLY !!

print ("")

# This time, we'll see some encoding/decoding functions for non-ascii
# strings.

# First, let's define a string, that intentionally has special char's non-us-ascii:

mynonusstr="Condición, están, vivirán, año, tenía"

# Now, in "normal conditions", this will fail... but... see the header of our file. After
# the shebang (!/usr/blah blah) we added: coding: latin-1. This enable our script
# to interpretate and print non-ascii chars:

print (mynonusstr)

# Now, same string, but in unicode. See the "u" before the escaped chars:

myunicodestr1 = u"\u0043\u006f\u006e\u0064\u0069\u0063\u0069\u00f3\u006e\u002c \u0065\u0073\u0074\u00e1\u006e\u002c \u0076\u0069\u0076\u0069\u0072\u00e1\u006e\u002c \u0061\u00f1\u006f\u002c \u0074\u0065\u006e\u00ed\u0061"

print (myunicodestr1)

# See the following text:

anotherstr="Hello( \xF4\xC4\xE8\xC2 )World"

# Print it, and you'll only see the Hello World part:

print (anotherstr)

# Now, let's use decode and you'll see the rest:

print (anotherstr.decode("latin-1"))

# Note that you can use the functions str and unicode to transform between types:

stringnormal = "My Text"
stringunicod = u"My Text"

print (str(stringunicod))
print (unicode(stringnormal))

print ("")
# END
