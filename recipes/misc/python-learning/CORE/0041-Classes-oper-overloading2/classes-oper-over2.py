#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 16, 2016
# TigerLinux AT Gmail DOT Com
# More operators overloading
#
#

print ("")

# Let's explore mode overloading operators here !

class myoverload:
    def __init__(self,value1):
        # This construct the class and set the first
        # attribute:
        self.value1 = value1

    # Now, let's use __call__ operator, that will define
    # a secondary argument for the class:
    def __call__(self,value2):
        # If called like classobject(number) it will
        # return an exponential of the original value1 elevated
        # to value2
        return self.value1 ** value2
    # And, what about comparision operators ??
    # greater than:
    def __gt__(self,value2):
        return self.value1 > value2
    # lower than:
    def __lt__(self,value2):
        return self.value1 < value2
    # bool, for True comparisions:
    def __bool__(self):
        return True
    # This is called when the object is destroyed:
    def __del__(self):
        print ("I'm dead now and my last value was: " + str(self.value1))


# And, let's test. This will construct our object, and set value1:

mynumber = myoverload(2)

# Now, let's call it with a square of the original value:

print (str(mynumber.value1) +  " ^ 2 is: " +  str(mynumber(2)))

# And exponential to 5:

print (str(mynumber.value1) + " ^ 5 is: " + str(mynumber(5)))

print ("")

# Test for gt, lt and bool:

print (mynumber > 3)
print (mynumber < 4)
if mynumber:
    print ("Yes it's TRUE!!")
else:
    print ("No.. it's FALSE!!")

print ("")

# Now, let's reasign the mynumber object to another thing, effectivelly
# killing it as a class, and calling the "__del__" overload operator:

mynumber = 4

print ("")

# END
