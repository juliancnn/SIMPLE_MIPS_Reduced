`timescale 1ns / 100ps
`include "defines.v"

module alu_control
#(
    parameter NB_ALU_OP  = 3,
    parameter NB_FUNC = 6
)
(
    input   wire [NB_ALU_OP  - 1 : 0]   i_alu_op,
    input   wire [NB_FUNC - 1 : 0]   i_func,
    output  reg  [NB_FUNC - 1 : 0]   o_alu_func
);

/* crt alu codes */
/*
localparam EXE_ALUOP_ADD      = 3'b000;
localparam EXE_ALUOP_SUB      = 3'b001; // resta
localparam EXE_ALUOP_FUNC     = 3'b010;
localparam EXE_ALUOP_AND      = 3'b011;
localparam EXE_ALUOP_OR       = 3'b100;
localparam EXE_ALUOP_XOR      = 3'b101;
*/
/* ALU CODES */
/*
localparam SUBU   = 6'b100011;  // rs - rt (signed obvio)
localparam AND    = 6'b100100;
localparam OR     = 6'b100101;
localparam XOR    = 6'b100110;
localparam NOR    = 6'b100111;
localparam SLT    = 6'b101010;
localparam ADD    = 6'b110001;
*/

always @(*)
begin
    case (i_alu_op)
        `EXE_ALUOP_ADD      :  o_alu_func =      `ADD;
        `EXE_ALUOP_SUB      :  o_alu_func =     `SUBU;
        `EXE_ALUOP_FUNC     :  o_alu_func =    i_func;
        `EXE_ALUOP_AND      :  o_alu_func =      `AND;
        `EXE_ALUOP_OR       :  o_alu_func =       `OR;
        `EXE_ALUOP_XOR      :  o_alu_func =      `XOR;
        `EXE_ALUOP_SHIFTLUI :  o_alu_func = `SHIFTLUI;
        `EXE_ALUOP_SLTI     :  o_alu_func =      `SLT;
         default         :  o_alu_func = {NB_FUNC{1'b1}};
    endcase;
end



endmodule
