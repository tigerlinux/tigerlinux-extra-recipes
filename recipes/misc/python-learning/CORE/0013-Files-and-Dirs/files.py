#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12, 2016
# TigerLinux AT Gmail DOT Com
# Basic operations with files
#
#

# Let's import os. We'll need it for some file operations:

import os

# Let's define a pair of filenames:

myfilename = "data.txt"
myfilenamerenamed = "data2.txt"

# Then following statement will create (or open for write) our
# file, and return a "object" to the "myfile" name. Python is an
# OOP languaje (OOP = Object Oriented Programming) so many things
# here contain methods and attributes !.

myfile = open(myfilename, "w")

# Now, write the following text into the file:

myfile.write("Kiki\n")
myfile.write("Rayita\n")
myfile.write("Negrito\n")

# Close the file:

myfile.close()

# Let's open it again, but read only

print ("")

myfile = open(myfilename, "r")

mytext = myfile.read()
print ( mytext )

# Note that, everytime i use myfile.write after an open, I basically reset's the file
# contents, meaning, I'm not appending, but erasing and creating as new any contents

# Now, let's open the file again, but, in "append" mode:

myfile = open(myfilename, "a")

# And write more data:

myfile.write("Kiki Ratonila\n")
myfile.write("Rayoncita de Rayon\n")
myfile.write("Negrurismo de Renegro\n")

# Close the file:

myfile.close()

# Ok... using the OS library, let's see the directory contents

print ( "\nCurrent directory contents: " + str(os.listdir(os.curdir)) + "\n" )


# Let's open it again, but read only

myfile = open(myfilename, "r")

mytext = myfile.read()
print ( mytext )

myfile.close()

# Ok... using the OS library, let's rename the file:

os.rename( myfilename, myfilenamerenamed )

# Now, let's open it again in write mode, but with the new filename:

myfile = open(myfilenamerenamed, "w")

# Let's declare a listp:

mylist1 = ("Kiki", "Rayita", "Negrito", "Ratona", "Rayadura", "Negrurismo")

# And write that list, each line with a trailing "\n" to the file

for data in mylist1:
    myfile.write(data+"\n")

# Then, close the file

myfile.close()

# And print the actual dir contrents

print ( "\nCurrent directory contents: " + str(os.listdir(os.curdir)) + "\n" )

# Let's open it again, but read only and show the data inside the file

myfile = open(myfilenamerenamed, "r")

mytext = myfile.read()
print ( mytext )

myfile.close()

# Now, let's read the file, line by line. Note that the line must be actually ended by a "\n" to be
# considered really a line. Also, with "rstrip()" method, we ensure to get rid of the final "\n" when
# printing each line in the loop:

myfile = open(myfilenamerenamed, "r")

count = 1
for line in myfile:
    print ( "Line number \"" + str(count) + "\", contents: \"" + line.rstrip() + "\"" )
    count += 1

myfile.close()

# Ok, let's delete the file:

os.remove(myfilenamerenamed)

# And print again the directory contents:

print ( "\nCurrent directory contents: " + str(os.listdir(os.curdir)) + "\n" )

# End
