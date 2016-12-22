#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 23, 2016
# TigerLinux AT Gmail DOT Com
# Simple password dialog
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

# This example will show a practical use for a dialog box asking for a password
# Includes oldpassword/newpasword/newpasswordagain logic

##########################################################################
##########################################################################
############### GET PASSWORD CLASS DEFINITION BEGINS HERE ################
##########################################################################
##########################################################################
##########################################################################

class GetPassword:
    def __init__(self, windowobj):
        # We define here our old password, newpassword and newpasswordagain attributes:
        self.oldpass=""
        self.newpass1=""
        self.newpass2=""
        # Our class variable "windowobj"
        self.windowobj = windowobj
        # Here, and using grid instead or pack, we proceed to set 3 labels and
        # position in the proper places:
        Label(self.windowobj, text='Enter Old Password:').grid(row=0, sticky=W)
        Label(self.windowobj, text='Enter New Password:').grid(row=1, sticky=W)
        Label(self.windowobj, text='Enter New Password Again:').grid(row=2,sticky=W)
        # Then, our entry boxes, as classes of Entry:
        self.oldpw = Entry(self.windowobj, width = 16, show='*')
        self.newpw1 = Entry(self.windowobj, width = 16, show='*')
        self.newpw2 = Entry(self.windowobj, width = 16, show='*')
        # And set the class instances of our entry boxes in the second column:
        # Note that the entry textboxes are in the same row's as their label's counterparts
        self.oldpw.grid(row=0, column=1, sticky=W)
        self.newpw1.grid(row=1, column=1, sticky=W)
        self.newpw2.grid(row=2, column=1, sticky=W)
        # We'll also define this control attribute for the class
        self.alertmessage="OK"

        # This function will be assigned to the "OK" button:
        def onclickok():
            sys.stdout.write("Called ONCLICK\n")
            # Everytime we press "OK" in the dialog box, we update our password
            # attributes:
            self.oldpass = self.oldpw.get()
            self.newpass1 = self.newpw1.get()
            self.newpass2 = self.newpw2.get()
            sys.stdout.write("P-Old:" + self.oldpass  + "\nP-N-1: " + self.newpass1 + "\nP-N-2: " + self.newpass2 + "\n")

            # This function will be called when in different times:
            # a.- If our old password is blank
            # b.- If our new and new-again passwords does not match
            # c.- If our new/new-again passwords are blank
            # d.- If our password is OK (and also will display the password)
            def checkdialog():
                sys.stdout.write("\nINSIDE CHECKDIALOG\n")

                # This function will be called if we either pressed OK or destroyed
                # the dialog box:
                def ondestroyorok():
                    sys.stdout.write("Dialog Destroyed or press OK\n")
                    self.windowobj.deiconify()
                    self.windowobj.focus_set()
                    self.newalert.destroy()
                    return

                # We proceed to create a new window, child of the main dialog box:
                self.newalert=Toplevel(self.windowobj)
                # disallow resize
                self.newalert.resizable(0,0)
                # And label it with the proper message from "self.alertmessage" attribute
                # This alert message will change depending of our situation (blank password, etc.):
                Label(self.newalert,text=self.alertmessage).pack(pady=10)
                # Then, we hid the parent window
                self.windowobj.withdraw()
                # Define our protocol if we are deleted !
                self.newalert.protocol('WM_DELETE_WINDOW', ondestroyorok)

                # And, define our protocol if we click on OK:
                Button(self.newalert, text="OK", command = ondestroyorok).pack(pady=20,padx=20,side=TOP)

            # Here, we check our password conditions (blank, non matching, etc.):
            if self.newpass1 != self.newpass2:
                self.alertmessage = "Password does not match"
                sys.stdout.write("Not matching passwords\n" + "pass1: " + self.newpass1 + "\npass2: " + self.newpass2)
            elif self.newpass1 == "" or self.newpass2 == "":
                self.alertmessage = "New Password cannot be BLANK"
                sys.stdout.write("New Password - pass: " + self.newpass1 + " " + self.newpass2 + "\n")
            else:
                self.alertmessage="OK"

            if self.oldpass == "":
                self.alertmessage = "Old password cannot be BLANK"

            # Then, if the alert message is NO OK (bad password, etc.), we call
            # the checkdialog method
            if self.alertmessage != "OK":
                checkdialog()
                sys.stdout.write("Called alert dialog!!\n")
                sys.stdout.write("Old Password: " + self.oldpass + "\n")
                sys.stdout.write("New Password - pass: " + self.newpass1 + " " + self.newpass2 + "\n")
                return

            # If our password is OK, then we call checkdialog with the proper message:

            self.alertmessage = "Your new password is: " + self.newpass2
            checkdialog()

            sys.stdout.write("\nREADY HERE !!\n\nOld Password: " + self.oldpass + "\n")
            sys.stdout.write("New Password - pass: " + self.newpass2 + "\n")

        # If we destroyed our main window, of pressed EXIT button, we exit normally:
        def onclickcancelordestroy():
            sys.exit("Program ended normally by user CANCEL request !!")

        # We define our protocol in case of main window destruction:

        windowobj.protocol('WM_DELETE_WINDOW', onclickcancelordestroy)

        # And finally, our two buttons. The "OK" will call "onclickok" method/function inside
        # the class
        # The "EXIT" button will just exit the program !.
        Button(windowobj, text="OK", command = onclickok).grid(row = 3, column= 0)
        Button(windowobj, text="EXIT", command = onclickcancelordestroy).grid(row = 3, column= 1)
        
##########################################################################
##########################################################################
################ GET PASSWORD CLASS DEFINITION ENDS HERE #################
##########################################################################
##########################################################################
##########################################################################
        


# We init a "Tk" instance:
mainwindow = Tk()
# Add options for the font:
mainwindow.option_add('*font', ('serif', 12, 'bold'))
# ... and the window title...
mainwindow.title("Enter New Password")
# Get rid of resize controls
mainwindow.resizable(0,0)

# Then, we create an instance object with the "mainwindow" class instance of "Tk()" class
# and pass to the MyMainApp class the mainwindow instance which will be used by the buttons
# inside the MyMainApp instance (mydisplay here):

# mydisplay = MyMainApp(mainwindow)
mydisplay = GetPassword(mainwindow)

# Finally, our message loop:

mainwindow.mainloop()

# END
