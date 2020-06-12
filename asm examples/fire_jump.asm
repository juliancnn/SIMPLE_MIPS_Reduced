// Fibonacci r0=0, r1=1, r2 result, -> Fibo con branch
    XOR r4, r4, r4              //XOR rd, rs, rt  Clear R4
    XOR r5, r5, r5              //XOR rd, rs, rt  Clear R5
    jump loop;
    ADDI r5, r5, 'd45            // f(7) = 21 
fiboFunc:
    ADDU r2, r0, r1             // ADDU rd, rs, rt
    ADDI r0, r1, 0              //ADDI rt, rs, inmediate
    return;
    ADDI r1, r2, 0
loop:
    call fiboFunc
    ADDI r4, r4, 'd1
    BNE  r4, r5, loop           //BEQ rs, rt, offset
