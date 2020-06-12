`timescale 1ns / 100ps
// @TODO Revisar los branch signados, hacer TB, con sumas y RESTAS
// @TODO Despues hay que hacer lo del jump para ajustar el alu control a sumas
// @TODO Par el jump, ponemos un mux a la salida de la alu, con el PC8 o la salida de la alu
//       Agregar un bit mas de control, ala etapa de exe

module execute
#(
    parameter N_REG            =             32,
    parameter _NB_INDEX_REG     =  $clog2(N_REG),
    parameter NB_SHAMT         =              5,
    parameter NB_FUNC          =              6,
    parameter NB_DATA          =             32,
    parameter NB_PC            =             32,
    parameter NB_ADDR_INDEX    =             26

)
(
    input   wire                               i_clk,
    input   wire                               i_rst,
    input   wire                               i_pipe_enabled,
    
    input   wire   [`NB_EXE_CTRL   - 1 : 0]     i_control_exe,   // ctl
    input   wire   [`NB_MEM_CTRL   - 1 : 0]     i_control_mem,   // ctl
    input   wire   [`NB_WRB_CTRL   - 1 : 0]     i_control_wb,    // ctl
    
    input   wire   [NB_DATA       - 1 : 0]     i_signed_literal,
    input   wire   [NB_FUNC       - 1 : 0]     i_func,
    input   wire   [NB_SHAMT      - 1 : 0]     i_shift_amount,
    input   wire   [NB_DATA       - 1 : 0]     i_data_rs,
    input   wire   [NB_DATA       - 1 : 0]     i_data_rt,
    
    input   wire   [NB_ADDR_INDEX  - 1 : 0]    i_addr_index,
    input   wire   [NB_PC         - 1 : 0]     i_pc_plus4,
    input   wire   [_NB_INDEX_REG - 1 : 0]     i_index_reg_rt,
    input   wire   [_NB_INDEX_REG - 1 : 0]     i_index_reg_rd, 
    
    input  wire  [`NB_FORWARDING_SELECTOR - 1 : 0]  i_fwd_rs_select,
    input  wire  [`NB_FORWARDING_SELECTOR - 1 : 0]  i_fwd_rt_select,
    // EX/MEM register inside this module
    input  wire  [NB_DATA       - 1 : 0]            i_fwd_wrb_data,
    
         
    output  wire   [`NB_MEM_CTRL   - 1 : 0]     o_control_mem,
    output  wire   [`NB_WRB_CTRL   - 1 : 0]     o_control_wb,
    
    output  wire   [NB_DATA       - 1 : 0]     o_alu_result,
    output  wire   [NB_DATA       - 1 : 0]     o_data_rt,
    output  wire   [_NB_INDEX_REG - 1 : 0]     o_reg_dest,
    
    output  wire   [NB_DATA       - 1 : 0]     o_instr_pc_branch,    // to back <<    
    output  wire                               o_branch_taken,       // to back <<

    output  wire   [NB_PC         - 1 : 0]     o_instr_pc_jump,
    output  wire                               o_jump_taken
    
);

// ----------  output  reg: passthrough ----------------------- 
reg   [`NB_MEM_CTRL   - 1 : 0]        control_mem;
reg   [`NB_WRB_CTRL   - 1 : 0]         control_wb;
reg   [NB_DATA       - 1 : 0]             data_rt;
reg   [_NB_INDEX_REG - 1 : 0]      index_reg_dest;

//---- Wire 4 control
wire   [NB_DATA      - 1 : 0]          alu_sec_op;
wire   [NB_FUNC      - 1 : 0]    control_func_alu;
wire                                alu_zero_flag;

// ---- Alu

wire   [NB_DATA      - 1 : 0]         alu_rs;
wire   [NB_DATA      - 1 : 0]         alu_rt; 
wire   [NB_DATA      - 1 : 0]         alu_result;


//----- Jump control logic
wire    select_alu_result;

// Port 
reg   [NB_DATA      - 1 : 0]              result;



always @(posedge i_clk)
begin
    if (i_rst)
    begin
        control_mem  <=  'd0;
        control_wb   <=  'd0;
        data_rt      <=  'd0;
    end
    else if (i_pipe_enabled)
    begin
        control_mem  <=  i_control_mem;
        control_wb   <=  i_control_wb;
        data_rt      <=  alu_rt;
    end
end

