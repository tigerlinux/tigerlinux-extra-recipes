#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 22, 2016
# TigerLinux AT Gmail DOT Com
# TKInter basic message box that prints some messages to the text console
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
        text ='Press me please !!',
        command=(lambda:sys.stdout.write('I AM A MESSAGE\n'))
    )
mytk.pack()
mainloop()

# END
