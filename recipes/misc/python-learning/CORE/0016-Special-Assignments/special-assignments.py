#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 14, 2016
# TigerLinux AT Gmail DOT Com
# Special Assignments
#
#

# First special assignments:

# Here, each variable name in the left side, is assigned to a value in the same position
# at the right side

[ gato1, gato2, gato3 ] = ( "Kiki", "Rayita", "Negrito" )

print (gato1)
print (gato2)
print (gato3)

# Similar case: Here, a variable in the left side is assigned to a single char in the left side:

( a1, a2, a3, a4, a5, a6 ) = "Rayita"

print (a1,a2,a3,a4,a5,a6)

# Now, we declare a string with 4 char's:

string1 = "Kiki"

# Then assign new variables to the value of the string.. 4 variables (must match):

c1,c2,c3,c4 = string1

print (c1,c2,c3,c4)

# Other cases:

# Here, all 3 variables are assigned to the same value: "Gatos"

kiki = rayita = negrito = "Gatos"

print ( "Kiki, Rayita and Negrito are " + negrito )

# Now, we can use "range" in order to assign a "range" of number to a set of variables:
# This will assign the values 0 - 3 (range(4))

b1,b2,b3,b4 = range(4)

print (b1,b2,b3,b4)

# Now, let's do something with empty mutable objects that are cross-referenced:

# We define two list's here, both referenced and empty:

list1 = list2 = []

# Now, we append data on the first list:

list1.append("Kiki")
list1.append("Rayita")
list1.append("Negrito")

# See the effect on list2:

print (list2)

# Now, append data on list 2:

list2.append("Kisa")

# And see the effect on both lists:

print (list1)
print (list2)

# Both list are referenced and will share the same data. Whatever you change on one, will made
# updated on the other because both lists are referenced and were created empty.

# END
