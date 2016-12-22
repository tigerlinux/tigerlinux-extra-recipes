#!/usr/bin/python3
#
# By Reynaldo R. Martinez P.
# Sept 09 2016
# TigerLinux AT Gmail DOT Com
# INPUT TEXT FROM CONSOLE
#
#

import sys

print ( "Python version is:", sys.version_info )

# What are we doing here ??. It happens that the input management functions are
# different in py2 and py3. By using "sys", we proceed to see what python version
# is running the script, and then, use the right input function:

if sys.version_info.major == 2:
   mytext = raw_input("Python Series 2: Please enter any string and then press ENTER: ")
elif sys.version_info.major == 3:
   mytext = input("Python Series 3: Please enter any string and then press ENTER: ")
else:
   print ("Unsupported python version")
   mytext = "UNSUPPORTED"

print ( "Your entered the following text:" )
print ( mytext )


