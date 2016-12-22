#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Importing classes from a module
#
#

# First, import the module:

import classmodule

# Now, we can use the attributes. Classes imported from a module, are module
# attributes:

print ("")

# First, we init the kiki instance from the module's attribute: MasDatosDeGato, which
# is defined inside the module as a class:

kiki = classmodule.MasDatosDeGato()

# Now, we can set values using the methods in the "kiki" object:

kiki.setname("kiki Ratonilla")
kiki.setcolor("Base White with Black Spots")
kiki.caraderaton(True)

# And print the data using the printcolor method in the class object:

kiki.printcolor()

# And, for fun, we can print the module documentation

print (classmodule.__doc__)

print ("")

# END
