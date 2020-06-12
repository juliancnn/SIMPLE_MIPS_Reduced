
module rom_memory
#(
   parameter ROM_WIDTH = 64,
   parameter ROM_ADDR_BITS = 5,
   parameter FILE = "",
   parameter MAX_SIZE = 1024
 )

 (
   input  wire                          i_clock,
   input  wire                          i_write_enable,
   input  wire [ROM_ADDR_BITS - 1 : 0]  i_write_addr,
   input  wire [ROM_WIDTH     - 1 : 0]  i_data,
   input  wire [ROM_ADDR_BITS - 1 : 0]  i_read_addr,

   output wire [ROM_WIDTH-1 : 0]        o_data
 );

reg [ROM_WIDTH-1:0] rom [MAX_SIZE - 1   :0];
assign o_data = rom[i_read_addr];

always @ (posedge i_clock)
begin
    if (i_write_enable)
        rom[i_write_addr] <= i_data;
end


//Memory initialization
initial
    $readmemb(FILE, rom, 0);


endmodule
