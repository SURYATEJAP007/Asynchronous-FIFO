module async_fifo_tb;

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 4;



reg                     wr_clk;
reg                     wr_rst_n;
reg                     wr_en;
reg [DATA_WIDTH-1:0]    wr_data;


reg                     rd_clk;
reg                     rd_rst_n;
reg                     rd_en;

wire [DATA_WIDTH-1:0]   rd_data;


wire                    full;
wire                    empty;


integer i;
reg [DATA_WIDTH-1:0] expected_data;
reg [DATA_WIDTH-1:0] expected_mem [0:15];


async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
u_async_fifo
(
    .wr_clk     (wr_clk),
    .wr_rst_n   (wr_rst_n),
    .wr_en      (wr_en),
    .wr_data    (wr_data),

    .rd_clk     (rd_clk),
    .rd_rst_n   (rd_rst_n),
    .rd_en      (rd_en),
    .rd_data    (rd_data),

    .full       (full),
    .empty      (empty)
);


initial begin
    wr_clk = 0;
    forever #5 wr_clk = ~wr_clk;
end



initial begin
    rd_clk = 0;
    forever #7 rd_clk = ~rd_clk;
end


initial begin
    wr_en   = 0;
    rd_en   = 0;
    wr_data = 0;
end


initial begin

    reset_fifo();

    single_write_test();

    reset_fifo();

    single_write_read_test();

    reset_fifo();

    multiple_write_read_test();

    reset_fifo();

    full_test();

    reset_fifo();

    empty_test();

    $display("\n================================");
    $display("ALL TESTS COMPLETED");
    $display("================================");

    #20;

    $finish;

end

//======================================================
// Reset Test
//======================================================

task reset_fifo;

begin

    $display("\n--------------------------------");
    $display("RESETTING FIFO");
    $display("--------------------------------");

    wr_rst_n = 0;
    rd_rst_n = 0;

    wr_en = 0;
    rd_en = 0;
    wr_data = 0;

   fork
begin
    repeat(2) @(posedge wr_clk);
    wr_rst_n = 1;
end

begin
    repeat(2) @(posedge rd_clk);
    rd_rst_n = 1;
end
join

    #2;

    if(empty && !full)
        $display("RESET TEST PASS");
    else
        $display("RESET TEST FAIL");

end

endtask

//======================================================
// Single Write Test
//======================================================

task single_write_test;

begin

    $display("\n--------------------------------");
    $display("SINGLE WRITE TEST");
    $display("--------------------------------");

    wr_data = 8'hA5;
    wr_en   = 1;

    @(posedge wr_clk);

    wr_en = 0;

    // empty is computed in the read domain from a 2-flop synchronized
    // version of wr_gray, so it takes a couple of rd_clk edges to update.
    // Wait on the signal itself instead of guessing a fixed delay,
    // with a timeout so a genuinely broken sync path doesn't hang forever.
    // (Written with plain fork/join + named-block disable so it compiles
    // as Verilog-2001, not just SystemVerilog.)
    fork
        begin : wait_block
            wait(empty == 0);
            disable timeout_block;
        end
        begin : timeout_block
            #100;
            $display("SINGLE WRITE TEST TIMEOUT - check sync path");
            disable wait_block;
        end
    join

    if(empty == 0)
        $display("SINGLE WRITE TEST PASS");
    else
        $display("SINGLE WRITE TEST FAIL");

end

endtask

//======================================================
// Single Write Read Test
//======================================================

task single_write_read_test;

begin

    $display("\n--------------------------------");
    $display("SINGLE WRITE READ TEST");
    $display("--------------------------------");

    expected_data = 8'hA5;

    wr_data = expected_data;
    wr_en   = 1;

    @(posedge wr_clk);

    wr_en = 0;

    wait(empty == 0);

    rd_en = 1;

    @(posedge rd_clk);

    rd_en = 0;

    #1;

 if(rd_data == expected_data)
    $display("WRITE READ TEST PASS");
else begin
    $display("WRITE READ TEST FAIL");
    $display("Expected = %h", expected_data);
    $display("Received = %h", rd_data);
end
end

endtask

//======================================================
// Multiple Write Read Test
//======================================================

task multiple_write_read_test;

begin

    $display("\n--------------------------------");
    $display("MULTIPLE WRITE READ TEST");
    $display("--------------------------------");

 
    expected_mem[0] = 8'hA1;
    expected_mem[1] = 8'hB2;
    expected_mem[2] = 8'hC3;
    expected_mem[3] = 8'hD4;



    $display("Writing Data");

    wr_en = 1;

    for(i=0;i<4;i=i+1)
    begin

        wr_data = expected_mem[i];

        @(posedge wr_clk);

        #1;

        $display("WRITE[%0d] = %h",i,wr_data);

    end

    wr_en = 0;


    $display("Reading Data");

    for(i=0;i<4;i=i+1)
    begin

        wait(empty == 0);

        rd_en = 1;

        @(posedge rd_clk);

        rd_en = 0;

        #1;

        if(rd_data == expected_mem[i])

            $display("READ[%0d] PASS  Expected=%h  Received=%h",
                      i,
                      expected_mem[i],
                      rd_data);

        else

            $display("READ[%0d] FAIL  Expected=%h  Received=%h",
                      i,
                      expected_mem[i],
                      rd_data);

    end

end

endtask

//======================================================
// Full Condition Test
//======================================================

task full_test;

begin

    $display("\n--------------------------------");
    $display("FULL CONDITION TEST");
    $display("--------------------------------");



    wr_en = 1;

    for(i=0;i<(1<<ADDR_WIDTH);i=i+1)
    begin

        wr_data = i;

        @(posedge wr_clk);

        #1;

        $display("WRITE[%0d] = %h",i,wr_data);

    end

    wr_en = 0;


    #2;

    if(full)
        $display("FULL FLAG TEST PASS");
    else
        $display("FULL FLAG TEST FAIL");


    wr_data = 8'hFF;
    wr_en   = 1;

    @(posedge wr_clk);

    wr_en = 0;
#2;

    if(full)
        $display("WRITE BLOCK TEST PASS");
    else
        $display("WRITE BLOCK TEST FAIL");

end

endtask

//======================================================
// Empty Condition Test
//======================================================

task empty_test;

begin

    $display("\n--------------------------------");
    $display("EMPTY CONDITION TEST");
    $display("--------------------------------");


    while(!empty)
    begin

        rd_en = 1;

        @(posedge rd_clk);

        rd_en = 0;

        #1;

    end


    if(empty)
        $display("EMPTY FLAG TEST PASS");
    else
        $display("EMPTY FLAG TEST FAIL");


    rd_en = 1;

    @(posedge rd_clk);

    rd_en = 0;

    #2;

    if(empty)
        $display("READ BLOCK TEST PASS");
    else
        $display("READ BLOCK TEST FAIL");

end

endtask




endmodule