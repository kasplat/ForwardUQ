
# can change the name of the output file
f = open("samples.txt", "w+")
"""
'i' are the values in the left row
range(5, 62, 2) means that the minimum for the left row is 5, the max for the left row is 62 - step size (it will
not do 62), and the step size (the difference between each entry) is 2.

'j' are the values in the right row. The same logic as for i applies to the range calculations.
"""
for i in (range(0, 62, 2)):
    if i > 100:  # don't go above 100
        i = 100
    for j in range(i + 2, 102, 2):
        if j > 100:  # don't go above 100
            j = 100
        f.write(str(i) + "," + str(j) + "\n")  # can change the delimiter by changing the character in the middle here
