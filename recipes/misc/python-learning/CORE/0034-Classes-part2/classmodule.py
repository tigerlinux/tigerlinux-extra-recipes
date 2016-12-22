#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Classes - Part2 - Our classes in a module
#
#

"""
Module with the classes:
NombreDeGato:
    Methods: setname(name) and printname
DatosDeGato:
    Methods: setname(name), setcolor(color), printname, printcolor, printcolorandname
MasDatosDeGato:
    Methods: setname(name), setcolor(color), printname, printcolor, printcolorandname, caraderaton(bool)
"""

__all__ = [ "NombreDeGato", "DatosDeGato", "MasDatosDeGato"  ]

# First class - this will be a "Super Class"

class NombreDeGato:
    def setname(self,namestring):
        self.catname = namestring
    def printname(self):
        print ("The cat name is: " + self.catname)

# Second class - it includes the original class as a Super Class:

class DatosDeGato(NombreDeGato):
    def setcolor(self,colorstring):
        self.color=colorstring
    def printcolor(self):
        print ("The Cat Color is: " + self.colorstring)
    # The following method uses data from the superclass NombreDeGato:
    def printcolorandname(self):
        print ("The Cat Name is: \"" + self.catname + "\" and the Cat Color is: " + self.color)

# Third class, includes the second class as it's super class (inherits also
# from the first class) and redefines a method from it's super class (printcolor method)

class MasDatosDeGato(DatosDeGato):
    def caraderaton(self,mousefacebool=False):
        if mousefacebool:
            self.mousefacestring="has"
        else:
            self.mousefacestring="does not has"
    # Here, we are basically "overloading" the original printcolor
    # method defined on the DatosDeGato class
    def printcolor(self):
        print ("The Cat with name \"" + self.catname + "\" is \"" + self.color + "\" and " + self.mousefacestring + " a mouse face!!")

# END
