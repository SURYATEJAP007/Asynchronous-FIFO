module async_fifo
#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)
(
    // Write Interface
    input                      wr_clk,
    input                      wr_rst_n,
    input                      wr_en,
    input  [DATA_WIDTH-1:0]    wr_data,
    // Read Interface
    input                      rd_clk,
    input                      rd_rst_n,
    input                      rd_en,
    output [DATA_WIDTH-1:0]    rd_data,
    // Status
    output                     full,
    output                     empty
);

wire [ADDR_WIDTH:0] wr_bin;
wire [ADDR_WIDTH:0] wr_gray;
wire [ADDR_WIDTH:0] wr_gray_next;
wire [ADDR_WIDTH:0] rd_bin;
wire [ADDR_WIDTH:0] rd_gray;
wire [ADDR_WIDTH:0] rd_gray_next;
wire [ADDR_WIDTH:0] rd_gray_sync;
wire [ADDR_WIDTH:0] wr_gray_sync;
wire [ADDR_WIDTH-1:0] wr_addr;
wire [ADDR_WIDTH-1:0] rd_addr;

wr_ptr #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_wr_ptr (
    .wr_clk      (wr_clk),
    .wr_rst_n    (wr_rst_n),
    .wr_en       (wr_en),
    .full        (full),
    .wr_bin      (wr_bin),
    .wr_gray     (wr_gray),
    .wr_gray_next(wr_gray_next)
);

rd_ptr #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_rd_ptr (
    .rd_clk      (rd_clk),
    .rd_rst_n    (rd_rst_n),
    .rd_en       (rd_en),
    .empty       (empty),
    .rd_bin      (rd_bin),
    .rd_gray     (rd_gray),
    .rd_gray_next(rd_gray_next)
);

sync_r2w #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_sync_r2w (
    .wr_clk      (wr_clk),
    .wr_rst_n    (wr_rst_n),
    .rd_gray     (rd_gray),
    .rd_gray_sync(rd_gray_sync)
);

sync_w2r #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_sync_w2r (
    .rd_clk      (rd_clk),
    .rd_rst_n    (rd_rst_n),
    .wr_gray     (wr_gray),
    .wr_gray_sync(wr_gray_sync)
);

full_logic #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_full_logic (
    .wr_clk      (wr_clk),
    .wr_rst_n    (wr_rst_n),
    .wr_gray_next(wr_gray_next),
    .rd_gray_sync(rd_gray_sync),
    .full        (full)
);

empty_logic #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_empty_logic (
    .rd_clk      (rd_clk),
    .rd_rst_n    (rd_rst_n),
    .rd_gray_next(rd_gray_next),
    .wr_gray_sync(wr_gray_sync),
    .empty       (empty)
);

fifo_mem #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_fifo_mem (
    .wr_clk  (wr_clk),
    .wr_en   (wr_en && !full),
    .wr_addr (wr_addr),
    .wr_data (wr_data),
    .rd_clk  (rd_clk),
    .rd_en   (rd_en && !empty),
    .rd_addr (rd_addr),
    .rd_data (rd_data)
);

assign wr_addr = wr_bin[ADDR_WIDTH-1:0];
assign rd_addr = rd_bin[ADDR_WIDTH-1:0];

endmodule
