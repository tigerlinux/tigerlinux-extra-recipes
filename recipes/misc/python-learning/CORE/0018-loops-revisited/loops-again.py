#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 13, 2016
# TigerLinux AT Gmail DOT Com
# More and more loops
#
#

# Let's explore for/while loops here in several ways

# First, a simple while with a condition:
# This will loop until value1 gets equal to value 2

print ("")

value1 = 1
value2 = 10

while value1 <= value2:
    print ("The actual value is: " + str(value1))
    value1 += 1

print ("")

# Another way, in reverse

value1 = 1
value2 = 10

while value2 >=  value1:
    print ("The actual value is: " + str(value2))
    value2 -= 1

print ("")

# Now, in pass experiments we tested "break", but, what about "continue" ?. See next:

value1 = 1
value2 = 10

while value2 >= value1:
    if value2 % 2 != 0:
        value2 -= 1
        continue
    print ("The actual even number is: " + str(value2))
    value2 -= 1

print ("")

# In the former sample, the continue forces the code to go to the next loop whitout doing the "print" part,
# in effect, only the "print the actual even number" will be executed when the value2 variable value is not
# an odd number (value2 % 2 != 0)
# We can do the same without the continue the following way:

value1 = 1
value2 = 10

while value2 >= value1:
    if value2 % 2 == 0:
        print ("The actual even number is: " + str(value2))
    value2 -= 1

print ("")

# Now, the following is unique to python. A while/else structure. See the followin case:

mylist = [ 1,2,3,4,5,6,7 ]

compare = 3
initial = 1

while initial <= mylist[len(mylist)-1]:
    print ("Comparing number " + str(mylist[initial-1]))
    if mylist[initial-1] == compare:
        print ("Comparision number FOUND and it's " + str(initial))
        break
    initial += 1
else:
    print ("Loop finished, and the comparision number was not found")

print ("")

# Now, let's change the compare number to anything outside the values in our
# list, so the "else" part triggers:

mylist = [ 1,2,3,4,5,6,7 ]

compare = 9
initial = 1

while initial <= mylist[len(mylist)-1]:
    print ("Comparing number " + str(mylist[initial-1]))
    if mylist[initial-1] == compare:
        print ("Comparision number FOUND and it's " + str(initial))
        break 
    initial += 1
else:
    print ("Loop finished, and the comparision number was not found")

# As you can see in the last code block, if the loop finish whitout a break, the else
# get triggered. Again, this structure currently exits only in python !

print ("")

# Now, let's see the "for loops".

# Let's define a list, and run it trough a for loop:

mylist = [ "Kiki", "Rayita", "Negrito" ]

for catname in mylist:
    print (catname + " is a CAT !!")

print ("")

# We can also include an "else" that will trigger if no-break was called. See the following two
# examples, one triggering a break, the other triggering the else:

# First, with the condition that triggers the break:

mylist = [ "Kiki", "Rayita", "Nash", "Negrito" ]

for catname in mylist:
    if catname == "Nash":
        print ("ALERT !!. Found a DOG in our CAT PACK and the name is " + catname + ". Aborting the loop !")
        break
    else:
        print (catname + " is a CAT !!")
else:
    print ("And also KISA is a CAT!!")

print ("")

# Now, with the condition that triggers the "Else":

mylist = [ "Kiki", "Rayita", "Negrito" ]

for catname in mylist:
    if catname == "Nash":
        print ("ALERT !!. Found a DOG in our CAT PACK and the name is " + catname + ". Aborting the loop !")
        break
    else:
        print (catname + " is a CAT !!")
else:
    print ("And also KISA is a CAT!!")

print ("")

# More types used in loops:

# List of values

for number in [ 1, 2, 3, 4, 5 ]:
    print ("My number is :" + str(number))

print ("")

# String

mystring = "Gatiburu"

for letter in mystring:
    print (letter)

print ("")

# Numbers in a range

for number in range(10):
    print ("Range number: " + str(number))

print ("")

# A list of tuples:

mytuplelist = [ (1,3),(2,4),(5,7),(8,10) ]

print ("Complete list of tuples: " + str(mytuplelist))

for (value1, value2) in mytuplelist:
    print (value1, value2)

print ("")

# A dictionary:

mydict = { "gato1": "Kiki", "gato2": "Rayita", "gato3": "Negrito" }

for mykey in mydict:
    print (str(mykey) + " name is " + str(mydict[mykey]))

print ("")

# An iteration of both keys and items of the previous example, which produces the same effect:

mydict = { "gato1": "Kiki", "gato2": "Rayita", "gato3": "Negrito" }
list(mydict.items())

for (mykey,myvalue) in mydict.items():
    print (str(mykey) +  " name is " + str(myvalue))

print ("")

# Now, let's see different ways to make comparisions in nested loops:

list1 = [ "Kiki", "Rayita", "Nash", "Toulousse", "Negrito" ]
list2 = [ "Nash", "Toulousse", "Perro" ]

found = False
counter = 0

for cat in list1:
    for dog in list2:
        if cat == dog:
            print ("Found a DOG in the CAT PACK, and the culprit name is: \"" + cat + "\"")
            found = True
            counter += 1
else:
    if not found:
        print ("Not found any DOGS in the CAT pack")
    else:
        print ("Number of DOGS found in the CAT pack: " + str(counter))

print ("")

# We can do the same letting python to do the work for us:

list1 = [ "Kiki", "Rayita", "Nash", "Toulousse", "Negrito" ]
list2 = [ "Nash", "Toulousse", "Perro" ]

found = False
counter = 0

for cat in list1:
    if cat in list2:
        print ("Found a DOG in the CAT PACK, and the culprit name is: \"" + cat + "\"")
        found = True
        counter += 1
else:
    if not found:
        print ("Not found any DOGS in the CAT pack")
    else:
        print ("Number of DOGS found in the CAT pack: " + str(counter))

print ("")

# In the last example, we get rid of the second loop (for dog in list2) and the if (if cat == dog) with a simple line
# containing "if cat in list2"

# END
