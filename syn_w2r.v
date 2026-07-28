module sync_w2r #(parameter ADDR_WIDTH=4) (
input rd_clk,
input rd_rst_n,
input [ADDR_WIDTH:0] wr_gray,
output [ADDR_WIDTH:0] wr_gray_sync
);
reg [ADDR_WIDTH:0] wr_gray_sync1;
reg [ADDR_WIDTH:0] wr_gray_sync2;

always@(posedge rd_clk or negedge rd_rst_n) begin
if(!rd_rst_n) begin
wr_gray_sync1<='0;
wr_gray_sync2<='0;
end
else begin
wr_gray_sync1<=wr_gray;
wr_gray_sync2<=wr_gray_sync1;
end
end
assign wr_gray_sync=wr_gray_sync2;
endmodule
