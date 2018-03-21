"""
Program to generate ranges for differentiation.

When run, asks for input on how many samples to generate and what distribution to use. The values used for the normal
distribution are specified in the email given. They can easily be edited in the code if needed.

The program will write the values to the specific file type given.

Additional ideas: Could just generate the range and the mean randomly and then center the mean like that for
the uniform distribution. Similar idea can apply for the gaussian samples.
"""

import numpy as np
import matplotlib.pyplot as plt

num_samples = int(input("Input number of samples to generate for the ranges: "))
type = input("Would you like to use a gaussian? If not, a uniform distribution will be used (yes/no): ")
counter = 0
lower_ps = []
higher_ps = []
new_c = 0
if type.lower() in ["yes", "y"]:
    f = open("gaussian_samples.txt", "w")
    print("Generating Gaussian samples. Lower : mean = 32.5 sd = 16, Upper: mean = 52.5, sd = 20")
    for n in range(num_samples):
        while counter < num_samples:
            while True:
                a = np.random.normal(32.5, 16)
                if not (60 < a or a < 5):
                    break
            while True:
                b = np.random.normal(52.5, 20)
                if not (100 < b or b < 5):
                    break
            if a < b:
                lower_ps.append(a)
                higher_ps.append(b)
                f.write(str(a) + "," + str(b) + "\n")
                counter = counter + 1
            # else:
            #     new_c = new_c +1
            #     print("new c is: "+ str(new_c))

        f.close()
else:
    f = open("uniform_sample.txt", "w")
    print("Generating uniform samples. Lower : 5 to 60, Upper: mean = 5 to 100")
    for n in range(num_samples):
        while counter < num_samples:
            a = np.random.uniform(5, 60)
            b = np.random.uniform(5, 100)
            if a < b:
                lower_ps.append(a)
                higher_ps.append(b)
                f.write(str(a) + "," + str(b) + "\n")
                counter = counter + 1
            # else:
            #     new_c = new_c + 1
            #     print(new_c)
        f.close()

plt.hist(lower_ps, 20)
plt.show()
plt.hist(higher_ps, 20)
plt.show()

