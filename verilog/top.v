
module top
(
    input  wire i_fpga_clock,
    input  wire i_fpga_reset,
    input  wire RsRx,
    
    output wire RsTx
);


// Localparams
localparam NB_GPIO = 32;
localparam N_REG   = 32;
localparam NB_PC   = 32;
localparam _NB_INDEX_REG = $clog2(N_REG);


// Clocking signal
wire micro_clock_out;
wire clock_mips;
wire locked_clock;

// Debug Unit to MicroBlaze
wire [NB_GPIO - 1 : 0] micro_gpio_rf; // gpio_rtl_tri_o
wire [NB_GPIO - 1 : 0] rf_gpio_micro; //gpio_rtl_tri_i

// Mips to Debug Unit
wire [NB_GPIO - 1 : 0] mips_regData_debug; 
wire [NB_GPIO - 1 : 0] mips_memData_debug;
wire [NB_GPIO - 1 : 0] mips_pcCount_debug;

//Debug Unit to Mips
wire                            debug_run_mips;
wire                            debug_step_mips;
wire [NB_PC - 1 : 0]            debug_instructionAddr_mips;
wire [NB_PC - 1 : 0]            debug_instructionData_mips;
wire                            debug_instructionWrEnb_mips;
wire [NB_PC - 1 : 0]            debug_memoryAddr_mips;
wire [_NB_INDEX_REG - 1 : 0]    debug_regIndex_mips;

wire                            debug_reset_mips;

reg                             step_prev;
wire                            step_posedge;
reg  [NB_PC - 1 : 0]            aux_memdata_1;
reg  [NB_PC - 1 : 0]            aux_memdata_2;
reg  [NB_PC - 1 : 0]            aux_regdata_1;
reg  [NB_PC - 1 : 0]            aux_regdata_2;
reg  [NB_PC - 1 : 0]            aux_addrmem_1;
reg  [NB_PC - 1 : 0]            aux_addrmem_2;
reg  [NB_PC - 1 : 0]            aux_pccount_1;
reg  [NB_PC - 1 : 0]            aux_pccount_2;


// Intermediate registers to achieve timing requirements
always @ (posedge i_fpga_clock)
begin
    aux_memdata_1 <= mips_memData_debug;
    aux_regdata_1 <= mips_regData_debug;
    aux_memdata_2 <= aux_memdata_1;
    aux_regdata_2 <= aux_regdata_1;
    aux_addrmem_1 <= debug_memoryAddr_mips;
    aux_addrmem_2 <= aux_addrmem_1;
    aux_pccount_1 <= mips_pcCount_debug;
    aux_pccount_2 <= aux_pccount_1;
end

MicroGPIO
u_micro
(
    .clock100           (micro_clock_out),
    .gpio_rtl_tri_o     (micro_gpio_rf),
    .gpio_rtl_tri_i     (rf_gpio_micro),
    .reset              (i_fpga_reset), //hard reset
    .sys_clock          (i_fpga_clock), //fpga clock
    .o_lock_clock       (locked_clock),
    .usb_uart_rxd       (RsRx),
    .usb_uart_txd       (RsTx)
);

assign clock_mips = locked_clock & micro_clock_out;


debug_unit
#(
    .NB_GPIO(NB_GPIO),
    .N_REG(N_REG)
 )
    u_dbg_unit
    (
        .i_clock                    (clock_mips),
        .i_reset                    (~i_fpga_reset),
        .i_gpio                     (micro_gpio_rf),
        .i_mips_reg                 (aux_regdata_2),
        .i_mips_mem                 (aux_memdata_2),
        .i_mips_pc                  (aux_pccount_2),

        .o_gpio                     (rf_gpio_micro),
        .o_run                      (debug_run_mips),
        .o_step                     (debug_step_mips),
        .o_instruction_addr         (debug_instructionAddr_mips),
        .o_instruction_data         (debug_instructionData_mips),
        .o_instruction_write_enb    (debug_instructionWrEnb_mips),
        .o_memory_addr              (debug_memoryAddr_mips),
        .o_reg_index                (debug_regIndex_mips),
        .o_reset                    (debug_reset_mips)
    );


// Edge detection for step execution
always @ (posedge clock_mips)
begin
    step_prev <= debug_step_mips;
end
assign step_posedge = ((step_prev == 1'b0) && debug_step_mips == 1'b1) ? 1'b1 : 1'b0;

mips_toplevel
#(
    .NB_DATA    (32),
    .N_REG      (32),
    .NB_PC      (32),
    .MEM_DEPTH  (1024)
 )
 (
    .clk                        (clock_mips),
    .btnC                       (~i_fpga_reset | debug_reset_mips),
    .i_rf_pipe_enabled          (step_posedge | debug_run_mips),
    .i_rf_instruction_addr      (debug_instructionAddr_mips),    
    .i_rf_instruction_data      (debug_instructionData_mips),    
    .i_rf_instruction_write     (debug_instructionWrEnb_mips),
    .i_rf_reg_index_addr        (debug_regIndex_mips),
    .i_rf_memory_addr           (aux_addrmem_2),
    .o_rf_reg_data              (mips_regData_debug),
    .o_rf_memory_data           (mips_memData_debug),
    .o_rf_pc_count              (mips_pcCount_debug)
 );


endmodule
