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
        # This time, we'll create two frames, and arrange our buttons in both frames:
        # Farame 1, from class windowobj:
        frame1=Frame(windowobj)
        Button(frame1, text='LEFT-TOP',command=(lambda:sys.stdout.write('Frame 1, TOP button pressed\n'))).pack(side=TOP, anchor=W, fill=X, expand=YES)
        Button(frame1, text='CLICK HERE TO EXIT',command=(lambda:sys.exit("Program ended normally !!"))).pack(side=TOP, anchor=W, fill=X, expand=YES)
        Button(frame1, text='LEFT-BOTTOM',command=(lambda:sys.stdout.write('Frame 2, BOTTOM button pressed\n'))).pack(side=TOP, anchor=W, fill=X, expand=YES)
        # And, arrange our frame "LEFT"
        frame1.pack(side=LEFT)

        # Second frame:
        frame2=Frame(windowobj)
        Button(frame2, text='Sec-Left',command=(lambda:sys.stdout.write('Frame 2, LEFT button pressed\n'))).pack(side=LEFT)
        Button(frame2, text='Sec-Center',command=(lambda:sys.stdout.write('Frame 2, CENTER button pressed\n'))).pack(side=LEFT)
        Button(frame2, text='Sec-Rigth',command=(lambda:sys.stdout.write('Frame 2, CENTER button pressed\n'))).pack(side=LEFT)
        # And, arrange of frame "LEFT", with 5x5 padding
        frame2.pack(side=LEFT, padx=5, pady=5)

        # General info here: fill=X, fill along "X" axis.. fill=Y, fill aling Y axis.. fill=BOTH.. fill along both X and Y axis

# We init a "Tk" instance:
mainwindow = Tk()
# Add options for the font:
mainwindow.option_add('*font', ('times', 20, 'bold'))
# ... and the window title...
mainwindow.title("Main Window")

# Then, we create an instance object with the "mainwindow" class instance of "Tk()" class
# and pass to the MyMainApp class the mainwindow instance which will be used by the buttons
# inside the MyMainApp instance (mydisplay here):

mydisplay = MyMainApp(mainwindow)

# Finally, our message loop:

mainwindow.mainloop()

# END
