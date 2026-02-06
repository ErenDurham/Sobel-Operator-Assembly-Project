# Sobel filter of a 5x5 image

.data
a:      .word 10, 9, 9, 4, 0
        .word 0, 6, 6, 2, 2
        .word 5, 9, 8, 4, 3
        .word 7, 5, 5, 4, 3
        .word 8, 10, 8, 5, 0
gx:     .word -1, 0, 1
        .word -2, 0, 2
        .word -1, 0, 1
gy:     .word 1, 2, 1
        .word 0, 0, 0
        .word -1, -2, -1
c:      .word 0, 0, 0
        .word 0, 0, 0
        .word 0, 0, 0

.text
.globl main

# Basic logic:
# gx = sum( A[i+u][j+v] * Gx[u][v] )
# gy = sum( A[i+u][j+v] * Gy[u][v] )
# C[i][j] = Gx + Gy

# t0: i
# t1: j 
# t2: k
# t5: u 
# t6: v
# s0: base address of a
# s2: base address of Gx
# s3: base address of Gy
# s4: base address of c
# s11: Gx accumulation
# s9:  Gy accumulation
# s6:  weight value from current gx
# s10: weight value from current gy
# s8:  value of A[i+u][j+v]
# s7:  memory address for array indexing
# s1:  gx + gy
# s5:  temporary general purpose reg


main:
    # intialize arrays
    lui  s0, %hi(a)
    addi s0, s0, %lo(a)
    
    lui  s2, %hi(gx)
    addi s2, s2, %lo(gx)
    
    lui  s3, %hi(gy)
    addi s3, s3, %lo(gy)
    
    lui  s4, %hi(c)
    addi s4, s4, %lo(c)
    
    addi t0, x0, 0 # initialize i
row_loop:
    addi t1, x0, 0 # initialize j
col_loop:
    addi t2, x0, 0 # initialize k
    addi t3, x0, 0 # gx
    addi t4, x0, 0 # gy
    addi t5, x0, 0 # initialize u
    addi t6, x0, 0 # initialize v
    addi s11, x0, 0   # gx_sum
    addi s9,  x0, 0   # gy_sum
G_loop:
    # Obtaining A[i+u][j+v] --------------------
    add s7, t0, t5 # t7 = i + u
    add s8, t1, t6 # t8 = j + v
    
    # Now to multiply t7 * 5
    addi s10, x0, 5 # intitialize 5
    addi s5, s7, 0
    slli s7, s7, 2 # t7 = t7 * 4
    add s7, s7, s5 # t7 = t7*5
    
    add s10, s7, s8 # obtain the final element index
    slli s10, s10, 2 # off set by four bytes for the byte address
    add s7, s10, s0 # adding the byte address and the starting address of the array to get the actual address
    lw s8, 0(s7) # s8 holds the value of A[i+u][j+v]
    
    # Now to find Gx[k] and Gy[k] and multiply to corresponding values of A -----------
    slli s5, t2, 2 # shift to next point in arr
    add s5, s2, s5 # add base address of Gx to get current gx
    lw s6, 0(s5) # get value gx (s6)
    
    slli s5, t2, 2 # shift to next point in arr
    add s5, s3, s5 # add base address of Gy
    lw s10, 0(s5) # s10 is value of current gy
    
    # Now we mul gx * A[i+u][j+v], which is s6 * s8
    
    # Gx and Gy can either be -2, -1, 0, 1, or 2. So check which value it is
check_gx:
    
    addi s7, x0, 1
    beq s6, s7, xone_sob
    
    addi s7, x0, -1
    beq s6, s7, xneg_one_sob
    
    addi s7, x0, 2
    beq s6, s7, xtwo_sob
    
    addi s7, x0, -2
    beq s6, s7, xneg_two_sob
    
    beq s6, x0, xzero_sob
    
xzero_sob: # multiplying by 0, so the result is adding by 0
    add s11, s11, x0
    jal x0, check_gy
    
xone_sob: # Result is just A[i+u][j+v]
    add s11, s11, s8
    jal x0, check_gy

xneg_one_sob:
    sub s11, s11, s8 # makes result -gx
    jal x0, check_gy
    
xtwo_sob:
    slli s5, s8, 1 # mult by two with bit shifting
    add s11, s5, s11
    jal x0, check_gy

xneg_two_sob:
    slli s5, s8, 1
    sub s11, s11, s5 # makes result -2gy
    jal x0, check_gy
    
check_gy:
    addi s7, x0, 1
    beq s10, s7, yone_sob
    
    addi s7, x0, -1
    beq s10, s7, yneg_one_sob
    
    addi s7, x0, 2
    beq s10, s7, ytwo_sob
    
    addi s7, x0, -2
    beq s10, s7, yneg_two_sob
    
    beq s10, x0, yzero_sob

yzero_sob: # multiplying by 0, so the result is 0
    add s9, s9, x0
    jal x0, cont
    
yone_sob: # Result is just A[i+u][j+v]
    add s9, s8, s9
    jal x0, cont

yneg_one_sob:
    sub s9, s9, s8 # makes result -A[i+u][j+v]
    jal x0, cont
    
ytwo_sob:
    slli s5, s8, 1 # mult by two with bit shifting
    add s9, s5, s9
    jal x0, cont

yneg_two_sob:
    slli s5, s8, 1
    sub s9, s9, s5 # makes result -2gy
    jal x0, cont 

cont:
    addi t2, t2, 1 # Update k
    addi t6, t6, 1 # Update v
     
    # Check if end of row is met
    addi s1, x0, 3 # store 3 to compare to v
    bne t6, s1, continue # check if v == 3 (end of row)
    addi t6, x0, 0 # make v = 0 to move start of row
    addi t5, t5, 1 # and update u to move down
    
    bne t5, s1, continue # Now check if u == 3 (end of window)
    addi t5, x0, 0 # reset u
    addi t6, x0, 0 # reset v
continue:
   addi s5, x0, 9
   blt t2, s5, G_loop
   add s1, s11, s9 # obtain Gx + Gy
   
   # Now, to get C[i][j] to store the value of s1
   # Find C[i][j] = i * 3 + j
   slli s5, t0, 1 # i*2
   add s5, s5, t0  # (i*2)+i = i*3
   add s5, s5, t1 # (i*3) + j
   slli s5, s5, 2 # shift for byte address
   add s5, s5, s4 # add base address of C to get value
   sw s1, 0(s5) # save value into C[i][j]
   
   # update j
   addi t1, t1, 1
   addi s7, x0, 3
   blt t1, s7, col_loop
   
   # update i
   addi t0, t0, 1
   blt t0, s7, row_loop

done:
    addi t0, x0, 0
    lui  t1, %hi(c)
    addi t1, t1, %lo(c)
    
print_loop:
    lw   a0, 0(t1)
    addi a7, x0, 1
    ecall
    
    addi a0, x0, 32
    addi a7, x0, 11
    ecall
    
    addi t1, t1, 4
    addi t0, t0, 1
    
    # Check if end of row (every 3 elements)
    addi t6, x0, 3
    blt  t0, t6, check_done
    beq  t0, t6, print_newline
    addi t6, x0, 6
    beq  t0, t6, print_newline
    jal x0, check_done
    
print_newline:
    addi a0, x0, 10
    addi a7, x0, 11
    ecall
    
check_done:
    addi t6, x0, 9
    blt  t0, t6, print_loop
    
    addi a7, x0, 10
    ecall
