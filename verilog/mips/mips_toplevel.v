`timescale 1ns/100ps

`include "defines.v"


module mips_toplevel
#(
    parameter NB_DATA           = 32,
    parameter NB_PC             = 32,
    parameter NB_OPCODE         = 6,
    parameter NB_FUNC           = 6,
    parameter NB_SHAMT          = 5,
    parameter NB_OFFSET         = 16,
    parameter NB_ADDR_INDEX     = 26,
    parameter N_REG             = 32,
    parameter _NB_INDEX_REG     = $clog2(N_REG),

    parameter MEM_DEPTH         = 1024
 )
 (
    input  wire                             clk,
    input  wire                             btnC,
    //FIXME ver bien como setear los enables
    input  wire                             i_rf_pipe_enabled,
    input  wire                             i_rf_instruction_write,
    input  wire [NB_PC          - 1 : 0]    i_rf_instruction_addr,
    input  wire [NB_DATA        - 1 : 0]    i_rf_instruction_data,
    input  wire [_NB_INDEX_REG  - 1 : 0]    i_rf_reg_index_addr,
    input  wire [NB_DATA        - 1 : 0]    i_rf_memory_addr,

    output wire [NB_DATA        - 1 : 0]    o_rf_reg_data,
    output wire [NB_DATA        - 1 : 0]    o_rf_memory_data,
    output wire [NB_PC          - 1 : 0]    o_rf_pc_count
 );

localparam NB_INDEX_REG = $clog2(N_REG);

wire i_clk;
wire i_rst;
assign i_clk = clk;
assign i_rst = btnC;


/* fetch to decode */

wire   [NB_OPCODE   - 1 : 0]      fetch_opcode_decode;
wire   [NB_INDEX_REG -1 : 0]      fetch_indexRS_decode;
wire   [NB_INDEX_REG -1 : 0]      fetch_indexRT_decode;
wire   [NB_INDEX_REG -1 : 0]      fetch_indexRD_decode;
wire   [NB_SHAMT     -1 : 0]      fetch_shamt_decode;
wire   [NB_FUNC      -1 : 0]      fetch_func_decode;
wire   [NB_ADDR_INDEX-1 : 0]      fetch_addrIndex_decode;
wire   [NB_OFFSET    -1 : 0]      fetch_offset_decode;
wire   [NB_PC       - 1 : 0]      fetch_pcPlus4_decode;


/* decode to execute */

wire   [`NB_EXE_CTRL   - 1 : 0]   decode_ctrlExe_execute;   // ctl
wire   [`NB_MEM_CTRL   - 1 : 0]   decode_ctrlMem_execute;   // ctl
wire   [`NB_WRB_CTRL   - 1 : 0]   decode_ctrlWrb_execute;    // ctl
    
wire   [NB_PC         - 1 : 0]    decode_pcPlus4_execute;
wire   [NB_ADDR_INDEX - 1 : 0]    decode_addrIndex_execute;
wire   [NB_DATA       - 1 : 0]    decode_signLit_execute;
wire   [NB_FUNC       - 1 : 0]    decode_func_execute;
wire   [NB_SHAMT      - 1 : 0]    decode_shamt_execute;
wire   [NB_INDEX_REG  - 1 : 0]    decode_indexRT_execute;
wire   [NB_INDEX_REG  - 1 : 0]    decode_indexRD_execute;
      
wire   [NB_DATA       - 1 : 0]    decode_dataRS_execute;
wire   [NB_DATA       - 1 : 0]    decode_dataRT_execute;

/* execute to fetch */
wire   [NB_PC         - 1 : 0]    execute_addrBranch_fetch;
wire                              execute_branchTaken_fetch;
wire   [NB_PC         - 1 : 0]    execute_addrJump_fetch;
wire                              execute_jumpTaken_fetch;

/* execute to mem */
 
wire   [`NB_MEM_CTRL   - 1 : 0]   execute_ctrlMem_memacc;
wire   [`NB_WRB_CTRL   - 1 : 0]   execute_ctrlWrb_memacc;
    
wire   [NB_DATA       - 1 : 0]    execute_aluResult_memacc;
wire   [NB_DATA       - 1 : 0]    execute_dataRT_memacc;
wire   [NB_INDEX_REG - 1 : 0]    execute_regDest_memacc;


/* mem to writeback */

wire [NB_DATA        - 1 : 0]    memacc_aluResult_wrb;
wire [NB_DATA        - 1 : 0]    memacc_memData_wrb;
wire [NB_INDEX_REG   - 1 : 0]    memacc_regDest_wrb;
wire [`NB_WRB_CTRL   - 1 : 0]    memacc_controlWrb_wrb;


/* writeback signals  */
wire [NB_DATA       - 1 : 0]    wrb_data_decode;
wire                            wrb_writeEnable_decode;
wire [NB_INDEX_REG  - 1 : 0]    wrb_indexReg_decode;

