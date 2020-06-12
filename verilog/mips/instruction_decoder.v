`timescale 1ns / 100ps


module instruction_decoder
#(
    parameter NB_OPCODE        =              6,
    parameter N_REG            =             32,
    parameter _NB_INDEX_REG     =  $clog2(N_REG),
    parameter NB_SHAMT         =              5,
    parameter NB_FUNC          =              6,
    parameter NB_OFFSET        =             16,
    parameter NB_ADDR_INDEX    =             26,  // Addr index
    parameter NB_DATA          =             32,
    parameter NB_PC            =             32   // Pc branch

)
(
    input   wire                              i_clk,
    input   wire                              i_rst,
    input   wire                              i_pipe_enabled,
    input   wire                              i_insert_nop,
    input   wire   [NB_OPCODE     - 1 : 0]    i_opcode,
    input   wire   [_NB_INDEX_REG - 1 : 0]    i_index_reg_rs,
    input   wire   [_NB_INDEX_REG - 1 : 0]    i_index_reg_rt,
    input   wire   [_NB_INDEX_REG - 1 : 0]    i_index_reg_rd,
    input   wire   [NB_SHAMT      - 1 : 0]    i_shift_amount,
    input   wire   [NB_FUNC       - 1 : 0]    i_func,
    input   wire   [NB_ADDR_INDEX - 1 : 0]    i_addr_index,
    input   wire   [NB_OFFSET     - 1 : 0]    i_offset,
    input   wire   [NB_PC         - 1 : 0]    i_pc_plus4,

    input   wire   [_NB_INDEX_REG - 1 : 0]    i_rf_reg_index_addr,
    
    input   wire   [_NB_INDEX_REG - 1 : 0]    i_wrb_write_addr,   // <from future>
    input   wire   [NB_DATA       - 1 : 0]    i_wrb_write_data,   // <from future>
    input   wire                              i_wrb_write_enable, // <from future>
    

    
    output  wire   [`NB_EXE_CTRL   - 1 : 0]   o_control_exe,   // ctl
    output  wire   [`NB_MEM_CTRL   - 1 : 0]   o_control_mem,   // ctl
    output  wire   [`NB_WRB_CTRL   - 1 : 0]   o_control_wb,    // ctl
    
    output  wire   [NB_ADDR_INDEX - 1 : 0]    o_addr_index,
    output  wire   [NB_PC         - 1 : 0]    o_pc_plus4,
    output  wire   [NB_DATA       - 1 : 0]    o_signed_literal,
    output  wire   [NB_FUNC       - 1 : 0]    o_func,
    output  wire   [NB_SHAMT      - 1 : 0]    o_shift_amount,
    output  wire   [_NB_INDEX_REG - 1 : 0]    o_index_reg_rt,
    output  wire   [_NB_INDEX_REG - 1 : 0]    o_index_reg_rd,
    output  wire   [_NB_INDEX_REG - 1 : 0]    o_index_reg_rs,  //4warding unit
    
    output  wire   [NB_DATA       - 1 : 0]    o_data_rs,
    output  wire   [NB_DATA       - 1 : 0]    o_data_rt, 
    output  wire   [NB_DATA       - 1 : 0]    o_rf_reg_data 
         
    
)
;

wire   [_NB_INDEX_REG - 1 : 0]    rs_addr;
// ----------  output  reg: passthrough ----------------------- 
reg [NB_PC         - 1 : 0]   id_ex_instruccion_pc; 
reg [NB_FUNC       - 1 : 0]   id_ex_func;
reg [NB_SHAMT      - 1 : 0]   id_ex_shift_amount;
reg [_NB_INDEX_REG - 1 : 0]   id_ex_index_reg_rt;
reg [_NB_INDEX_REG - 1 : 0]   id_ex_index_reg_rd;
reg [_NB_INDEX_REG - 1 : 0]   id_ex_index_reg_rs; // 4 4warding
reg [NB_DATA       - 1 : 0]    signed_literal;
reg [NB_ADDR_INDEX - 1 : 0]    addr_index;

// ----------  output  reg: Req logic  ----------------------- 
reg  [NB_DATA       - 1 : 0]    data_rs;
reg  [NB_DATA       - 1 : 0]    data_rt;
wire [NB_DATA       - 1 : 0]    rf_data_rs;
wire [NB_DATA       - 1 : 0]    rf_data_rt;

// --------- Unit control reg
reg   [`NB_EXE_CTRL   - 1 : 0]    id_ex_control_exe;
reg   [`NB_MEM_CTRL   - 1 : 0]    id_mem_control_mem;
reg   [`NB_WRB_CTRL   - 1 : 0]    id_wb_control_wb;
wire  [`NB_EXE_CTRL   - 1 : 0]    w_control_exe;
wire  [`NB_MEM_CTRL   - 1 : 0]    w_control_mem;
wire  [`NB_WRB_CTRL   - 1 : 0]    w_control_wb;
wire                              ext_sig;

