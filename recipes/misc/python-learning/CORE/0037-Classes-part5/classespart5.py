#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Spet 16, 2016
# TigerLinux AT Gmail DOT Com
# A practical class with constructor and methods
#
#

print ("")

# Let's define a class with all it's things:

class catdatacomplete:
    # Class constructor
    def __init__(self,strcatname,strcatcolor,numweight,boolmouseface=False):
        self.strcatname = strcatname
        self.strcatcolor = strcatcolor
        self.numweight = numweight
        self.boolmouseface = boolmouseface

    # First method print all data:
    def printalldata(self):
        print ("The cat name is: ",self.strcatname)
        print ("The cat color is: ",self.strcatcolor)
        print ("The cat weight is: ",self.numweight)
        if self.boolmouseface:
            print ("The cat has a mouse face")
        else:
            print ("The cat does not has a mouse face")

    # Let's use str too:
    def __str__(self):
        if self.boolmouseface:
            self.mymouseface = "has a mouse face"
        else:
            self.mymouseface = "does not has a mouse face"
        return "The cat name is: " + self.strcatname + ", with weight: " + str(self.numweight) + ", color: " + self.strcatcolor + ", and " + self.mymouseface

    # Let's create a function that return's a dictionary of our data:
    def returndict(self):
        self.mydict = {}
        self.mydict["name"] = self.strcatname
        self.mydict["color"] = self.strcatcolor
        self.mydict["weight"] = self.numweight
        self.mydict["mouseface"] = self.boolmouseface
        return self.mydict


# Ok, with the class ready, let's instantiate an object:

kiki = catdatacomplete("Kiki","Base white with black spots",3.2,True)

# Now, let's call the methods:

kiki.printalldata()
print (kiki)
print (kiki.returndict())

print ("")

# Note that the original class included a default (boolmouseface). Let's use this to
# instantiate another object:

rayita = catdatacomplete("Rayita","Creamy white with gray-listed patches", 4.0)

rayita.printalldata()
print (rayita)
print (rayita.returndict())

print ("")

# Also, you can pass atributes with names:

negrito = catdatacomplete(strcatname="Negrito", strcatcolor="Black with white belly", numweight=4.5)

negrito.printalldata()
print (negrito)
print (negrito.returndict())

print ( "" )

# Note something here. You can modify the variables declared inside a class, as long they are not
# private (defined with _variablename):

negrito.strcatname = "Negrura de Gato"

# then:

negrito.printalldata() 

print ("")

# END