/* Fordwaring unit */
wire [NB_INDEX_REG              - 1 : 0]     decode_indexRS_fordwarding;
wire [`NB_FORWARDING_SELECTOR   - 1 : 0]     fordwarding_selectorRS_execute;
wire [`NB_FORWARDING_SELECTOR   - 1 : 0]     fordwarding_selectorRT_execute;
wire                                         execute_writeEnable_forwarding;

/* Hazard unit */

//Usa los wires que ya tenemos saliendo de cada module

wire    hazard_insertNOP_decode;
wire    hazard_stall_fetch;

/***********************************************

                   Instances

************************************************/


instruction_fetch
#(
    .NB_OPCODE      (NB_OPCODE) ,
    .N_REG          (N_REG),
    .NB_SHAMT       (NB_SHAMT),
    .NB_FUNC        (NB_FUNC),
    .NB_OFFSET      (NB_OFFSET),
    .NB_ADDR_INDEX  (NB_ADDR_INDEX),  // Addr index
    .NB_PC          (NB_PC)            // Pc branch
 )
    u_fetch_stage
    (
        .i_clk              (i_clk),
        .i_rst              (i_rst),
        .i_pipe_enabled     (i_rf_pipe_enabled),
        .i_stall            (hazard_stall_fetch),
        
        .i_pc_sel_branch    (execute_branchTaken_fetch),
        .i_pc_sel_jump      (execute_jumpTaken_fetch),
        
        .i_pc_addr_branch   (execute_addrBranch_fetch),
        .i_pc_addr_jump     (execute_addrJump_fetch),

        .i_rf_instruction_write_enb(i_rf_instruction_write),
        .i_rf_instruction_addr(i_rf_instruction_addr),
        .i_rf_instruction_data(i_rf_instruction_data),

        .o_opcode           (fetch_opcode_decode),
        .o_index_reg_rs     (fetch_indexRS_decode),
        .o_index_reg_rt     (fetch_indexRT_decode),
        .o_index_reg_rd     (fetch_indexRD_decode),
        .o_shift_amount     (fetch_shamt_decode),
        .o_func             (fetch_func_decode),
        .o_addr_index       (fetch_addrIndex_decode),
        .o_offset           (fetch_offset_decode),
        .o_pc_plus4         (fetch_pcPlus4_decode),
        .o_rf_pc_count      (o_rf_pc_count)
    );


instruction_decoder
#(
    .NB_OPCODE      (NB_OPCODE) ,
    .N_REG          (N_REG),
    .NB_SHAMT       (NB_SHAMT),
    .NB_FUNC        (NB_FUNC),
    .NB_OFFSET      (NB_OFFSET),
    .NB_ADDR_INDEX  (NB_ADDR_INDEX),  // Addr index
    .NB_PC          (NB_PC)            // Pc branch
 )
    u_decode_stage
    (
        .i_clk              (i_clk),
        .i_rst              (i_rst),
        .i_pipe_enabled     (i_rf_pipe_enabled),
        .i_insert_nop       (hazard_insertNOP_decode | execute_branchTaken_fetch),
        .i_opcode           (fetch_opcode_decode),
        .i_index_reg_rs     (fetch_indexRS_decode),
        .i_index_reg_rt     (fetch_indexRT_decode),
        .i_index_reg_rd     (fetch_indexRD_decode),
        .i_shift_amount     (fetch_shamt_decode),
        .i_func             (fetch_func_decode),
        .i_addr_index       (fetch_addrIndex_decode),
        .i_offset           (fetch_offset_decode),
        .i_pc_plus4         (fetch_pcPlus4_decode),

        .i_rf_reg_index_addr(i_rf_reg_index_addr),
        .o_rf_reg_data      (o_rf_reg_data),

        .i_wrb_write_addr   (wrb_indexReg_decode),
        .i_wrb_write_data   (wrb_data_decode),
        .i_wrb_write_enable (wrb_writeEnable_decode),     
        
        .o_control_exe      (decode_ctrlExe_execute),
        .o_control_mem      (decode_ctrlMem_execute),
        .o_control_wb       (decode_ctrlWrb_execute),

        .o_addr_index       (decode_addrIndex_execute),
        .o_pc_plus4         (decode_pcPlus4_execute),
        .o_signed_literal   (decode_signLit_execute),
        .o_func             (decode_func_execute),
        .o_shift_amount     (decode_shamt_execute),
        .o_index_reg_rt     (decode_indexRT_execute),
        .o_index_reg_rd     (decode_indexRD_execute),
        .o_index_reg_rs     (decode_indexRS_fordwarding),
        .o_data_rs          (decode_dataRS_execute),
        .o_data_rt          (decode_dataRT_execute)
    );

