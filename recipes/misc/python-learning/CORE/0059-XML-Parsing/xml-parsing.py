#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 20, 2016
# TigerLinux AT Gmail DOT Com
# XML Parsing example
#
#

print ""

# Let's play with some XML parsing

# First, let's import the library we are going to use:

import re

# And, define our xml file:

xmlfile = "myxmlfile.xml"

# Let's open the file using a with/as combo:

with open(xmlfile,"r") as myfile:
    mytext = myfile.read()
    # Let's print our file, just for reference:
    print mytext
    print ""
    # The findall method will help us here to find
    # specific nodes in the "mytext" string
    found = re.findall( "<catname>(.*)</catname>", mytext  )
    # Then, let's print our ocurrences for the nodes we are
    # looking for:
    for mycatname in found:
        print "The cat name in the XML is: ", mycatname

print ""

# Let's use now another library:

from xml.dom.minidom import parse, Node

# the method "parse" method will open the file and parse it:

myxmlparsed = parse(xmlfile)

# Then, begin the parsing:
# The first loop run trough all nodes with a "<catname>" tag using
# object.getElementsByTagName("tagname") method
for firstnode in myxmlparsed.getElementsByTagName('catname'):
    # Here, we extract the childnodes in the "firstnode" object
    # by calling the object.childNodes attribute. This will give us
    # the <catname>, CAT NAME, </catname>
    for secondnode in firstnode.childNodes:
        # And, if the nodeType is text, not tag, we'll print
        # the object.data attribute, which will give us the actual
        # data inside <catname></catname> node
        if secondnode.nodeType == Node.TEXT_NODE:
            print "The cat name in the XML is: ", secondnode.data

print ""

# Annnddd... another way to kill a cat:

from xml.etree.ElementTree import parse

# Open the xml and retrieve all structure in it:
xmlstruct = parse(xmlfile)

# A single loop solve all things:
for mytext in xmlstruct.findall("catname"):
    print "The cat name in the XML is: ", mytext.text


print ""
# END
