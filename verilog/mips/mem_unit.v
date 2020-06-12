`timescale 1ns / 100ps

module mem_unit
#(
    parameter NB_DATA = 32,
    parameter N_REGS = 32,
    parameter _NB_INDEX_REG = $clog2(N_REGS),
    parameter MEM_DEPTH = 1024
 )
 (
    input wire                              i_clk,
    input wire                              i_rst,
    input wire                              i_pipe_enabled,
    input wire  [NB_DATA        - 1 : 0]    i_alu_result,
    input wire  [NB_DATA        - 1 : 0]    i_data_rt,
    input wire  [_NB_INDEX_REG  - 1 : 0]    i_reg_dest,
    input wire  [`NB_MEM_CTRL   - 1 : 0]    i_control_mem,
    input wire  [`NB_WRB_CTRL   - 1 : 0]    i_control_wrb,

    input wire  [NB_DATA        - 1 : 0]    i_rf_memory_addr,

    output wire [NB_DATA        - 1 : 0]    o_alu_result,
    output wire [NB_DATA        - 1 : 0]    o_mem_data,
    output wire [_NB_INDEX_REG  - 1 : 0]    o_reg_dest,
    output wire [`NB_WRB_CTRL   - 1 : 0]    o_control_wrb,
    output wire [NB_DATA        - 1 : 0]    o_rf_memory_data
 );


localparam MASK_LOWER = 32'h0000ffff;
localparam FULL_WORD_ENB    = 4'b1111;
localparam HALF_UPPER_ENB   = 4'b1100;
localparam HALF_LOWER_ENB   = 4'b0011;
localparam BYTE_ZERO_ENB    = 4'b0001;
localparam BYTE_ONE_ENB     = 4'b0010;
localparam BYTE_TWO_ENB     = 4'b0100;
localparam BYTE_THREE_ENB   = 4'b1000;



/* 4 RW Logic */
wire [NB_DATA - 1 : 0 ] real_addr;
wire [NB_DATA - 1 : 0 ] mem_out_data; //data read from memory

reg [3 : 0]             sel_half;
reg [3 : 0]             sel_byte;
reg [3 : 0]             rd_byte_enable;

reg [NB_DATA - 1 : 0 ]  read_data;
reg [NB_DATA - 1 : 0 ]  read_data_signed;
reg [3 : 0]             wr_byte_enable;

assign real_addr  = {2'b00,i_alu_result[NB_DATA - 1 : 2]};

/* ------------- Out Logic --------------*/
reg [NB_DATA        - 1 : 0]    alu_result  ;
reg [NB_DATA        - 1 : 0]    mem_data    ;
reg [_NB_INDEX_REG  - 1 : 0]    reg_dest    ;
reg [`NB_WRB_CTRL    - 1 : 0]   wrb_control ;

assign o_alu_result = alu_result;
assign o_mem_data   = mem_data;
assign o_reg_dest   = reg_dest;


always @(posedge i_clk)
begin
    if (i_rst)
    begin
        alu_result <= 'd0;
        mem_data   <= 'd0;
        reg_dest   <= 'd0;
    end
    else if(i_pipe_enabled)
    begin
        alu_result <=     i_alu_result;
        mem_data   <= read_data_signed;
        reg_dest   <=       i_reg_dest;
    end
end

assign o_control_wrb = wrb_control;
 
always @(posedge i_clk)
begin
    if (i_rst)
        wrb_control <= 'd0;
    else if (i_pipe_enabled)
        wrb_control <= i_control_wrb;
end

/**********************************************
                WRITE  LOGIC

**********************************************/

always @(*)
begin
    if( i_control_mem[`POS_MEM_RDWR +: `NB_MEM_RDWR] == `MEM_WRITE 
        && i_control_mem[`POS_MEM_BYENB +: `NB_MEM_BYENB] ==  `MEM_BYENB_BYTE)
            wr_byte_enable = 4'b0001;
    else if( i_control_mem[`POS_MEM_RDWR +: `NB_MEM_RDWR] == `MEM_WRITE 
        && i_control_mem[`POS_MEM_BYENB +: `NB_MEM_BYENB] ==  `MEM_BYENB_HALF)
            wr_byte_enable = 4'b0011;
    else
        wr_byte_enable = 4'b1111;
end


byte_memory
#(
    .NB_DATA  (NB_DATA),
    .DEPTH    (MEM_DEPTH),
    .NB_ADDR  (NB_DATA)
 )
 u_byte_mem
 (
    .i_clk          (i_clk),
    .i_write_enable ((i_control_mem[`POS_MEM_RDWR +: `NB_MEM_RDWR] == `MEM_WRITE)  & i_pipe_enabled),
    .i_byte_enb     (wr_byte_enable),
    .i_addr         (real_addr),
    .i_data         (i_data_rt),
    .o_data         (mem_out_data),

    .i_addr_debug   (i_rf_memory_addr),
    .o_data_debug   (o_rf_memory_data)
 );

/**********************************************
                READ LOGIC

**********************************************/
// Codificacion para seleccion lectura de byte
always @(*)
begin
    case (i_alu_result [1:0])
        2'b00 : sel_byte = 4'b0001;
        2'b01 : sel_byte = 4'b0010;
        2'b10 : sel_byte = 4'b0100;
        2'b11 : sel_byte = 4'b1000;
    endcase
end

// Codificacion para seleccion lectura de media palabra
always @(*)
begin
    case (i_alu_result [1:0])
        2'b00   : sel_half = 4'b0011;
        2'b10   : sel_half = 4'b1100;
        default : sel_half = 4'b1111;
    endcase
end

// Seleccion de lectura byte/half/word
always @(*)
begin
    case (i_control_mem[`POS_MEM_BYENB +: `NB_MEM_BYENB])
        `MEM_BYENB_BYTE : rd_byte_enable = sel_byte;
        `MEM_BYENB_HALF : rd_byte_enable = sel_half;
        `MEM_BYENB_WORD : rd_byte_enable =  4'b1111;
        default         : rd_byte_enable =  4'b0000;
    endcase
end

// Shifteo de datos para la cargar alineado en el banco de registro el dato
always @ (*)
begin
    case(rd_byte_enable)
        HALF_LOWER_ENB  : read_data    = {16'h0000  , mem_out_data[0  +: 16]};
        HALF_UPPER_ENB  : read_data    = {16'h0000  , mem_out_data[16 +: 16]};
        BYTE_ZERO_ENB   : read_data    = {24'h000000, mem_out_data[0  +: 8]};
        BYTE_ONE_ENB    : read_data    = {24'h000000, mem_out_data[8  +: 8]};
        BYTE_TWO_ENB    : read_data    = {24'h000000, mem_out_data[16 +: 8]};
        BYTE_THREE_ENB  : read_data    = {24'h000000, mem_out_data[24 +: 8]};
        FULL_WORD_ENB   : read_data    = mem_out_data;
        default         : read_data    = 32'hAA_AA_AA_AA;
    endcase
end

// Ajuste de extencion de signo para lectura
always @(*)
begin
    case(i_control_mem[`POS_MEM_EXTSIG +: `NB_MEM_EXTSIG])
        `MEM_EXTEND_BYTE    : read_data_signed = {{24{read_data[7]}} , read_data[0 +: 8]};
        `MEM_EXTEND_HALF    : read_data_signed = {{16{read_data[15]}}, read_data[0 +: 16]};
        default             : read_data_signed = read_data;
    endcase
end

endmodule
