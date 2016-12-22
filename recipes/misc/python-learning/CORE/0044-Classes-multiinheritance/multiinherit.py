#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 16, 2016
# TigerLinux AT Gmail DOT Com
# Multiple Inheritance
#
#

print ("")

# This excercise show how a class can inherit from multiple super
# clases:

class catcolor:
    def __init__(self,color):
        self.color = color
    def returncolor(self):
        return str(self.color)

class catrace:
    def __init__(self,race):
        self.race = race
    def returnrace(self):
        return str(self.race)

# Now, the class that will inherits from both classes:

# First, in the class declaration, we include the two previouslly
# declared clases. Both are super classes for the new class
class catdata(catcolor,catrace):
    # Here, we init our class with the parameters we are going
    # to use
    def __init__(self,catname,catdatacolor,catdatarace):
        # Then, we "init" the inherited classes with the data
        # in the __init__ from this class
        catcolor.__init__(self,catdatacolor)
        catrace.__init__(self,catdatarace)
        self.catname = catname
    def printcatdata(self):
        # Here, we'll call the two methods inherited from the catcolor and catrace
        # super classes !.
        print ("The cat \"" + self.catname + "\" is a \"" + catcolor.returncolor(self) + "\" \"" + catrace.returnrace(self) + "\" Cat")

# Now, let's init an instance:

kiki = catdata("Kiki","Base white with black spots","Cacri (callejero criollo)")

# And, print the object data calling a method inside the object:

kiki.printcatdata()

print ("")

# END
