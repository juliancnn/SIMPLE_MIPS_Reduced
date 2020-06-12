`timescale 1ns / 100ps

/*
    Operaciones que debe soportar :
        - setear el registro step
        - limpiar el registro step
        - setear el registro run
        - limpiar el registro run
        - setear intr_addr_low
        - setear intr_addr_high
        - setear intr_data_low
        - setear intr_data_high
        - setear instr_wite_enable
        - limpiar instr_write_enable
        - setear index para seleccionar lectura de algun registro
        - setear memory_read_addr_low
        - setear memory_read_addr_high
        - setear output_data con el mips_data_rf
*/

module debug_unit
#(
    parameter NB_GPIO       = 32,
    parameter NB_PC         = 32,
    parameter N_REG         = 32,
    parameter _NB_INDEX_REG = $clog2(N_REG)
    
 )
 (
    input  wire                             i_clock,
    input  wire                             i_reset,
    input  wire [NB_GPIO - 1 : 0]           i_gpio,

    input  wire [NB_GPIO - 1 : 0]           i_mips_reg,
    input  wire [NB_GPIO - 1 : 0]           i_mips_mem,
    input  wire [NB_GPIO - 1 : 0]           i_mips_pc,


    output wire [NB_GPIO - 1 : 0]           o_gpio,
    output wire                             o_run,
    output wire                             o_step,

    output wire [NB_PC - 1 : 0]             o_instruction_addr,
    output wire [NB_PC - 1 : 0]             o_instruction_data,
    output wire                             o_instruction_write_enb,

    output wire [NB_PC - 1 : 0]             o_memory_addr,
    output wire [_NB_INDEX_REG - 1 : 0]     o_reg_index,
    output wire                             o_reset
 );


localparam NB_ADDR      = 7;
localparam NB_DATA      = 24; // slice of data from i_gpio
localparam NB_HALF      = 16;

localparam POS_DATA     = 0;
localparam POS_ENABLE   = 31;
localparam POS_ADDR     = 16;



localparam [NB_ADDR - 1 : 0]    OP_CLR_ALL              = 'd10;
localparam [NB_ADDR - 1 : 0]    OP_SET_STEP             = 'd11;
localparam [NB_ADDR - 1 : 0]    OP_CLR_STEP             = 'd12;
localparam [NB_ADDR - 1 : 0]    OP_SET_RUN              = 'd13;
localparam [NB_ADDR - 1 : 0]    OP_CLR_RUN              = 'd14;
localparam [NB_ADDR - 1 : 0]    OP_SET_INSTR_ADDR_LOW   = 'd15;
localparam [NB_ADDR - 1 : 0]    OP_SET_INSTR_ADDR_HIGH  = 'd16;
localparam [NB_ADDR - 1 : 0]    OP_SET_INSTR_DATA_LOW   = 'd17;
localparam [NB_ADDR - 1 : 0]    OP_SET_INSTR_DATA_HIGH  = 'd18;
localparam [NB_ADDR - 1 : 0]    OP_SET_INSTR_WRITE_ENB  = 'd19;
localparam [NB_ADDR - 1 : 0]    OP_CLR_INSTR_WRITE_ENB  = 'd20;
localparam [NB_ADDR - 1 : 0]    OP_SET_REG_INDEX        = 'd21;
localparam [NB_ADDR - 1 : 0]    OP_SET_MEM_ADDR_LOW     = 'd22;
localparam [NB_ADDR - 1 : 0]    OP_SET_MEM_ADDR_HIGH    = 'd23;
localparam [NB_ADDR - 1 : 0]    OP_GET_ODATA_MIPS_RF    = 'd24;
localparam [NB_ADDR - 1 : 0]    OP_GET_ODATA_IF_ID      = 'd25;
localparam [NB_ADDR - 1 : 0]    OP_GET_ODATA_ID_EX      = 'd26;
localparam [NB_ADDR - 1 : 0]    OP_GET_ODATA_EX_MEM     = 'd27;
localparam [NB_ADDR - 1 : 0]    OP_GET_ODATA_MEM_WRB    = 'd28;
localparam [NB_ADDR - 1 : 0]    OP_GET_ODATA_MEMORY     = 'd29;
localparam [NB_ADDR - 1 : 0]    OP_GET_ODATA_PC         = 'd30;

localparam [NB_ADDR - 1 : 0]    OP_SET_RESET_UP         = 'd31;
localparam [NB_ADDR - 1 : 0]    OP_SET_RESET_DOWN       = 'd32;



// Input port slice signals
wire [NB_ADDR - 1 : 0]      input_addr;
wire [NB_DATA - 1 : 0]      input_data;
wire                        input_enable;
wire                        clr_all;


//registro para que no joda que hay cosas desconectadas
(* keep = "true" *) reg [NB_GPIO - 1 : 0] todo;

assign input_addr   = i_gpio[POS_ADDR +: NB_ADDR];
assign input_data   = i_gpio[POS_DATA +: NB_DATA] ;
assign input_enable = i_gpio[POS_ENABLE] ;
assign clr_all      = (input_addr == OP_CLR_ALL) ? 1'b1 : 1'b0;

// instruction config regs
reg [NB_HALF - 1 : 0]       instruction_data_low;
reg [NB_HALF - 1 : 0]       instruction_data_high;

reg [NB_HALF - 1 : 0]       instruction_addr_low;
reg [NB_HALF - 1 : 0]       instruction_addr_high;

reg                         instruction_write_enable;

reg                         reset;
// decode_reg_read
reg [_NB_INDEX_REG - 1 : 0] reg_index;

//memory addr read
reg [NB_HALF - 1 : 0]       memory_addr_low;
reg [NB_HALF - 1 : 0]       memory_addr_high;

//Ejecution control
reg                         step;
reg                         run;

reg [NB_GPIO - 1 : 0]       output_data;
reg [NB_GPIO - 1 : 0]       output_data_next;

//Ports

assign o_run                    = run;
assign o_step                   = step;
assign o_instruction_addr       = {instruction_addr_high, instruction_addr_low};
assign o_instruction_data       = {instruction_data_high, instruction_data_low};
assign o_instruction_write_enb  = instruction_write_enable;

assign o_memory_addr            = {memory_addr_high, memory_addr_low};
assign o_reg_index              = reg_index;

assign o_reset                  = reset;

always @ (posedge i_clock)
begin
    todo <= i_gpio;
end
//----------------- write logic ---------------------------//

// Instruction setup
always @ (posedge i_clock)
begin
    if (i_reset || clr_all)
        instruction_data_low <= 0;
    else if (input_enable && input_addr == OP_SET_INSTR_DATA_LOW )
        instruction_data_low <= input_data[0 +: NB_HALF];
end

always @ (posedge i_clock)
begin
    if (i_reset || clr_all)
        instruction_data_high <= 0;
    else if (input_enable && input_addr == OP_SET_INSTR_DATA_HIGH)
        instruction_data_high <= input_data[0 +: NB_HALF];
end

always @ (posedge i_clock)
begin
    if (i_reset || clr_all)
        instruction_addr_low <= 0;
    else if (input_enable && input_addr == OP_SET_INSTR_ADDR_LOW )
        instruction_addr_low <= input_data[0 +: NB_HALF];
end

always @ (posedge i_clock)
begin
    if (i_reset || clr_all)
        instruction_addr_high <= 0;
    else if (input_enable && input_addr == OP_SET_INSTR_ADDR_HIGH )
        instruction_addr_high <= input_data[0 +: NB_HALF];
end

always @ (posedge i_clock)
begin
    if (i_reset || clr_all || (input_addr == OP_CLR_INSTR_WRITE_ENB))
        instruction_write_enable <= 0;
    else if (input_enable && input_addr == OP_SET_INSTR_WRITE_ENB )
        instruction_write_enable <= 1;
end

//register index
always @ (posedge i_clock)
begin
    if (i_reset || clr_all)
        reg_index <= 0;
    else if (input_enable && input_addr == OP_SET_REG_INDEX)
        reg_index <= input_data[0 +: _NB_INDEX_REG];
end

// memory
always @ (posedge i_clock)
begin
    if (i_reset || clr_all)
        memory_addr_low <= 0;
    else if (input_enable && input_addr == OP_SET_MEM_ADDR_LOW )
        memory_addr_low <= input_data[0 +: NB_HALF];
end

always @ (posedge i_clock)
begin
    if (i_reset || clr_all)
        memory_addr_high <= 0;
    else if (input_enable && input_addr == OP_SET_MEM_ADDR_HIGH )
        memory_addr_high <= input_data[0 +: NB_HALF];
end


//Ejecution control
always @ (posedge i_clock)
begin
    if (i_reset || clr_all || (input_addr == OP_CLR_RUN))
        run <= 0;
    else if (input_enable && input_addr == OP_SET_RUN )
        run <= 1;
end

always @ (posedge i_clock)
begin
    if (i_reset || clr_all || (input_addr == OP_CLR_STEP))
        step <= 0;
    else if (input_enable && input_addr == OP_SET_STEP)
        step <= 1;
end

always @ (posedge i_clock)
begin
    if (i_reset || clr_all || (input_addr == OP_SET_RESET_DOWN))
        reset <= 0;
    else if (input_enable && input_addr == OP_SET_RESET_UP)
        reset <= 1;
end


//----------------- read logic ---------------------------//
always @ (*)
begin
    output_data_next = output_data;
    case (input_addr)
    OP_GET_ODATA_MIPS_RF:   output_data_next = i_mips_reg;
    OP_GET_ODATA_MEMORY :   output_data_next = i_mips_mem;
    OP_GET_ODATA_PC     :   output_data_next = i_mips_pc;
    endcase
end



always @ (posedge i_clock)
begin
    if (i_reset || clr_all)
        output_data <= 0;
    else
        output_data <= output_data_next;
end

assign o_gpio = output_data;


endmodule
