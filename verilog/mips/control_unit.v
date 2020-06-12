`timescale 1ns/100ps
`include "defines.v"


module control_unit
#(
    parameter NB_OPCODE   = 6,
    parameter NB_FUNC     = 6

 )
 (
    input  wire  [NB_OPCODE - 1 : 0]         i_opcode,
    input  wire  [NB_FUNC - 1   : 0]         i_func,
    output wire                              o_ext_sig,
    output wire  [`NB_EXE_CTRL - 1 : 0]      o_exe_ctrl,
    output wire  [`NB_MEM_CTRL - 1 : 0]      o_mem_ctrl,
    output wire  [`NB_WRB_CTRL - 1 : 0]      o_wrb_ctrl
 );

//localparam
localparam NB_MEM_BYTE_ENB    = 4;

localparam FUNC_JR            = 6'b001000;   
localparam FUNC_JALR          = 6'b001001;

// I-types
localparam OPCODE_I_MASK        = 6'b111000;
//Loads
localparam OPCODE_I_LOAD_TYPE   = 6'b100000; // 16-21 (doc drive)
localparam OPCODE_I_LOAD_LB     = 3'b000;
localparam OPCODE_I_LOAD_LH     = 3'b001;
localparam OPCODE_I_LOAD_LW     = 3'b011;
localparam OPCODE_I_LOAD_LBU    = 3'b100;
localparam OPCODE_I_LOAD_LHU    = 3'b101;
localparam OPCODE_I_LOAD_LWU    = 3'b111;
//Stores
localparam OPCODE_I_STORE_TYPE   = 6'b101000; // 16-21 (doc drive)
localparam OPCODE_I_STORE_SB     = 3'b000;
localparam OPCODE_I_STORE_SH     = 3'b001;
localparam OPCODE_I_STORE_SW     = 3'b011;
// Literal
localparam OPCODE_I_LITERAL_LOGIC       = 4'b0011;
localparam I_TYPE_ARITMETIC_AND         = 2'b00;
localparam I_TYPE_ARITMETIC_OR          = 2'b01;
localparam I_TYPE_ARITMETIC_XOR         = 2'b10;
localparam I_TYPE_ARITMETIC_LUI         = 6'b11;
localparam OPCODE_I_TYPE_ARITMETIC_ADD   = 6'b001000;
localparam OPCODE_I_TYPE_ARITMETIC_SLTI  = 6'b001010;
//
localparam OPCODE_I_TYPE_BRANCH_EQ      = 6'b000100;
localparam OPCODE_I_TYPE_BRANCH_NE      = 6'b000101;

localparam OPCODE_I_TYPE_J      = 6'b000010;
localparam OPCODE_I_TYPE_JAL    = 6'b000011;


// Internal Signals

//control
reg                                 exe_alu_src;
reg  [`NB_ALU_OP      - 1 : 0]      exe_alu_op;
reg  [`NB_IS_BRANCH   - 1 : 0]      exe_is_branch; // Asig
wire [`NB_JUMP_TYPE   - 1 : 0]      exe_jump_type; // Asig
reg                                 exe_reg_dest;  // Asig

reg  [`NB_MEM_BYENB   - 1 : 0]      mem_byte_enb;
reg  [`NB_MEM_EXTSIG  - 1 : 0]      mem_ext_sig;
reg  [`NB_MEM_RDWR    - 1 : 0]      mem_write_enb;

reg                                 wrb_mem_to_reg;
reg                                 wrb_write_enb_reg;

//instruction type
wire                                R_type;
wire                                I_type_load;
wire                                I_type_store;
wire                                I_type_aritmetic_logic;
wire                                I_type_artimetic_logic_add;
wire                                I_type_aritmetic_slti;

wire                                I_type_branch_eq;
wire                                I_type_branch_ne;

wire                                I_type_j;
wire                                I_type_jal;

wire                                J_type_jr;
wire                                J_type_jalr;

assign  R_type                      = (i_opcode == 6'b000000) && (i_func != FUNC_JR) && (i_func != FUNC_JALR);
assign  I_type_load                 = ((i_opcode &  OPCODE_I_MASK) == OPCODE_I_LOAD_TYPE);
assign  I_type_store                = ((i_opcode &  OPCODE_I_MASK) == OPCODE_I_STORE_TYPE);
assign  I_type_aritmetic_logic      = (i_opcode[NB_OPCODE -1 -: 4] == OPCODE_I_LITERAL_LOGIC);
assign  I_type_artimetic_logic_add  = (i_opcode ==  OPCODE_I_TYPE_ARITMETIC_ADD);
assign  I_type_aritmetic_slti       = (i_opcode ==  OPCODE_I_TYPE_ARITMETIC_SLTI);

assign  I_type_branch_eq            = (i_opcode == OPCODE_I_TYPE_BRANCH_EQ);
assign  I_type_branch_ne            = (i_opcode == OPCODE_I_TYPE_BRANCH_NE);

assign I_type_j                     = (i_opcode == OPCODE_I_TYPE_J);
assign I_type_jal                   = (i_opcode == OPCODE_I_TYPE_JAL);

assign J_type_jr                    = (i_opcode == 6'b000000) && (i_func == FUNC_JR);
assign J_type_jalr                  = (i_opcode == 6'b000000) && (i_func == FUNC_JALR);

assign exe_jump_type                = (I_type_j)     ? `EXE_JUMP_J
                                      :(I_type_jal)  ? `EXE_JUMP_JAL
                                      :(J_type_jr)   ? `EXE_JUMP_JR
                                      :(J_type_jalr) ? `EXE_JUMP_JALR
                                      : `EXE_JUMP_NONE;


//-------------  PORTS  -----------------------------------
assign o_exe_ctrl [`POS_EXE_ALUSRC   +: `NB_ALU_SRC   ] = exe_alu_src   ;
assign o_exe_ctrl [`POS_EXE_ALUOP    +: `NB_ALU_OP    ] = exe_alu_op    ;
assign o_exe_ctrl [`POS_EXE_ISBRANCH +: `NB_IS_BRANCH ] = exe_is_branch ;
assign o_exe_ctrl [`POS_EXE_REGDEST  +: `NB_REG_DEST  ] = exe_reg_dest  ;
assign o_exe_ctrl [`POS_EXE_JUMP     +: `NB_JUMP_TYPE ] = exe_jump_type ;

assign o_mem_ctrl [`POS_MEM_RDWR     +: `NB_MEM_RDWR  ] = mem_write_enb ;
assign o_mem_ctrl [`POS_MEM_BYENB    +: `NB_MEM_BYENB ] = mem_byte_enb  ;
assign o_mem_ctrl [`POS_MEM_EXTSIG   +: `NB_MEM_EXTSIG] = mem_ext_sig  ;
 
assign o_wrb_ctrl [`POS_WRB_MEM2REG  +: `NB_WRB_MEM2REG  ] = wrb_mem_to_reg;
assign o_wrb_ctrl [`POS_WRB_WRITEENB +: `NB_WRB_WRITEENB ] = wrb_write_enb_reg;

assign  o_ext_sig =  (i_opcode[NB_OPCODE -1 -: 4] == OPCODE_I_LITERAL_LOGIC) ? `DEC_EXT_ZEROPAD : `DEC_EXT_SING;

//exe
always @ (*)
begin
    exe_alu_src   = 0;
    exe_alu_op    = 0;
    exe_reg_dest  = 0;
    exe_is_branch = `EXE_BRACH_NONE;
    if (R_type)
    begin
        exe_alu_src  = `EXE_ALUSRC_RT; 
        exe_alu_op   = `EXE_ALUOP_FUNC; 
        exe_reg_dest = `EXE_REGDEST_RD;
    end
    else if(I_type_load | I_type_store)
    begin
        exe_alu_src  = `EXE_ALUSRC_LITERAL;
        exe_alu_op   = `EXE_ALUOP_ADD; 
        exe_reg_dest = `EXE_REGDEST_RT;
    end
    else if(I_type_aritmetic_logic)
    begin
        exe_alu_src  = `EXE_ALUSRC_LITERAL; 
        exe_reg_dest = `EXE_REGDEST_RT;
        
        case (i_opcode [1:0])
        I_TYPE_ARITMETIC_AND: 
            exe_alu_op   = `EXE_ALUOP_AND;
        I_TYPE_ARITMETIC_OR:
            exe_alu_op   = `EXE_ALUOP_OR;
        I_TYPE_ARITMETIC_XOR:
            exe_alu_op   = `EXE_ALUOP_XOR;
        I_TYPE_ARITMETIC_LUI:
            exe_alu_op   = `EXE_ALUOP_SHIFTLUI;
        endcase
    end
    else if(I_type_artimetic_logic_add)
    begin
        exe_alu_src  = `EXE_ALUSRC_LITERAL; 
        exe_reg_dest = `EXE_REGDEST_RT;
        exe_alu_op   = `EXE_ALUOP_ADD;
    end
    else if(I_type_aritmetic_slti)
    begin
        exe_alu_src  = `EXE_ALUSRC_LITERAL; 
        exe_reg_dest = `EXE_REGDEST_RT;
        exe_alu_op   = `EXE_ALUOP_SLTI;
    end
    else if(I_type_branch_eq)
    begin
        exe_alu_src  = `EXE_ALUSRC_RT; 
        exe_reg_dest = `EXE_REGDEST_RT;
        exe_alu_op   = `EXE_ALUOP_XOR;
        exe_is_branch = `EXE_BRACH_EQ;
    end
    else if(I_type_branch_ne)
    begin
        exe_alu_src  = `EXE_ALUSRC_RT; 
        exe_reg_dest = `EXE_REGDEST_RT;
        exe_alu_op   = `EXE_ALUOP_XOR;
        exe_is_branch = `EXE_BRACH_NE;
    end

    
end


//mem
always @ (*)
begin
    mem_byte_enb  = 0;
    mem_write_enb = `MEM_NONE;
    mem_ext_sig   = 0;
    if (R_type | I_type_aritmetic_logic | I_type_artimetic_logic_add 
               | I_type_aritmetic_slti  | I_type_branch_ne | I_type_branch_eq
               | I_type_j | I_type_jal  | J_type_jr | J_type_jalr)
    begin
        mem_byte_enb  = `MEM_BYENB_WORD;
        mem_write_enb = `MEM_NONE;
        mem_ext_sig   = `MEM_EXTEND_NONE;
    end
    else if(I_type_load)
    begin
        mem_write_enb = `MEM_READ;
        
        // Indican si el load es signado o no, y la cantidad de bytes a leer
        case (i_opcode [2:0])
            OPCODE_I_LOAD_LB:
            begin
                mem_byte_enb  = `MEM_BYENB_BYTE;
                mem_ext_sig   = `MEM_EXTEND_BYTE;
            end
            OPCODE_I_LOAD_LH:
            begin
                mem_byte_enb  = `MEM_BYENB_HALF;
                mem_ext_sig   = `MEM_EXTEND_HALF;
            end 
            OPCODE_I_LOAD_LW:
            begin
                mem_byte_enb  = `MEM_BYENB_WORD;
                mem_ext_sig   = `MEM_EXTEND_NONE;
            end 
            OPCODE_I_LOAD_LBU:
            begin
                mem_byte_enb  = `MEM_BYENB_BYTE;
                mem_ext_sig   = `MEM_EXTEND_NONE;
            end 
            OPCODE_I_LOAD_LHU:
            begin
                mem_byte_enb  = `MEM_BYENB_HALF;
                mem_ext_sig   = `MEM_EXTEND_NONE;
            end 
            OPCODE_I_LOAD_LWU:
            begin
                mem_byte_enb  = `MEM_BYENB_WORD;
                mem_ext_sig   = `MEM_EXTEND_NONE;
            end  
            
        endcase
    end
    else if(I_type_store)
    begin
        mem_write_enb = `MEM_WRITE;
        
        // Indican si el load es signado o no, y la cantidad de bytes a leer
        case (i_opcode [2:0])
            OPCODE_I_STORE_SB:
            begin
                mem_byte_enb  = `MEM_BYENB_BYTE;
                mem_ext_sig   = `MEM_EXTEND_NONE;
            end
            OPCODE_I_STORE_SH:
            begin
                mem_byte_enb  = `MEM_BYENB_HALF;
                mem_ext_sig   = `MEM_EXTEND_NONE;
            end 
            OPCODE_I_STORE_SW:
            begin
                mem_byte_enb  = `MEM_BYENB_WORD;
                mem_ext_sig   = `MEM_EXTEND_NONE;
            end             
        endcase
    end
end


// write back
always @ (*)
begin
    wrb_mem_to_reg    = `WRB_USE_ALU;
    wrb_write_enb_reg = `WRB_READ;
    if (R_type | I_type_aritmetic_logic 
               | I_type_artimetic_logic_add | I_type_aritmetic_slti
               | I_type_jal  | J_type_jalr)
    begin
        wrb_mem_to_reg    = `WRB_USE_ALU;
        wrb_write_enb_reg = `WRB_WRITE; 
    end
    else if(I_type_load)
    begin
        wrb_mem_to_reg    = `WRB_USE_MEM;
        wrb_write_enb_reg = `WRB_WRITE; 
    end
    else if(I_type_store | I_type_branch_ne | I_type_branch_eq
            | I_type_j   | J_type_jr)
    begin
        wrb_mem_to_reg    = `WRB_USE_ALU;
        wrb_write_enb_reg = `WRB_READ; 
    end
end

endmodule
