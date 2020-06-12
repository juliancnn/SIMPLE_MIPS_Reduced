`timescale 1ns / 100ps

module tb_instruccion_fetch;



reg tb_clk;
reg tb_rst;


instruccion_fetch #() int_tb
(
    .i_clk(tb_clk),
    .i_rst(tb_rst),
    .i_pc_enabled(1'b0)
    
);


initial
begin
    tb_clk = 0;
    tb_rst = 1;
    #5
    tb_rst = 0;
end

always #1 tb_clk = ~tb_clk;

endmodule
