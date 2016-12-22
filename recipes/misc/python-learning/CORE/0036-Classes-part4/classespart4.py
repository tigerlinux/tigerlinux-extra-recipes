#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 16, 2016
# TigerLinux AT Gmail DOT Com
# Simple Classes
#
#

print ("")

# Let's see a simple class, with no methods or any other object.

class simpleclass():
    pass

# The "pass" statement is used when no other statements are included.

# Now, let's initialize an instance of the class:

killer = simpleclass()

# And, the magic:

killer.variable1 = 23
killer.list1 = [ 1, 2, 3, 4 ]
killer.dict1 = { "a": 1, "b": 2, "c": 3 }

# The, print:

print (killer.variable1)
print (killer.list1)
print (killer.dict1)

print ("")

# The actual magic here is the fact that no one of the attributes referenced here
# were actually declared inside the class, yet, they are part of the class instance
# just because we decided to declare them after we created the class instance

# Now, let's do something more interesting. Another simpleclass without anything:

class simpleclass2():
    pass

# And, set two attributes directly attached in the class:

simpleclass2.gatolist = [ "Kiki", "Rayita", "Negrito" ]

# Then, instantiate a class object:

gatos = simpleclass2()

# And:

print (gatos.gatolist)

# Mofify the gatolist attribute:

gatos.gatolist = [ "Kiki", "Rayita", "Negrito", "Kisa" ]

print (gatos.gatolist)

print ("")

# The "gatos.gatolist" attribute inherits it's value from the original assignment
# when we stated "simpleclass2.gatolist", but, because "gatos" is a separate object,
# we can modify the variable whitout affecting other instances of the object. See:

masgatos = simpleclass2()

print (gatos.gatolist)
print (masgatos.gatolist)

print ("")

# The gatos.gatolist object is modified as we did before, but the masgatos.gatolist
# objects retains the values from the original class assignment !.

# Note that we can do the same for methods. See this:

# We'll define a function here. Note that we need the "self" because this function
# will be used inside a class:

def printnames(self,mylist):
    for name in mylist:
        print (name)

# Now, let's assign this function as a method for the class "masgatos":

simpleclass2.printcatnames = printnames

# The last statement defined the method "printcatnames" inside the class "masgatos",
# and based that method in the code of "printnames" function. Now, see this:

masgatos.printcatnames(masgatos.gatolist)

# See what happened here ?. Just because we defined the method in the original class,
# all objects already instantiated using that class automatically inherit the new
# method !

print ("")

# Note something interesting here. This is a way to use attributes instead of
# dictionaries. See this:

mydict2 = {}
mydict2["name"] = "Kiki"
mydict2["mousefase"] = True
mydict2["color"] = "Base white with black patches"

# Now, the same but using a class:

class catdata():
    pass

kiki = catdata()
kiki.name = "Kiki"
kiki.mouseface = True
kiki.color = "Base white with black patches"

# Let's print:

print (mydict2)
print ("Name:",kiki.name,", Mouse face:", kiki.mouseface,", Color:", kiki.color)

# This shows again: Python has a tousand ways to skin a cat !!

print ("")

# END
