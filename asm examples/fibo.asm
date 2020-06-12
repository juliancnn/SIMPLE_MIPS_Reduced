// en 47 satura, ultimo numero valido en la serie para 32 bits
// Fibonacci r0=0, r1=1, r2 result, -> Fibo con branch
    XOR r4, r4, r4              //XOR rd, rs, rt  Clear R4
    XOR r5, r5, r5              //XOR rd, rs, rt  Clear R5
    ADDI r5, r5, 'd7            // f(7) = 21 
fibo:
    ADDU r2, r0, r1             // ADDU rd, rs, rt
    ADDI r0, r1, 0              //ADDI rt, rs, inmediate
    ADDI r1, r2, 0
    ADDI r4, r4, 'd1
    BNE  r4, r5, fibo (-5?)     //BEQ rs, rt, offset
// jump 4ever -> j 3 = 00001000000000000000000000000011
// jal 3            ->  00001100000000000000000000000011



00000000100001000010000000100110
00000000101001010010100000100110
00100000101001010000000000000111 
00000000000000010001000000100001
00100000001000000000000000000000
00100000010000010000000000000000
00100000100001000000000000000001
00010100100001011111111111111011
