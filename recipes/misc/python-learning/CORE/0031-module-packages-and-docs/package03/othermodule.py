#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 15, 2016
# TigerLinux AT Gmail DOT Com
# Modules - Module file with a function - package version
#
#

# Next is the docstring. For any function or module, the
# first you should include before any statement if the
# docstring !.

"""
This module contain the function "mysquearedlist" which will
get a list of numbers, and return another list with the square
of every number in the original list.

Also, the variable "variable3" with value 777 is included in
the module
"""

# The following declares which variables and functions will
# be exported when the module is called with "*":


__all__ = [ "variable3", "mysquaredlist" ]

# The following variable is internal. Every variable with a "_" in the
# front, is considered local:

_factor = 2

# A function that will square the components of a list:

def mysquaredlist(inlist):
    """
    This function requires only one argument: A list of
    numbers. The result will be another list with the
    squares of every number in the input list
    """
    outlist=[]
    for number in inlist:
        # The actual square. Note the use of the "_factor"
        # internal variable
        outlist.append( number ** _factor)
    return outlist


# And, declare a variable

variable3 = 777

# END
