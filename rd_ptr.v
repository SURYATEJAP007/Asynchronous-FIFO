module rd_ptr
#(
    parameter ADDR_WIDTH = 4
)
(
    input                       rd_clk,
    input                       rd_rst_n,
    input                       rd_en,
    input                       empty,
    output reg  [ADDR_WIDTH:0]  rd_bin,
    output reg  [ADDR_WIDTH:0]  rd_gray,
    output wire [ADDR_WIDTH:0]  rd_gray_next
);
 
wire [ADDR_WIDTH:0] rd_bin_next;
 
assign rd_bin_next  = rd_bin + (rd_en & ~empty);
assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
 

always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        rd_bin  <= '0;
        rd_gray <= '0;
    end
    else begin
        rd_bin  <= rd_bin_next;
        rd_gray <= rd_gray_next;
    end
end
 
endmodule
