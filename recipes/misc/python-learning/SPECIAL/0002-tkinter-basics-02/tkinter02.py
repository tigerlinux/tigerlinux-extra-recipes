#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 22, 2016
# TigerLinux AT Gmail DOT Com
# TKInter basic message box that exits the program when pressed
# 
#

import sys

if sys.version_info.major == 2:
    from Tkinter import Button, mainloop
    # import Tkinter as tkinter
else:
    from tkinter import Button, mainloop
    # import tkinter

mytk = Button(
        text ='Press me to exit please !!',
        command=(lambda:sys.exit("Program ended normally !!"))
        )
mytk.pack()
mainloop()

# END
