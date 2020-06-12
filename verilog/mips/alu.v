`timescale 1ns / 100ps
`include "defines.v"
// @TODO 
module alu
#
(
    parameter NB_SHAMT         =              5,
    parameter NB_FUNC          =              6,
    parameter NB_DATA          =             32
)(
    input   wire    [NB_DATA  - 1:0]      i_dataRS,
    input   wire    [NB_DATA  - 1:0]      i_dataRT,
    input   wire    [NB_SHAMT - 1:0]      i_shamt,
    input   wire    [NB_FUNC  - 1:0]      i_func,
    output  reg     [NB_DATA  - 1:0]      o_result,
    output  wire                          o_zero      
);


assign o_zero = ( o_result == 'd0) ? 1'b1 : 1'b0 ;
    
always @(*)
    case (i_func)
        /* Shift */
        `SLL  : o_result    = i_dataRT  <<  i_shamt;
        `SRL  : o_result    = i_dataRT  >>  i_shamt;
        `SRA  : o_result    = i_dataRT >>>  i_shamt;
        `SLLV : o_result    = i_dataRT  <<  i_dataRS;
        `SRLV : o_result    = i_dataRT  >>  i_dataRS;
        `SRAV : o_result    = i_dataRT >>>  i_dataRS;
        `SHIFTLUI: o_result = {i_dataRT[15:0],{16{1'b0}}} ;
        /* aritmetica basica */
        `ADD  : o_result    = $signed (i_dataRS) + $signed (i_dataRT);
        `ADDU : o_result    = i_dataRS + i_dataRT;
        `SUBU : o_result    = $signed (i_dataRS) - $signed (i_dataRT);
        /* Logic  */
        `AND  : o_result    =  i_dataRS & i_dataRT;
        `OR   : o_result    =  i_dataRS | i_dataRT;
        `XOR  : o_result    =  i_dataRS ^ i_dataRT;
        `NOR  : o_result    = ~(i_dataRS | i_dataRT);
        /**/
        `SLT  : o_result    = ($signed (i_dataRS) < $signed (i_dataRT)) ? 'd1 : 'd0;
        
        default: o_result   = {NB_DATA{1'b1}};
    endcase
endmodule