assign o_control_mem = control_mem;
assign o_control_wb  = control_wb;
assign o_data_rt     = data_rt;

always @(posedge i_clk)
begin
    if (i_rst)
        index_reg_dest <= 'd0;
    else if (i_pipe_enabled) 
    begin
        if(i_control_exe[`POS_EXE_JUMP +: `NB_JUMP_TYPE] == `EXE_JUMP_JAL)
            index_reg_dest <= 'd31;
        else if(i_control_exe[`POS_EXE_JUMP +: `NB_JUMP_TYPE] == `EXE_JUMP_JALR)
            index_reg_dest <= i_index_reg_rd;
        else if (i_control_exe[`POS_EXE_REGDEST] == `EXE_REGDEST_RT)
            index_reg_dest <= i_index_reg_rt;
        else
            index_reg_dest <= i_index_reg_rd;
    end
end

assign o_reg_dest = index_reg_dest;


// ---------- PC branch -----------------------


assign o_instr_pc_branch =  $signed(i_pc_plus4) + $signed(i_signed_literal);
assign o_branch_taken = ((i_control_exe[`POS_EXE_ISBRANCH +: `NB_IS_BRANCH] == `EXE_BRACH_EQ)
                        & alu_zero_flag)
                        ? 1'b1
                        : ((i_control_exe[`POS_EXE_ISBRANCH +: `NB_IS_BRANCH] == `EXE_BRACH_NE)
                            & (~alu_zero_flag))
                            ? 1'b1
                            : 1'b0; 



// ---------- PC Jump ----------------------
assign o_instr_pc_jump = (    (i_control_exe[`POS_EXE_JUMP +: `NB_JUMP_TYPE] == `EXE_JUMP_J)
                           || (i_control_exe[`POS_EXE_JUMP +: `NB_JUMP_TYPE] == `EXE_JUMP_JAL)
                         )  
                         ? {2'b00, i_pc_plus4[NB_PC - 1 -: 4],i_addr_index}
                         : alu_rs; 

assign o_jump_taken    =  (i_control_exe[`POS_EXE_JUMP +: `NB_JUMP_TYPE] != `EXE_JUMP_NONE) ? 1'b1 : 1'b0;


// ----------  ALU  -----------------------

assign alu_rs  = (i_fwd_rs_select == `FORWARDING_SEL_EXE )
                  ? result
                  : (i_fwd_rs_select == `FORWARDING_SEL_MEM )
                    ? i_fwd_wrb_data
                    :  i_data_rs;
                    
assign alu_rt  = (i_fwd_rt_select == `FORWARDING_SEL_EXE )
                  ? result
                  : (i_fwd_rt_select == `FORWARDING_SEL_MEM )
                    ? i_fwd_wrb_data
                    :  i_data_rt;
                                        
assign alu_sec_op   = (i_control_exe[`POS_EXE_ALUSRC] == `EXE_ALUSRC_LITERAL) 
                        ? i_signed_literal
                        : alu_rt;  // Mux seg operador alu

assign o_alu_result = result;

assign select_alu_result =  (    (i_control_exe[`POS_EXE_JUMP +: `NB_JUMP_TYPE] == `EXE_JUMP_JAL)
                              || (i_control_exe[`POS_EXE_JUMP +: `NB_JUMP_TYPE] == `EXE_JUMP_JALR)
                            )  
                            ? 1'b0 : 1'b1;

always @(posedge i_clk)
begin
    if(i_rst)
        result <= 'd0;
    else if(i_pipe_enabled)
        result <= (select_alu_result) 
                  ?  alu_result
                  :  i_pc_plus4 + 1'b1;
    else
        result <= result;
end

alu
#(
.NB_SHAMT   (NB_SHAMT),
.NB_FUNC     (NB_FUNC),
.NB_DATA     (NB_DATA)
)
u_alu
(
    .i_dataRS           (alu_rs),
    .i_dataRT       (alu_sec_op),
    .i_shamt    (i_shift_amount),
    .i_func   (control_func_alu),
    .o_result       (alu_result),
    .o_zero      (alu_zero_flag)
);


alu_control
#(
    .NB_ALU_OP  (`NB_ALU_OP),
    .NB_FUNC      (NB_FUNC)
)
u_alu_control
(
    .i_alu_op  (i_control_exe[`POS_EXE_ALUOP +: `NB_ALU_OP]),
    .i_func                                    (i_func),
    .o_alu_func                      (control_func_alu)
);

endmodule
