/**************************************
            Pruebas de Literales
 Todas las instrucciones
 Caso Load USE
**************************************/
LUI R0, 0
LUI R1, 0
LUI R2, 0
LUI R3, 0
LUI R4, 0
LUI R5, 0
LUI R6, 0
LUI R7, 0
LUI R8, 0
LUI R9, 0
LUI R10, 0
LUI R11, 0
LUI R12, 0
LUI R13, 0
LUI R14, 0
LUI R15, 0
LUI R16, 0
LUI R17, 0
LUI R18, 0
LUI R19, 0
LUI R20, 0
LUI R21, 0
LUI R22, 0
LUI R23, 0
LUI R24, 0
LUI R25, 0
LUI R26, 0
LUI R27, 0
LUI R28, 0
LUI R29, 0
LUI R30, 0
LUI R31, 0
// r0 = 0 Y R1 TODO A 1
NOR R1, R1, R1
SB  R1, 0(R0)
SH  R1, 4(R0)
SW  R1, 8(R0)
LB  R2, 0(R0)
LBU R3, 0(R0)
LH  R4, 4(R0)
LHU R5, 4(R0)
LW  R6, 8(R0)
ADDU R7, R6 , R0












// en 47 satura, ultimo numero valido en la serie para 32 bits
// Fibonacci r0=0, r1=1, r2 result, -> Fibo con branch
//    XOR $r4, $r4, $r4              //XOR rd, rs, rt  Clear R4
//    XOR $r5, $r5, $r5              //XOR rd, rs, rt  Clear R5
//    ADDI $r5, $r5, 7            // f(7) = 21
//fibo:
//    ADDU $r2, $r0, $r1             // ADDU rd, rs, rt
//    ADDI $r0, $r1, 0              //ADDI rt, rs, inmediate
//    ADDI $r1, $r2, 0
//    ADDI $r4, $r4, 1
//   BNE  $r4, $r5, fibo      //BEQ rs, rt, offset
// jump 4ever -> j 3 = 00001000000000000000000000000011
// jal 3            ->  00001100000000000000000000000011001100000000000000000000000011
