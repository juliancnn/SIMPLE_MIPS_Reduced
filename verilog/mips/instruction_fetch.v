`timescale 1ns / 100ps

module instruction_fetch
#(
    parameter NB_OPCODE        =              6,
    parameter N_REG            =             32,
    parameter NB_INDEX_REG     =  $clog2(N_REG),
    parameter NB_SHAMT         =              5,
    parameter NB_FUNC          =              6,
    parameter NB_OFFSET        =             16,
    parameter NB_ADDR_INDEX    =             26,  // Addr index
    parameter NB_PC            =             32   // Pc branch
    
)
(
    input   wire                              i_clk,
    input   wire                              i_rst,
    input   wire                              i_pipe_enabled,
    input   wire                              i_stall,
    input   wire                              i_pc_sel_branch, // control 
    input   wire                              i_pc_sel_jump,   // control
    input   wire   [NB_PC - 1 : 0]            i_pc_addr_branch,
    input   wire   [NB_PC - 1 : 0]            i_pc_addr_jump,

    input  wire                               i_rf_instruction_write_enb,
    input  wire    [NB_PC - 1 : 0]            i_rf_instruction_addr,
    input  wire    [NB_PC - 1 : 0]            i_rf_instruction_data,
    output wire    [NB_PC - 1 : 0]            o_rf_pc_count,
    
    output  wire   [NB_OPCODE   - 1 : 0]      o_opcode,
    output  wire   [NB_INDEX_REG -1 : 0]      o_index_reg_rs,
    output  wire   [NB_INDEX_REG -1 : 0]      o_index_reg_rt,
    output  wire   [NB_INDEX_REG -1 : 0]      o_index_reg_rd, 
    output  wire   [NB_SHAMT     -1 : 0]      o_shift_amount,
    output  wire   [NB_FUNC      -1 : 0]      o_func,
    output  wire   [NB_ADDR_INDEX-1 : 0]      o_addr_index,
    output  wire   [NB_OFFSET    -1 : 0]      o_offset,
    output  wire   [NB_PC       - 1 : 0]      o_pc_plus4
    
);

// LOCALPARAM
localparam  POS_OPCODE        =        31; // MSB
localparam  POS_INDEX_RS      =        25;
localparam  POS_INDEX_RT      =        20;
localparam  POS_INDEX_RD      =        15;
localparam  POS_SHIFT_AMOUNT  =        10;
localparam  POS_FUNC          =         5;
localparam  POS_ADDR_INDEX    =        25;
localparam  POS_OFFSET        =        15;
localparam  NB_INSTR          =        32;

localparam HALT_INSTR         = 32'hffffffff;

// PORTS

// REG INTERN
reg  [NB_PC   - 1  : 0]     pc_count;
reg  [NB_PC   - 1  : 0]     pc_4jump;
reg  [NB_INSTR - 1 : 0]     instruction;
wire [NB_INSTR - 1 : 0]     out_mem_data;
wire                        halt_detection;

// Ports
assign o_opcode         =  instruction  [POS_OPCODE        -:     NB_OPCODE];
assign o_index_reg_rs   =  instruction  [POS_INDEX_RS      -:  NB_INDEX_REG];
assign o_index_reg_rt   =  instruction  [POS_INDEX_RT      -:  NB_INDEX_REG];
assign o_index_reg_rd   =  instruction  [POS_INDEX_RD      -:  NB_INDEX_REG]; 
assign o_shift_amount   =  instruction  [POS_SHIFT_AMOUNT  -:      NB_SHAMT];
assign o_func           =  instruction  [POS_FUNC          -:       NB_FUNC];
assign o_addr_index     =  instruction  [POS_ADDR_INDEX    -: NB_ADDR_INDEX];
assign o_offset         =  instruction  [POS_OFFSET        -:     NB_OFFSET];
assign o_pc_plus4       =  pc_4jump;
assign o_rf_pc_count    =  pc_count;


assign halt_detection = (out_mem_data == HALT_INSTR) ? 1'b1 : 1'b0;
// PC counter Logic 
always @(posedge i_clk)
begin
    if (i_rst)
        pc_count <= {NB_PC{1'b0}};
    else if (i_pipe_enabled && (i_stall || halt_detection))
        pc_count <= pc_count;
    else if (i_pipe_enabled && i_pc_sel_branch) // Prioridad al que esta mas adentro en el pipe
        pc_count <= i_pc_addr_branch;
    else if (i_pipe_enabled && i_pc_sel_jump)
        pc_count <= i_pc_addr_jump;
    else if (i_pipe_enabled)
        pc_count <= pc_count + 1'b1; // La memoria la leemos de a 4b
end

// PC 4 jump logic
always @(posedge i_clk)
begin
    if (i_rst)
        pc_4jump <= {NB_PC{1'b0}} + 1'b1;
    else if (i_pipe_enabled && (i_stall || halt_detection))
        pc_4jump <= pc_4jump;
    else if (i_pipe_enabled && (i_pc_sel_branch | i_pc_sel_jump))
        pc_4jump <= {NB_PC{1'b0}};
    else if (i_pipe_enabled)
        pc_4jump <= pc_count + 1'b1;
end



// Out reg logic
always @(posedge i_clk)
begin
    if(i_rst)
        instruction <= 'd0;
    else if (i_pipe_enabled && halt_detection)
        instruction <= 'd0;
    else if (i_pipe_enabled && i_stall)
        instruction <= instruction;
    else if (i_pipe_enabled && (i_pc_sel_branch | i_pc_sel_jump))
        instruction <= {NB_INSTR{1'b0}};
    else if (i_pipe_enabled)
        instruction <= out_mem_data;
end



rom_memory
#(
    .ROM_WIDTH      (N_REG),
    .ROM_ADDR_BITS  (NB_PC),
    .FILE           ("r_test_cortocirtuito.mem") 
)
rom
(
    .i_clock            (i_clk),
    .i_write_enable     (i_rf_instruction_write_enb),
    .i_write_addr       (i_rf_instruction_addr),
    .i_data             (i_rf_instruction_data),
    .i_read_addr        (pc_count),
    .o_data             (out_mem_data)
);



endmodule
