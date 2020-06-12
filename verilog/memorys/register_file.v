`timescale 1ns/100ps

module register_file
#(
    parameter NB_DATA = 32,
    parameter N_REGS  = 32,
    parameter _NB_ADDR = $clog2(N_REGS)
 )
 (
    input  wire                      i_clk,
    input  wire                      i_rst,
    input  wire                      i_write_enable,
    input  wire [ NB_DATA-1 : 0]     i_data,
    input  wire [_NB_ADDR-1 : 0]     i_write_addr,
    input  wire [_NB_ADDR-1 : 0]     i_read_addr_RS,
    input  wire [_NB_ADDR-1 : 0]     i_read_addr_RT,

    input  wire [_NB_ADDR-1 : 0]     i_read_addr_debug,
    output wire [NB_DATA - 1 : 0]    o_data_debug,

    output wire [NB_DATA-1 : 0]     o_data_RS,
    output wire [NB_DATA-1 : 0]     o_data_RT
 );


reg [NB_DATA - 1 : 0] registers [N_REGS - 1 : 0];
integer i;

always @ (posedge i_clk)
begin
    if (i_rst)
    begin
        for (i = 0 ; i < N_REGS ; i = i + 1)
            registers[i] <= i;    
    end
    else if (i_write_enable)
        registers[i_write_addr] <= i_data;
end

assign o_data_RS = registers[i_read_addr_RS];
assign o_data_RT = registers[i_read_addr_RT];

assign o_data_debug = registers[i_read_addr_debug];

endmodule
