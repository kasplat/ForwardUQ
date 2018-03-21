# Author: Kesavan Kushalnagar
# finds the distribution for each node according to what type of tissue they were labelled as for each range.


class node:
    def __init__(self, x_, y_, z_, w_):
        x = x_
        y = y_
        z = z_
        w = w_


with open("va4/VA0042_5G4C_i_reOrder.elem") as f:
    i = 0
    for line in f:
        line = line.split(" ")
        if line[0] == "Tt":  # this line is a node line
            x = line[1]
            y = line[2]
            z = line[3]
            w = line[4]
            node(x, y, z, w)
        else:
            i = i+1
            print(line)
            if i == 3:
                break


