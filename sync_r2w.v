module sync_r2w
#(
    parameter ADDR_WIDTH = 4
)
(
    input                   wr_clk,
    input                   wr_rst_n,

    input  [ADDR_WIDTH:0]   rd_gray,

    output  [ADDR_WIDTH:0]   rd_gray_sync
);
reg [ADDR_WIDTH:0] rd_gray_sync1;
reg [ADDR_WIDTH:0] rd_gray_sync2;


always@(posedge wr_clk or negedge wr_rst_n) begin
if (!wr_rst_n) begin
rd_gray_sync1<='0;
rd_gray_sync2<='0;
end
else begin
rd_gray_sync1<=rd_gray;
rd_gray_sync2<=rd_gray_sync1;
end
end
assign  rd_gray_sync=rd_gray_sync2;
endmodule