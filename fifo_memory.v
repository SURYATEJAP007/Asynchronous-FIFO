module fifo_mem
#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)
(
   
    input                     wr_clk,
    input                     wr_en,
    input  [ADDR_WIDTH-1:0]   wr_addr,
    input  [DATA_WIDTH-1:0]   wr_data,

    
    input                     rd_clk,
    input                     rd_en,
    input  [ADDR_WIDTH-1:0]   rd_addr,
    output reg [DATA_WIDTH-1:0] rd_data
);

reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];


// Write operation
always @(posedge wr_clk)
begin
    if(wr_en)
        mem[wr_addr] <= wr_data;
end


// Read operation
always @(posedge rd_clk)
begin
    if(rd_en)
        rd_data <= mem[rd_addr];
end

endmodule
