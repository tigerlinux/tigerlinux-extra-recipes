#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Classes part 3
#
#

print ("")

# In this class, we'll explore the effects of the specially
# named attributes __init__, __add__ and __str__

class MyCatClass():
    # This init's the instance and it's first variable
    # "catname"
    def __init__(self,string1):
        self.catname = string1
    # This is called when the objects is added with "+" operator
    def __add__(self,string2):
        return MyCatClass(self.catname + string2)
    # This is called when used in print
    def __str__(self):
        return "My name is: " + self.catname

# Let's call it then:

# This call the __init__ part inside the object, which set catname = Rayita

rayita = MyCatClass("Rayita")

# This, call the __str__ part inside the object, which print's the string with
# the already set catname variable

print (rayita)

print ("")
# Now, let's use the add operator and see what happens

rayitacomplete = rayita + " De Rayon"

# The new object "rayitacomplete" will call the "__add__", setting the actual
# variable "catname" for this object as the original name in rayita object plus
# the new string " De Rayon". Then we print:

# This, again, call the __str__ part, but now the catname is "Rayita De Rayon"

print (rayitacomplete)

print ("")

# END
