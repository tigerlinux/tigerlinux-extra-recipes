#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 16, 2016
# TigerLinux AT Gmail DOT Com
# Operator Overloading
#
#

print ("")

# Some operators like +, print, -, "or", and others can be "overloaded"
# by the class. In past experiments, we tested with "__add__", "__init__"
# and "__str__". Let's do try some others here:

class overloadingnumber:
    # __init__ operator overload and constructor of the class:
    def __init__(self,num1):
        self.num1 = num1
        # Let's define this variable list... we'll have a use
        # for it later
        self.anydata = [ number for number in range(0,100) ]

    # __str__ for be used in print statements like:
    # print classedobject
    def __str__(self):
        return "classdata number: " + str(self.num1) + ", and list: " + str(self.anydata)

    # __add__ overloading operator to be used in "+" like object + value
    def __add__(self,anothernumber):
        return overloadingnumber(self.num1 + anothernumber)

    # __radd__ it's like the __add__ but applied when value + object is called:
    def __radd__(self,anothernumber):
        return overloadingnumber(anothernumber + self.num1)

    # __iadd__ is, again, like add, but applied in object += value forms:
    def __iadd__(self,anothernumber):
        self.num1 += anothernumber
        return self

    # __sub__ overloading operator to be used in "-"
    def __sub__(self,anothernumber):
        return overloadingnumber(self.num1 - anothernumber)

    # __getitem__ overloading is used when the class is named
    # in an indexing operation, like: classobject[index]
    def __getitem__(self,index):
        # Just return the value of the anydata list:
        return self.anydata[index]
    # __setitem__ overloading is used too for setting values
    # remember the self.anydata list ?. Let's use it here:
    def __setitem__(self,index,value):
        self.anydata[index] = value
    

# Let's try it:

object1 = overloadingnumber(23)

# Let's print, add and rest:

print (object1)
print (str(object1 - 20))
print (str(object1 + 40))
print (str(23 + object1))

# Note that other operations have it's overloading operators too:
# __mul__, __rmul__, __imul__ and so on

print ("")

# Let's loop and print
for i in range(0,10):
    object1 += 10
    print (object1.num1)

print ("")

# Also, you can use it for slices, but beware !. The actual function used by the
# __getitem__ must support to be used with slices. If we call object1[2:4] with
# our actual code, we'll generate an error !

# What about set item ???. This call's __setitem__:

for i in range(0,len(object1.anydata)):
    object1[i] = i**3

# And get them ??. This call's __getitem__:

counter = 0

for value in object1:
    print ("Value in index: " + str(counter) + " is: " + str(value))
    counter += 1

print ("")

# See again __str__:

print (object1)

# Iterations in classes include __iter__ and __next__, with the same effect we saw in
# iterations/yield exercises !

print ("")

#END
