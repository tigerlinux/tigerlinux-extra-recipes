#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 19, 2016
# TigerLinux AT Gmail DOT Com
# More cases of exception handling
#
#

print ("")

# let's see another type of exception handling, this time
# with try/finally combo:

def mylistvalue1(mylist,myindex):
    mymessage = "Code ran OK !!"
    try:
        return mylist[myindex]
    except IndexError:
        mymessage = "Ohh crap !!. We broke python again !!"
        return -1
    finally:
        print (mymessage)


# Define a list and use it in the function:

list1 = [ 1, 2, 3, 4 ]

print ("My list is: ", list1)

print ("")
print (mylistvalue1(list1,3))
print ("")
print (mylistvalue1(list1,99))
print ("")

# In our mylistvalue1 function, if we cause an Index Error, the variable
# "mymessage" changes from it's original "Code ran OK" to "Ohh crap...."
# Then, no matter how the code ends (with or without indexerror), the
# "finally" is called to print our message !.

# Now, let's see another way to do the things: With try/except/else. Let's
# define the function:

def mylistvalue2(mylist,myindex):
    mymessage = "No exception ocurrences detected"
    try:
        myvalue = mylist[myindex]
        if myvalue < 0:
            raise ValueError
    except IndexError:
        mymessage = "Ohhh well... nothing's perfect !!. Index out or range !!"
        print (mymessage)
        return -1
    except ValueError:
        mymessage = "Ehhh... negative number detected !!"
        print (mymessage)
        return -99
    except:
        mymessage = "Ehh... well... generic error detected !!"
        print (mymessage)
        return -77
    else:
        print (mymessage)
        return myvalue

# And again

list2 = [ 6, 5, 4, 3, 2, 1, 0, -1, -2, -3 ]

print ("")
print (mylistvalue2(list2,1))
print ("")
print (mylistvalue2(list2,99))
print ("")
print (mylistvalue2(list2,8))
print ("")

# The last block work's this way: The "try" will run the code, if an exception
# happens, it's intercept the specific exception (multiple except's can be used)
# If no exception is caught, then the "else" code is exec !.

# Now, everything combined: try/except/else/finally:

def mylistvalue3(mylist,myindex):
    try:
        myvalue = mylist[myindex]
        if myvalue < 0:
            raise ValueError
    except IndexError:
        mymessage = "Index out of range"
        myvalue = -1
    except ValueError:
        mymessage = "Negative number detected"
        myvalue = -99
    except:
        mymessage = "Uncategorized error detected"
        myvalue = -77
    else:
        mymessage = "No exceptions ocurrences detected"
    finally:
        print (mymessage)
        return myvalue

# And...

list3 = [ 6, 5, 4, 3, 2, 1, 0, -1, -2, -3 ]

print ("")
print (mylistvalue3(list3,1))
print ("")
print (mylistvalue3(list3,99))
print ("")
print (mylistvalue3(list3,8))
print ("")

# This function is a more poslished sample, using try, multiple except
# calls for different situations, and else, and a finally.
# If the "try" does OK, it calls the "else", then, the "finally" part.
# If the "try" originates any exception, the proper "except" is reached, then,
# the "finally" is called.
# No matter if the "try" causes an exception of not, the "finally" always
# get's executed.
# For this kind of exception handing, the flow is:
# TRY -> EXCEPT -> ELSE -> FINALLY

print ("")
#END
