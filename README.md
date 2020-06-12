# SIMPLE MIPS Reduced


See [minimal mips assembler debugger](https://github.com/juliancnn/minimal_mips_assembler_debugger) first.

### Features

- 100MHz support in basys3 (Without timing problems)
- Debug Unit (Dumps/step/reset) 
- Without support for interruptions and exceptions
- Load program in runtime

### Instrucction set
Instruction behavior and format (for [SIMPLE MIPS Reduced](https://github.com/juliancnn/SIMPLE_MIPS_Reduced)) is the same as specified in the document
[“MIPS® Architecture for Programmers Volume II-A: The MIPS32® Instruction Set Manual”
(Document Number: MD00086 Revision 6.06 December 15, 2016)](https://s3-eu-west-1.amazonaws.com/downloads-mips/documents/MD00086-2B-MIPS32BIS-AFP-6.06.pdf)

You can find it here https://www.mips.com/products/architectures/mips32-2/

 
|            Type      |    instrucction    |    Usage     |
| :-------------------- | :------------------: |------------------ |
 |Type R|SLL|SLL rd, rt, sa|
 |Type R|SRL|SRL rd, rt, sa|
 |Type R|SRA|SRA rd, rt, sa|
 |Type R|SLLV|SRA rd, rt, rs|
 |Type R|SRLV|SRLV rd, rt, rs|
 |Type R|SRAV|SRAV rd, rt, rs|
 |Type R|ADDU|ADDU rd, rt, rs|
 |Type R|SUBU|SUBU rd, rs, rt|
 |Type R|AND|AND rd, rs, rt|
 |Type R|OR|OR rd, rs, rt|
 |Type R|XOR|XOR rd, rs, rt|
 |Type R|NOR|NOR rd, rs, rt|
 |Type R|SLT|SLT rd, rs, rt|
 |Type I|LB|LB rt, offset (base)|
 |Type I|LH|LH rt, offset (base)|
 |Type I|LW|LW rt, offset (base)|
 |Type I|LWU|LWU rt, offset (base)|
 |Type I|LHU|LHU rt, offset (base)|
 |Type I|LBU|LBU rt, offset (base)|
 |Type I|SB|LB rt, offset (base)|
 |Type I|SH|SH rt, offset (base)|
 |Type I|SW|SW rt, offset (base)|
 |Type I|ADDI|ADDI rt, rs, inmediate|
 |Type I|ANDI|ANDI rt, rs, inmediate|
 |Type I|ORI|ORI rt, rs, inmediate|
 |Type I|XORI|XORI rt, rs, inmediate|
 |Type I|LUI|LUI rt, inmediate|
 |Type I|SLTI|SLTI rt, rs, inmediate|
 |Type I|BEQ|BEQ rs, rt, offset|
 |Type I|BNE|BNE rs, rt, offset|
 |Type I|J|J target|
 |Type I|JAL|JAL target|
 |Type J|JR|JR rs|
 |Type J|JALR|JALR rs (rd=31 default); JALR rd, rs|