// -------------  passthrough logic  -----------------------
always @(posedge i_clk)
begin
    if (i_rst)
    begin
        id_ex_instruccion_pc <=   'd0; 
        id_ex_func           <=   'd0;
        id_ex_shift_amount   <=   'd0;
        id_ex_index_reg_rt   <=   'd0;
        id_ex_index_reg_rd   <=   'd0;
        id_ex_index_reg_rs   <=   'd0;
        signed_literal       <=   'd0;
        addr_index           <=   'd0;
    end
    else if(i_pipe_enabled && i_insert_nop)
    begin
        id_ex_instruccion_pc <=   'd0; 
        id_ex_func           <=   'd0;
        id_ex_shift_amount   <=   'd0;
        id_ex_index_reg_rt   <=   'd0;
        id_ex_index_reg_rd   <=   'd0;
        id_ex_index_reg_rs   <=   'd0;
        signed_literal       <=   'd0;
        addr_index           <=   'd0;
    end
    else if(i_pipe_enabled)
    begin
        id_ex_instruccion_pc <=                    i_pc_plus4; 
        id_ex_func           <=                        i_func;
        id_ex_shift_amount   <=                i_shift_amount;
        id_ex_index_reg_rt   <=                i_index_reg_rt;
        id_ex_index_reg_rd   <=                i_index_reg_rd;
        id_ex_index_reg_rs   <=                i_index_reg_rs;
        signed_literal       <=     (ext_sig == `DEC_EXT_SING )
                                    ? {{16{i_offset[15]}},i_offset}
                                    : {{16{1'b0}},i_offset};
        addr_index           <=                  i_addr_index;
    end
end

// Ports passtrhough
assign o_pc_plus4       = id_ex_instruccion_pc; 
assign o_func           = id_ex_func          ;
assign o_shift_amount   = id_ex_shift_amount  ;
assign o_index_reg_rt   = id_ex_index_reg_rt  ;
assign o_index_reg_rd   = id_ex_index_reg_rd  ;
assign o_index_reg_rs   = id_ex_index_reg_rs  ; //4 4warding unit     
assign o_signed_literal =     signed_literal  ;
assign o_addr_index     =         addr_index  ;

// ------------- outputs reg  logic  -----------------------
// Evitamos usar negedge en el register file

always @(posedge i_clk)
begin
    if (i_rst)
    begin
        data_rs <= 'd0;
        data_rt <= 'd0;
    end
    else if(i_pipe_enabled && i_insert_nop)
    begin
        data_rs <= 'd0;
        data_rt <= 'd0;
    end
    else if(i_pipe_enabled)
    begin 
        data_rs <= (i_wrb_write_addr == i_index_reg_rs 
                        && i_wrb_write_enable)
                        ?  i_wrb_write_data
                        : rf_data_rs;
                        
        data_rt <= (i_wrb_write_addr == i_index_reg_rt 
                        && i_wrb_write_enable)
                        ?  i_wrb_write_data
                        : rf_data_rt;
    end
end

assign o_data_rt = data_rt;
assign o_data_rs = data_rs;



// -------------  register file read -----------------------

register_file
#(
    .NB_DATA(NB_DATA),
    .N_REGS(N_REG)
 )
 u_regf
 (
    .i_clk              (i_clk),
    .i_rst              (i_rst),
    .i_write_enable     (i_pipe_enabled & i_wrb_write_enable ),
    .i_data             (i_wrb_write_data),
    .i_write_addr       (i_wrb_write_addr),
    .i_read_addr_RS     (i_index_reg_rs),
    .i_read_addr_RT     (i_index_reg_rt),
    .i_read_addr_debug  (i_rf_reg_index_addr),

    .o_data_debug       (o_rf_reg_data),
    .o_data_RS          (rf_data_rs),
    .o_data_RT          (rf_data_rt)
 );

// -------------  Control unit read logic -----------------------


always @(posedge i_clk)
begin
    if (i_rst)
    begin
        id_ex_control_exe   <= 'd0;
        id_mem_control_mem  <= 'd0;
        id_wb_control_wb    <= 'd0;
    end
    else if(i_pipe_enabled && i_insert_nop)
    begin
        id_ex_control_exe   <= 'd0;
        id_mem_control_mem  <= 'd0;
        id_wb_control_wb    <= 'd0;
    end
    else if(i_pipe_enabled)
    begin
        id_ex_control_exe   <= w_control_exe;
        id_mem_control_mem  <= w_control_mem;
        id_wb_control_wb    <= w_control_wb;
    end
    
end
// Ports: Control 
assign  o_control_exe   =     id_ex_control_exe;
assign  o_control_mem   =     id_mem_control_mem;
assign  o_control_wb    =     id_wb_control_wb;


control_unit
#(
    .NB_OPCODE       (NB_OPCODE),
    .NB_FUNC           (NB_FUNC)
 )
 control
 (
    .i_opcode      (i_opcode),
    .i_func        (i_func),
    .o_exe_ctrl    (w_control_exe),
    .o_mem_ctrl    (w_control_mem),
    .o_wrb_ctrl    (w_control_wb),
    .o_ext_sig     (ext_sig)
 );

endmodule
