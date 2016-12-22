#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 23, 2016
# TigerLinux AT Gmail DOT Com
# Buttons and Message BOXES arrangment - basic
# 
#

import sys

if sys.version_info.major == 2:
    # from Tkinter import Button, mainloop
    # import Tkinter as tkinter
    from Tkinter import *
else:
    # from tkinter import Button, mainloop
    # import tkinter
    from tkinter import *

# In this example, we'll define a class application, and
# use it with 3 buttons, two of them printing messages to
# the console, and the central one exiting the program


# This is our application class:
class MyMainApp:
    # Constructor:
    def __init__(self, windowobj):
        # The button call's uses the "windowobj" instance of class "Tk()".
        # We'll use the fill and expand options and later set the window geometry to 400x300
        Button(windowobj, text='Left',command=(lambda:sys.stdout.write('Left button pressed\n'))).pack(side=LEFT, fill=X, expand=YES)
        Button(windowobj, text='CLICK HERE TO EXIT',command=(lambda:sys.exit("Program ended normally !!"))).pack(side=LEFT, fill=X, expand=YES)
        Button(windowobj, text='Right',command=(lambda:sys.stdout.write('Right button pressed\n'))).pack(side=LEFT, fill=X, expand=YES)

# We init a "Tk" instance:
mainwindow = Tk()
# Add options for the font:
mainwindow.option_add('*font', ('verdana', 12, 'bold'))
# ... and the window title...
mainwindow.title("Main Window")

# Let's set the geometry to 400x200

mainwindow.geometry("400x200")

# Then, we create an instance object with the "mainwindow" class instance of "Tk()" class
# and pass to the MyMainApp class the mainwindow instance which will be used by the buttons
# inside the MyMainApp instance (mydisplay here):

mydisplay = MyMainApp(mainwindow)

# Finally, our message loop:

mainwindow.mainloop()

# END
