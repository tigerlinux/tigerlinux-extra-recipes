#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sep 14, 2016
# TigerLinux AT Gmail DOT Com
# Arguments
#
#

print ("")

# Here, we'll see other kind of arguments that can be passed to functions:
# tuples
# dictionaries

# First kind: tuples. See the following function:

def mytuples(*myarg):
    print ("Original tuple: " + str(myarg))
    for Tuple in myarg:
        print (Tuple)
    print ("")

mytuples(2)
mytuples("Kiki",2,"Ratiya",5,"Negrito",6)

# Second, like a dictionary:

def mydict(**myarg):
    print ("Original dictionary: " + str(myarg))
    mykeys = list(myarg.keys())
    mykeys.sort()
    for mykey in mykeys:
        print ("Key: " + str(mykey) + ", value: " + str(myarg[mykey]))
    print ("")

mydict(gato1="kiki",gato2="rayita",gato3="negrito")
mydict(val1=5.32,val2=4.67,val3=2.0,val4=5)

# A practical approach of a function with a tuple argument. Let's generate a
# function that gets as argument a tuple of numbers, and depending of a switch
# in the first argument, return another tuple as odds or even numbers:

def oddsorevens(test="evens",*listofnumbers):
    final=[]
    # First, let's loop to the list of numbers
    for number in listofnumbers:
        # If first argument is "evens" of "odds":
        if str(test) == "evens":
            if number % 2 == 0:
                final.append(number)
        elif str(test) == "odds":
            if number % 2 != 0:
                final.append(number)
        else:
            # If we dit not used even or odds, it justs
            # return the original arguments
            final.append(number)
    # Finally, return our list:
    return final

#
# Let's call it:

print (oddsorevens("evens",1,2,3,4,5,6,7,8,9,10))
print (oddsorevens("odds",1,2,3,4,5,6,7,8,9,10))
print (oddsorevens("original",1,2,3,4,5,6,7,8,9,10))

print ("")

# Getting specialy named arguments from a dictionary
# This function spects to collect the arguments "mouseface", "weight" and "color"
# The first argument is the cat name... jejeje
# The remaining arguments are completelly optional, and the function has some
# defaults

def catfunction(name,**extraargs):
    # function defaults declared here:
    mymouseface=extraargs.get("mouseface",False)
    myweight=extraargs.get("weight",0.0)
    color=extraargs.get("color","white")
    print ("The cat name is \"" + str(name) + "\", and weights " + str(myweight) + " Kg's")
    if mymouseface:
        print ("The cat does have a Mouse Face")
    else:
        print ("The cat does not have a Mouse Face")
    print ("And the cat color pattern is " + str(color))
    print ("")

catfunction("Kiki",mouseface=True,color="White base with black spots",weight=3.0)
# Now, using defaults:
catfunction("Default Cat")
# More data, using some arguments:
catfunction("Negrito",color="Black whith some white spots",weight=4.5)
catfunction("Rayita",color="Creamy white with gray-listed spots",weigth=3.5)

# END
