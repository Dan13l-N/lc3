# A small LC3 library
Here are some LC3 routines I wrote in two days. LC3 is a virtual machine with an *extremely* poor instruction set.

Read more about LC3 here: https://en.wikipedia.org/wiki/Little_Computer_3

A web emulator is available here: https://lc3.cs.umanitoba.ca/

## My routines
I've decided to write a couple of simple assembly routines for LC3. This is a *horrible* (imagined) CPU. It has no `or`, `xor` or `sub`. It has *no bit shifts*. It only has a very bare minimum. 

I repeat: no bit shifts.

Of course, this is intentional, it's meant as a teaching device.

I've decided to use the following approach:

* R0, R1... will be used as parameters
* registers R0...R4 not used as parameters won't be touched by the routines; if a function needs them, it will save them
* R5 **won't be saved**, routines will use it for temporaries etc.
* I won't use user stack pointed to by R6, I won't use this register at all
* If my routines call other routines, I will maintain the R7 register

### **itoa(r0, r1)**

The routine converts a number in R1 into an ASCII string, and stores into a buffer which adress is in R1.

Both registers are changed. The buffer must have at least 7 words of room (.blkw 7). The string will be zero-terminated, so it can be used with `puts`.

### **printnum(r0)**

Prints the number in R0 on the console. It's just a thin wrapper around my `itoa` and standard routine `puts`.

### **multiply(r0, r1) -> r0**

The routine multiplies R0 and R1, and returns the result in R0.

### **div_mod(r0, r1) -> r0, r1**

The routine performs a division of R0 and R1. The result is returned as:

R0 = R0 mod R1

R1 = R0 div R1

### **shr(r0, r1) -> r0**

Shifts R0 right by the number of bits in R1, and returns the result in R0.

## Future...
I will expand the library for sure.
I'm thinking about maybe porting Tiny Basic to the LC3 platform.
