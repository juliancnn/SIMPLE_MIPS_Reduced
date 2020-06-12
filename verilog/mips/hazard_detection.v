`timescale 1ns/100ps

module hazard_detection
#(
    parameter N_REG = 32,
    parameter _NB_INDEX_REG = $clog2(N_REG)
 )
 (
    /* LOAD - USE hazard detection */
    input  wire [_NB_INDEX_REG - 1 : 0] i_decode_indexRT, //RT destino de LOAD
    input  wire [`NB_MEM_RDWR  - 1 : 0] i_decode_control_mem,
    input  wire [_NB_INDEX_REG - 1 : 0] i_fetch_indexRS,
    input  wire [_NB_INDEX_REG - 1 : 0] i_fetch_indexRT,

    output wire                         o_decode_insert_nop,
    output wire                         o_fetch_stall
 );


wire   is_load;
wire   rs_dependency;
wire   rt_dependency;
//[`POS_MEM_RDWR +: `NB_MEM_RDWR]
assign is_load              = (i_decode_control_mem == `MEM_READ); 
assign rs_dependency        = (i_decode_indexRT == i_fetch_indexRS);
assign rt_dependency        = (i_decode_indexRT == i_fetch_indexRT);

assign o_decode_insert_nop  = (is_load && (rs_dependency || rt_dependency)) ? 1'b1 : 1'b0;
assign o_fetch_stall        = (is_load && (rs_dependency || rt_dependency)) ? 1'b1 : 1'b0;

endmodule
