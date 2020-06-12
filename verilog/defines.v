/* ----------  DECODE STAGE ------------------ */
`define DEC_EXT_SING        1'b0
`define DEC_EXT_ZEROPAD     1'b1
/* ---------- EXECUTE STAGE ------------------ */

`define SLL         6'b000000  // Left  Shift i_dataRT shamt  
`define SRL         6'b000010  // Right Shift i_dataRT shamt (insertando ceros) L de logic
`define SRA         6'b000011  // Right Shift i_dataRT shamt (Aritmetico, conservando el sig)
`define SLLV        6'b000100  // Left  Shift i_dataRT << i_dataRS
`define SRLV        6'b000110  // Right Shift i_dataRT >> i_dataRS (insertando ceros) L de logic
`define SRAV        6'b000111  // Right Shift i_dataRT >> i_dataRS (conservando signo)
`define ADD         6'b110001
`define ADDU        6'b100001  // Add unsigned
`define SUBU        6'b100011  // rs - rt (signed obvio)
`define AND         6'b100100
`define OR          6'b100101
`define XOR         6'b100110
`define NOR         6'b100111
`define SLT         6'b101010
`define SHIFTLUI    6'b101011

/* execute control position and values */
`define EXE_ALUOP_ADD        3'b000
`define EXE_ALUOP_SUB        3'b001
`define EXE_ALUOP_FUNC       3'b010
`define EXE_ALUOP_AND        3'b011
`define EXE_ALUOP_OR         3'b100
`define EXE_ALUOP_XOR        3'b101
`define EXE_ALUOP_SHIFTLUI   3'b110
`define EXE_ALUOP_SLTI       3'b111

`define EXE_ALUSRC_RT      1'b0
`define EXE_ALUSRC_LITERAL 1'b1


`define EXE_REGDEST_RT     1'b0
`define EXE_REGDEST_RD     1'b1

`define EXE_BRACH_NONE     2'b00
`define EXE_BRACH_EQ       2'b01
`define EXE_BRACH_NE       2'b10

`define EXE_JUMP_NONE      3'b000
`define EXE_JUMP_J         3'b001
`define EXE_JUMP_JAL       3'b010
`define EXE_JUMP_JR        3'b011
`define EXE_JUMP_JALR      3'b100

`define NB_ALU_OP           3
`define NB_REG_DEST         1
`define NB_ALU_SRC          1
`define NB_IS_BRANCH        2
`define NB_JUMP_TYPE        3
                    

`define POS_EXE_REGDEST         0
`define POS_EXE_ALUOP       `POS_EXE_REGDEST  + `NB_REG_DEST 
`define POS_EXE_ISBRANCH    `POS_EXE_ALUOP    + `NB_ALU_OP
`define POS_EXE_ALUSRC      `POS_EXE_ISBRANCH + `NB_IS_BRANCH
`define POS_EXE_JUMP        `POS_EXE_ALUSRC   + `NB_ALU_SRC

// Control exe reg
`define NB_EXE_CTRL `NB_ALU_OP + `NB_REG_DEST + `NB_ALU_SRC + `NB_IS_BRANCH + `NB_JUMP_TYPE

/* ---------------- MEM STAGE ------------------ */

`define NB_MEM_RDWR     2
`define NB_MEM_BYENB    2 
`define NB_MEM_EXTSIG   2

`define POS_MEM_RDWR    0
`define POS_MEM_BYENB   `POS_MEM_RDWR  + `NB_MEM_RDWR    
`define POS_MEM_EXTSIG  `POS_MEM_BYENB + `NB_MEM_BYENB

`define MEM_BYENB_HALF   2'b00
`define MEM_BYENB_BYTE   2'b01
`define MEM_BYENB_WORD   2'b11

`define MEM_EXTEND_NONE  2'b00
`define MEM_EXTEND_BYTE  2'b01
`define MEM_EXTEND_HALF  2'b10

`define MEM_NONE         2'b00
`define MEM_READ         2'b10
`define MEM_WRITE        2'b01

`define NB_MEM_CTRL `NB_MEM_RDWR + `NB_MEM_BYENB + `NB_MEM_EXTSIG



/* ---------- WRITE BACK STAGE ------------------ */



/*  writeback position and values  */
`define WRB_USE_ALU         1'b0
`define WRB_USE_MEM         1'b1
`define WRB_READ            1'b0
`define WRB_WRITE           1'b1

`define NB_WRB_WRITEENB       1
`define NB_WRB_MEM2REG        1

`define POS_WRB_WRITEENB       0
`define POS_WRB_MEM2REG        `NB_WRB_WRITEENB + `POS_WRB_WRITEENB

`define NB_WRB_CTRL `NB_WRB_WRITEENB + `NB_WRB_MEM2REG


/* ---------- FORDWARING UNIT  ------------------ */

`define NB_FORWARDING_SELECTOR      2
`define FORWARDING_SEL_RF           2'b00
`define FORWARDING_SEL_EXE          2'b01
`define FORWARDING_SEL_MEM          2'b10
