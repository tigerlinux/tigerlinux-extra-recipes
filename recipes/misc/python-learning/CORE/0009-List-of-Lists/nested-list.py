#!/usr/bin/env python
#
# By Reynaldo R. Martinez P.
# Sept 12, 2016
# TigerLinux AT Gmail DOT Com
# Nested List
#
#

# We can define a list-of-lists, what's constitutes a "matrix" in the "real world" (mmm a movie comes to my mind...):

mymatrix = [ [1,2,3],
             [4,6,7],
             [8,9,10]]

print ( "This is my list-of-lists: " + str(mymatrix) )
print ( "In matrix form: \n\n" + str(mymatrix[0]) + "\n" + str(mymatrix[1]) + "\n" + str(mymatrix[2]) + "\n" )

# We can get specific items into this list-of-lists:

print ( "This is the first row of my matrix: " + str(mymatrix[0]) )

print ( "This is the second element of the third row of my matrix: " + str(mymatrix[2][1]) )

# We can manipulate thins in order to get specific items. Sample here, we use a for-loop
# that will give us the numbers in the second column (index 1):

print ( "The value of the items in the second column are: " + str( [myrow[1] for myrow in mymatrix]  ) )

# We can even do more complicated things. Here, we filter out odd numbers using the module operator:
# NOTE: Just to remember basic math lessons from school: The "module" of the division of any number and "2" is always "0"

print ( "The value of the even numbers in the second column are: " + str( [ myrow[1] for myrow in mymatrix if myrow[1] % 2 == 0  ] ) )

# We can manipulate our exit more and more. This time, we will multiple times 4 the actual value obtained:

print ( "The values of the items in the second column, multipled by 4 are: " + str( [ myrow[1] * 4 for myrow in mymatrix ] ) )

# We can obtain a diagonal of our matrix. This mean's obtaining numbers 1, 4 and 8:
# NOTE: NW = North West, SE = South East... Just in case ! ;-)

print ( "The \"NW\" to \"SE\" diagonal of our matrix is: " + str( [ mymatrix[i][i] for i in [0,1,2] ] ) )

# We can create a LIST based on the operation in a String:

mystring1 = "rayada"
mynewlist = [ char * 3 for char in mystring1 ]

print ( "The original string was \"" + mystring1 + "\" and this is a new list: " + str(mynewlist) )

# More operations.... From the original matrix, let's use a function to sum each row, this time using list(map):

mysumrow = list(map(sum, mymatrix))

print ( "The sum of every row from the matrix " + str(mymatrix) + " is: " + str(mysumrow) )

# And we can do the same for columns, but a little more complex:

mysumcol = list(map(sum, ( ([myrow[index] for myrow in mymatrix]) for index in range(0,len(mymatrix[0])) ) ) )

print ( "The sum of every column from the matrix " + str(mymatrix) + " is: " + str(mysumcol) )

# End
