`timescale 1ns / 100ps
`include "defines.v"

module forwarding_unit
#(
    parameter NB_DATA           =   32,
    parameter N_REG             =   32,
    parameter _NB_INDEX_REG     = $clog2(N_REG)

)
(
    input                                   i_exe_wrbctl_write,   // From inst i-1
    input                                   i_mem_wrbctl_write,   // From inst i-2
    input   [_NB_INDEX_REG - 1 : 0]         i_exe_regdest,        // From inst i-1
    input   [_NB_INDEX_REG - 1 : 0]         i_mem_regdest,        // From inst i-2
    
    input   [_NB_INDEX_REG - 1 : 0]         i_dec_indexRT,             // From inst i
    input   [_NB_INDEX_REG - 1 : 0]         i_dec_indexRS,              // From inst i
    
    output  wire  [`NB_FORWARDING_SELECTOR - 1 : 0]  o_mux_rs_select,
    output  wire  [`NB_FORWARDING_SELECTOR - 1 : 0]  o_mux_rt_select

);




assign o_mux_rs_select = ((i_dec_indexRS == i_exe_regdest ) & i_exe_wrbctl_write) 
                        ? `FORWARDING_SEL_EXE
                        :((i_dec_indexRS == i_mem_regdest ) & i_mem_wrbctl_write) 
                            ? `FORWARDING_SEL_MEM
                            : `FORWARDING_SEL_RF;

assign o_mux_rt_select = ((i_dec_indexRT == i_exe_regdest ) & i_exe_wrbctl_write) 
                        ? `FORWARDING_SEL_EXE
                        :((i_dec_indexRT == i_mem_regdest ) & i_mem_wrbctl_write) 
                            ? `FORWARDING_SEL_MEM 
                            : `FORWARDING_SEL_RF;


endmodule
