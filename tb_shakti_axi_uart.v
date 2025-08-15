`timescale 1ns / 1ps
`default_nettype none
module tb_shakti_axi_uart;

  // Clock and reset
  reg aclk;
  reg aresetn;

  // AXI4-Lite signals
  reg  [31:0] s_axi_awaddr;
  reg         s_axi_awvalid;
  wire        s_axi_awready;
  reg  [31:0] s_axi_wdata;
  reg  [3:0]  s_axi_wstrb;
  reg         s_axi_wvalid;
  wire        s_axi_wready;
  wire [1:0]  s_axi_bresp;
  wire        s_axi_bvalid;
  reg         s_axi_bready;
  reg  [31:0] s_axi_araddr;
  reg         s_axi_arvalid;
  wire        s_axi_arready;
  wire [31:0] s_axi_rdata;
  wire [1:0]  s_axi_rresp;
  wire        s_axi_rvalid;
  reg         s_axi_rready;

  // UART pins
  wire uart_txd;
  reg  uart_rxd;

  // Instantiate DUT
  shakti_axi_uart #(
    .CLOCK_DIV_WIDTH(20),
    .RX_FIFO_DEPTH(64)
  ) dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .uart_txd(uart_txd),
    .uart_rxd(uart_rxd)
  );

  // Clock generation
  initial aclk = 0;
  always #5 aclk = ~aclk; 

  // Reset sequence
  initial begin
    aresetn = 0;
    #20;
    aresetn = 1;
  end

  task axi_write(input [31:0] addr, input [31:0] data);
    begin
      s_axi_awaddr  = addr;
      s_axi_awvalid = 1;
      s_axi_wdata   = data;
      s_axi_wstrb   = 4'b1111;
      s_axi_wvalid  = 1;
      s_axi_bready  = 1;

      wait (s_axi_awready && s_axi_wready);
      s_axi_awvalid = 0;
      s_axi_wvalid  = 0;

      wait (s_axi_bvalid);
      s_axi_bready = 0;
      #10;
    end
  endtask

  // AXI read task
  task axi_read(input [31:0] addr);
    begin
      s_axi_araddr  = addr;
      s_axi_arvalid = 1;
      s_axi_rready  = 1;

      wait (s_axi_arready);
      s_axi_arvalid = 0;

      wait (s_axi_rvalid);
      $display("Read from 0x%08X = 0x%08X", addr, s_axi_rdata);
      s_axi_rready = 0;
      #10;
    end
  endtask

  // Test sequence
  initial begin
    // Initialize inputs
    s_axi_awaddr  = 0;
    s_axi_awvalid = 0;
    s_axi_wdata   = 0;
    s_axi_wstrb   = 0;
    s_axi_wvalid  = 0;
    s_axi_bready  = 0;
    s_axi_araddr  = 0;
    s_axi_arvalid = 0;
    s_axi_rready  = 0;
    uart_rxd      = 1;

    #50;

    // Write to UART control register (example address)
    axi_write(32'h0000_0000, 32'h0000_0001); // Enable UART

    // Write to UART TX register (example address)
    axi_write(32'h0000_0004, 32'h0000_0041); // Send 'A'

    // Read UART status register (example address)
    axi_read(32'h0000_0008);

    #100;
    $finish;
  end

endmodule
`default_nettype wire
