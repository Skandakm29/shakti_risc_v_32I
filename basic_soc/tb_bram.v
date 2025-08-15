`timescale 1ns / 1ps

module bram_tb;

    // Testbench signals
    reg clk;
    reg [31:0] addr;
    wire [31:0] rdata;

    // Instantiate the bram module
    bram uut (
        .clk(clk),
        .addr(addr),
        .rdata(rdata)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test stimulus
    initial begin
        
        // Wait for global reset
        #20;

        // Test different address reads
        addr = 0;      #10; $display("rdata @ addr %h = %h", addr, rdata);
        addr = 4;      #10; $display("rdata @ addr %h = %h", addr, rdata);
        addr = 8;      #10; $display("rdata @ addr %h = %h", addr, rdata);
        addr = 1020;   #10; $display("rdata @ addr %h = %h", addr, rdata);
        addr = 4096;   #10; $display("rdata @ addr %h = %h", addr, rdata); 

        #20;
        $finish;
    end

endmodule
