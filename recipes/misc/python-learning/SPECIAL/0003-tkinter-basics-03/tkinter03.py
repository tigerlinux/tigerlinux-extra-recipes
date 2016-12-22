#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Month day, year
# TigerLinux AT Gmail DOT Com
# TGENERIC MESSAGE
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

# Here, we'll explore different entities in tkinter library:

# We define here our mainwindow object:
mainwindow = Tk()

# The title for all our windows:
mainwindow.title('THE WORLD IS CRAZY')

# Here, we set the label of the mainwindow window:

Label(mainwindow, text="This is the main application Window !!\nKill it and everything else will close !!").pack(pady=10)

# Another window, which is a child of the main window:
window01 = Toplevel(mainwindow)

# And set it's label:
Label(window01, text="This is a child Window").pack(padx=10, pady=10)

# Another one. We set it's label and made it transient of our mainwindow:
window02 = Toplevel(mainwindow)
Label(window02, text="This is another child Window, transient class").pack(padx=10, pady=10)
window02.transient(mainwindow)

# Another child of the main window, whithout decorations
window03 = Toplevel(mainwindow, borderwidth=5, bg='yellow')
Label(window03, text='No wm decorations', bg='yellow', fg='black').pack(padx=10,pady=10)
window03.overrideredirect(1)
# Let's set the last window geometry
window03.geometry('300x150+150+150')

# Our mainloop - pretty much similar as old messageblock-loop in Windows C programming
mainwindow.mainloop()

# END
