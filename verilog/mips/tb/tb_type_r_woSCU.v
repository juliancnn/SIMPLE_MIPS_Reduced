`timescale 1ns / 100ps


module tb_type_r_woSCU;

reg clk;
reg rst;
reg pipe_enabled;

initial
begin
    clk = 1'b0;
    rst = 1'b0;
    pipe_enabled  = 1'b1;
    #3 rst = 1'b1;
    #5 rst = 1'b0;
end

always #1 clk = ~clk;


mips_toplevel
#(
)
u_mips
(
.clk(clk),
.sw({pipe_enabled, rst})
);
 
endmodule
