`timescale 1ns/100ps

module byte_memory
#(
    parameter NB_DATA = 32,
    parameter _NB_ENABLE = NB_DATA / 8,
    parameter DEPTH = 1024,
    parameter NB_ADDR = 32
 )
 (
    input  wire                          i_clk,
    input  wire                          i_write_enable,
    input  wire [_NB_ENABLE - 1 : 0]     i_byte_enb,
    input  wire [NB_ADDR - 1 : 0]        i_addr,
    input  wire [NB_DATA - 1 : 0]        i_data,

    input  wire [NB_ADDR - 1 : 0]       i_addr_debug,

    output wire [NB_DATA - 1 : 0]       o_data_debug,

    output wire [NB_DATA - 1 : 0]        o_data
 );

localparam NB_BYTE = 8;

wire                    valid_addr;
reg [NB_BYTE - 1 : 0]   byte_0;
reg [NB_BYTE - 1 : 0]   byte_1;
reg [NB_BYTE - 1 : 0]   byte_2;
reg [NB_BYTE - 1 : 0]   byte_3;

reg [NB_DATA - 1 : 0]   memory  [DEPTH - 1 : 0];

assign valid_addr = (i_addr < DEPTH) ? 1'b1 : 1'b0;

always @ (*)
begin
    if (i_byte_enb[0])
        byte_0 = i_data[0 * NB_BYTE +: NB_BYTE];
    else if (valid_addr)
        byte_0 = memory[i_addr][0 * NB_BYTE +: NB_BYTE];
    else
        byte_0 = 0;
end

always @ (*)
begin
    if (i_byte_enb[1])
        byte_1 = i_data[1 * NB_BYTE +: NB_BYTE];
    else if (valid_addr)
        byte_1 = memory[i_addr][1 * NB_BYTE +: NB_BYTE];
    else
        byte_1 = 0;
end

always @ (*)
begin
    if (i_byte_enb[2])
        byte_2 = i_data[2 * NB_BYTE +: NB_BYTE];
    else if (valid_addr)
        byte_2 = memory[i_addr][2 * NB_BYTE +: NB_BYTE];
    else
        byte_2 = 0;
end
always @ (*)
begin
    if (i_byte_enb[3])
        byte_3 = i_data[3 * NB_BYTE +: NB_BYTE];
    else if (valid_addr)
        byte_3 = memory[i_addr][3 * NB_BYTE +: NB_BYTE];
    else
        byte_3 = 0;
end

always @ (posedge i_clk)
begin
    if (valid_addr & (i_write_enable == `MEM_WRITE) )
        memory[i_addr] <= {byte_3, byte_2, byte_1, byte_0};
end

assign o_data = (valid_addr) ? memory[i_addr] : 32'hF0_F0_F0_F0;
assign o_data_debug = memory[i_addr_debug];
endmodule
