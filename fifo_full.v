module full_logic
#(
    parameter ADDR_WIDTH = 4
)
(
    input                       wr_clk,
    input                       wr_rst_n,
    input  [ADDR_WIDTH:0]       wr_gray_next,
    input  [ADDR_WIDTH:0]       rd_gray_sync,
    output reg                  full
);
 

wire full_val;
assign full_val = (wr_gray_next == {~rd_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                                      rd_gray_sync[ADDR_WIDTH-2:0]});
 
always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n)
        full <= 1'b0;
    else
        full <= full_val;
end
 
endmodule