execute
#(
    .NB_DATA        (NB_DATA),
    .N_REG          (N_REG),
    .NB_SHAMT       (NB_SHAMT),
    .NB_FUNC        (NB_FUNC),
    .NB_PC          (NB_PC)            // Pc branch
 )
    u_execute_stage
    (
        .i_clk              (i_clk),
        .i_rst              (i_rst),
        .i_pipe_enabled     (i_rf_pipe_enabled),

        .i_control_exe      (decode_ctrlExe_execute),
        .i_control_mem      (decode_ctrlMem_execute),
        .i_control_wb       (decode_ctrlWrb_execute),
        .i_pc_plus4         (decode_pcPlus4_execute),
        .i_addr_index       (decode_addrIndex_execute),
        .i_signed_literal   (decode_signLit_execute),
        .i_func             (decode_func_execute),
        .i_shift_amount     (decode_shamt_execute),
        .i_index_reg_rt     (decode_indexRT_execute),
        .i_index_reg_rd     (decode_indexRD_execute),
        .i_data_rs          (decode_dataRS_execute),
        .i_data_rt          (decode_dataRT_execute),
        
        .i_fwd_rs_select    (fordwarding_selectorRS_execute),
        .i_fwd_rt_select    (fordwarding_selectorRT_execute),
        .i_fwd_wrb_data     (wrb_data_decode),

        .o_control_mem      (execute_ctrlMem_memacc),
        .o_control_wb       (execute_ctrlWrb_memacc),
        
        .o_alu_result       (execute_aluResult_memacc),
        .o_data_rt          (execute_dataRT_memacc),
        .o_reg_dest         (execute_regDest_memacc),

        .o_instr_pc_branch  (execute_addrBranch_fetch),
        .o_branch_taken     (execute_branchTaken_fetch),
        
        .o_instr_pc_jump    (execute_addrJump_fetch),
        .o_jump_taken       (execute_jumpTaken_fetch)
    );

mem_unit
#(
    .NB_DATA    (NB_DATA),
    .N_REGS     (N_REG),
    .MEM_DEPTH  (MEM_DEPTH)
 )
    u_memory_stage
    (
        .i_clk              (i_clk),
        .i_rst              (i_rst),
        .i_pipe_enabled     (i_rf_pipe_enabled),
        .i_control_mem      (execute_ctrlMem_memacc),
        .i_control_wrb      (execute_ctrlWrb_memacc),
        
        .i_alu_result       (execute_aluResult_memacc),
        .i_data_rt          (execute_dataRT_memacc),
        .i_reg_dest         (execute_regDest_memacc),

        .i_rf_memory_addr   (i_rf_memory_addr),
        .o_rf_memory_data   (o_rf_memory_data),

        .o_alu_result       (memacc_aluResult_wrb),
        .o_mem_data         (memacc_memData_wrb),
        .o_reg_dest         (memacc_regDest_wrb),
        .o_control_wrb      (memacc_controlWrb_wrb)
    );

/***************************************
            write back logic
***************************************/

assign wrb_data_decode = (memacc_controlWrb_wrb[`POS_WRB_MEM2REG] == `WRB_USE_ALU)
                           ? memacc_aluResult_wrb 
                           : memacc_memData_wrb;

assign wrb_writeEnable_decode = memacc_controlWrb_wrb[`POS_WRB_WRITEENB];

assign wrb_indexReg_decode    = memacc_regDest_wrb;


/***************************************
            Fordwarding unit
***************************************/

assign execute_writeEnable_forwarding =  execute_ctrlWrb_memacc [`POS_WRB_WRITEENB];

forwarding_unit
#(
    .NB_DATA    (NB_DATA),
    .N_REG        (N_REG)

)
u_forwarding_unit
(
    .i_exe_wrbctl_write     (execute_writeEnable_forwarding),
    .i_mem_wrbctl_write     (wrb_writeEnable_decode),
    .i_exe_regdest          (execute_regDest_memacc),
    .i_mem_regdest          (wrb_indexReg_decode),
        
    .i_dec_indexRT         (decode_indexRT_execute),
    .i_dec_indexRS         (decode_indexRS_fordwarding),
     
    .o_mux_rs_select       (fordwarding_selectorRS_execute),
    .o_mux_rt_select       (fordwarding_selectorRT_execute)

);

/***************************************
            Hazard  unit
***************************************/

hazard_detection
#(
    .N_REG(N_REG)
 )
    u_hazard_detection
    (
        .i_decode_indexRT       (decode_indexRT_execute), //RT destino de LOAD
        .i_decode_control_mem   (decode_ctrlMem_execute[`POS_MEM_RDWR +: `NB_MEM_RDWR]),
        .i_fetch_indexRS        (fetch_indexRS_decode),
        .i_fetch_indexRT        (fetch_indexRT_decode),

        .o_decode_insert_nop    (hazard_insertNOP_decode),
        .o_fetch_stall          (hazard_stall_fetch)

    );

endmodule
