`timescale 1ns / 100ps
`include "defines.v"

// @TODO dsp incluir un archivo para obtener los parametros

module tb_control_unit
#( 
    parameter NB_OPCODE   = 6,
    parameter NB_FUNC     = 6,
    parameter NB_EXE_CTRL = 4,
    parameter NB_MEM_CTRL = 6,
    parameter NB_WRB_CTRL = 2
)();

localparam FUNC_JR            = 6'b001000;   
localparam FUNC_JALR          = 6'b001001;


// Inputs
reg  [NB_OPCODE - 1 : 0]        tb_opcode;
reg  [NB_FUNC - 1 : 0]          tb_func;

// outputs
wire  [NB_EXE_CTRL - 1 : 0]      tb_o_exe_ctrl;
wire  [NB_MEM_CTRL - 1 : 0]      tb_o_mem_ctrl;
wire  [NB_WRB_CTRL - 1 : 0]      tb_o_wrb_ctrl;


//Logic for test
initial
begin
    $display("-- Test for R-Type --");
    $display(`EXE_ALUOP_FUNC);
    tb_opcode = 6'b000000;
    tb_func   = 6'b000000; // Algun R type
    #3 // Que pasa si no un R type? pero un op=0
    tb_func = FUNC_JR;
    #3 // Que pasa si no un R type? pero un op=0
    tb_func = FUNC_JALR;
    // Otro R type
    #3
    tb_func = 'b101010;
    
    
end


// COntrol Unit    
control_unit #() control_tb
(
    .i_opcode(tb_opcode),
    .i_func(tb_func),
    .o_exe_ctrl(tb_o_exe_ctrl),
    .o_mem_ctrl(tb_o_mem_ctrl),
    .o_wrb_ctrl(tb_o_wrb_ctrl)
    
);

endmodule
    
