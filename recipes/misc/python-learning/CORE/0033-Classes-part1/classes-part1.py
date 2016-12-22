#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Classes - Part1
#
#

print ("")

# A simple class definition:

class NombreDeGato:
    def setname(self,namestring):
        self.catname = namestring
    def printname(self):
        print ("The cat name is: " + self.catname)

# Let's see how this work:

# First, we define 3 objects from the same class:

kiki = NombreDeGato()
rayita = NombreDeGato()
negrito = NombreDeGato()

# Each of those names are instances of the NombreDeGato class.

# Now, let's call their inside functions, which we can call
# from now: Methods. setname is a method:

kiki.setname("Kiki Ratonilla")
rayita.setname("Rayita de Rayon")
negrito.setname("Negrito de Electron")

# This specific "setname" method filled a variable inside the class
# object instance which is later used by the printname method:

kiki.printname()
rayita.printname()
negrito.printname()

print ("")

# Each object inherit all things from the class, and each function inside
# the class, is a method

# We can define another class which uses data from an already defined class.
# This make's the original class "a Super Class". The classes inherits all
# attributes from their superclasses:

class DatosDeGato(NombreDeGato):
    def setcolor(self,colorstring):
        self.color=colorstring
    def printcolor(self):
        print ("The Cat Color is: " + self.colorstring)
    # The following method uses data from the superclass NombreDeGato:
    def printcolorandname(self):
        print ("The Cat Name is: \"" + self.catname + "\" and the Cat Color is: " + self.color)

# Again, define a class instance object:

kikita = DatosDeGato()

# Set some of its values... one is inherited from the NombreDeGato Super Class:

kikita.setname("Kikita Ratonilla")
kikita.setcolor("Base White with Black Spots")

# And call the method for print:

kikita.printcolorandname()

# The last method, uses data from the super class (self.catname) inherited from the super class
# method call (setname), and also data from the new class (color)

# You can, again, set another class, that inherites from the class that also inherits from the
# original cat, and even rewrite some of the functions:

class MasDatosDeGato(DatosDeGato):
    def caraderaton(self,mousefacebool=False):
        if mousefacebool:
            self.mousefacestring="has"
        else:
            self.mousefacestring="does not has"
    # Here, we are basically "rewriting" the original printcolor
    # method defined on the DatosDeGato class
    def printcolor(self):
        print ("The Cat with name \"" + self.catname + "\" is \"" + self.color + "\" and " + self.mousefacestring + " a mouse face!!")

print ("")

negrurismo = MasDatosDeGato()
negrurismo.setname("Negrito")
negrurismo.setcolor("Black with white spots")
negrurismo.caraderaton()
negrurismo.printcolor()

print ("")

kikiloca = MasDatosDeGato()
kikiloca.setname("Kiki")
kikiloca.setcolor("Base White with Black Spots")
kikiloca.caraderaton(True)
kikiloca.printcolor()

print ("")

# END
