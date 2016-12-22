#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 13, 2016
# TigerLinux AT Gmail DOT Com
# Functions Basics
#
#

print ("")

# A single function definition:

def multiply(number1, number2):
    return number1 * number2

myvar = multiply(10,20)

print (myvar)
print (multiply(5,6))
print (multiply("K",4))

print ("")

# Something more complex. This one intersects two list, returning a list with the
# intersection of both list

def intersect(list1,list2):
    listresult=[]
    for value1 in list1:
        if value1 in list2:
            listresult.append(value1)
    return listresult

catsonly = [ "kiki", "rayita", "negrito" ]
catsanddogs = [ "nash", "tolousse", "kiki", "negrito" ]

print (catsonly)
print (catsanddogs)
print (intersect(catsonly,catsanddogs))
print (intersect([1,2,3,4],[1,6,8,7,3]))

print ("")

# Now, all the vars inside a function are local by default, unless we define a global:

# First, let's create a variable and assign it a value:

gato = "Kiki"

# now the function, were we'll use the same variable but indicating is a global var:

def namechanger(name):
    global gato
    gato = name

# Then, let's do the trick:

print ("The variable is: " + gato)
namechanger("Rayita")
print ("The variable now is: " + gato)

print ("")

# Also, we can define a function which uses a global variable:

# This is a global variable:

globalcatname = "Kiki, Rayita y Negrito son Gatos !!"

# Then, a function uses the global variable defined outside the function:

def usesglobal(repetitions):
    for rep in range(repetitions):
        print (globalcatname)

# Let's call the function:

usesglobal(3)

print ("")

# Functions with defaults: The following example defines the argument with a default value. See the
# effects of this:

def defaulted(string="Kiki",number=3):
    for i in range(number):
        print (string)

# Now, call the function, with and without arguments:

defaulted()
defaulted("Rayita")
defaulted("Negrito",2)

# Note something here. In order to include the second argument only, you need to doit the followig way:

defaulted(number=8)

# You can do it with both arguments:

defaulted(string="Gatiburu",number=2)

print ("")

# Functions with attributes. Let's see the following function:

def attr(val1,val2):
    attr.division = val1 / val2
    attr.multiply = val1 * val2
    attr.sum = val1 + val2
    attr.exp = val1 ** val2
    print ("Values: " + str(val1) + " and " + str(val2))
    return attr

# Now, let's call the function

attr(5,2)
print (attr.division, attr.multiply, attr.sum, attr.exp)

print ("")

# Call it again, and the atributes change:

attr(23.4,12.5)
print (attr.division, attr.multiply, attr.sum, attr.exp)

print ("")

# Now, let's assign the function to a variable:

myvar1 = attr(5,6)

# And print the variable attributes, inherited from the function: NOTE: For this to work,
# the return in the function must be the same name of the function:

print (myvar1.division, myvar1.multiply, myvar1.sum, myvar1.exp)

# NOTE SOMETHING HERE !. The attributes keep the state globally, no matter if the name
# of the function was assigned to a variable. Keep that in mind !

print ("")

# END
