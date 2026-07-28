module empty_logic
#(
    parameter ADDR_WIDTH = 4
)
(
    input                       rd_clk,
    input                       rd_rst_n,
    input  [ADDR_WIDTH:0]       rd_gray_next,
    input  [ADDR_WIDTH:0]       wr_gray_sync,
    output reg                  empty
);
 
wire empty_val;
assign empty_val = (rd_gray_next == wr_gray_sync);

always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n)
        empty <= 1'b1;
    else
        empty <= empty_val;
end
 
endmodule
