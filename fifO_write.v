module wr_ptr
#(
    parameter ADDR_WIDTH = 4
)
(
    input  wire                   wr_clk,
    input  wire                   wr_rst_n,
    input  wire                   wr_en,
    input  wire                   full,
    output reg  [ADDR_WIDTH:0]    wr_bin,
    output reg  [ADDR_WIDTH:0]    wr_gray,
    output wire [ADDR_WIDTH:0]    wr_gray_next
);
 
wire [ADDR_WIDTH:0] wr_bin_next;
 
assign wr_bin_next = wr_bin + (wr_en & ~full);
assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
 
always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        wr_bin  <= '0;
        wr_gray <= '0;
    end
    else begin
        wr_bin  <= wr_bin_next;
        wr_gray <= wr_gray_next;
    end
end
 
endmodule
