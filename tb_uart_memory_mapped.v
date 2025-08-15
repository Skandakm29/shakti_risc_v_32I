`timescale 1ns/1ps
`default_nettype none

module tb_apb3_uart;

  // Parameters
  localparam CLOCK_DIV_WIDTH = 20;
  localparam RX_FIFO_DEPTH   = 64;
  localparam DATA_BITS_MAX   = 8;
  localparam CLOCK_DIV_INIT  = 10; // for simulation, make small

  // DUT signals
  reg                      pclk;
  reg                      presetn;
  reg                      psel;
  reg                      penable;
  reg                      pwrite;
  reg  [11:0]              paddr;
  reg  [31:0]              pwdata;
  wire [31:0]              prdata;
  wire                     pready;
  wire                     pslverr;
  wire                     txd;
  reg                      rxd;

  // Instantiate DUT
  apb3_uart #(
    .CLOCK_DIV_WIDTH(CLOCK_DIV_WIDTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
    .DATA_BITS_MAX(DATA_BITS_MAX),
    .CLOCK_DIV_INIT(CLOCK_DIV_INIT)
  ) dut (
    .pclk(pclk),
    .presetn(presetn),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr),
    .txd(txd),
    .rxd(rxd)
  );

  // Clock generation
  initial pclk = 0;
  always #5 pclk = ~pclk; // 100MHz clock

  // Reset
  initial begin
    presetn = 0;
    #20;
    presetn = 1;
  end

  // APB3 write task
  task apb_write(input [11:0] addr, input [31:0] data);
    begin
      @(posedge pclk);
      psel    = 1;
      penable = 1;
      pwrite  = 1;
      paddr   = addr;
      pwdata  = data;
      @(posedge pclk);
      psel    = 0;
      penable = 0;
      pwrite  = 0;
      paddr   = 0;
      pwdata  = 0;
    end
  endtask

  // APB3 read task
  task apb_read(input [11:0] addr, output [31:0] data);
    begin
      @(posedge pclk);
      psel    = 1;
      penable = 1;
      pwrite  = 0;
      paddr   = addr;
      @(posedge pclk);
      data = prdata;
      psel    = 0;
      penable = 0;
      pwrite  = 0;
      paddr   = 0;
    end
  endtask

  // UART RX simulation: sample txd and drive rxd for echo
  initial begin
    rxd = 1;
    forever @(posedge pclk) begin
      // For simple loopback, rxd follows txd after a short delay
      #1 rxd = txd;
    end
  end
   reg [31:0] txstat;
   reg [31:0] rxdata;

  // Test Procedure
  initial begin
    // Wait for reset
    @(posedge presetn);

    // Set UART frame: 8 data bits, no parity, 1 stop
    apb_write(12'h04, 32'h08);

    // Write a byte to UART TX
    apb_write(12'h08, 32'h55); // send 0x55

    // Wait for transmission
    repeat(30) @(posedge pclk);

    // Check TX busy status
    
    apb_read(12'h08, txstat);
    $display("TX Busy Status: %b", txstat[0]);

    // Wait for RX to receive (loopback)
    repeat(50) @(posedge pclk);

    // Read RX data/valid
    
    apb_read(12'h0C, rxdata);
    $display("RX Valid: %b, RX Data: %02x", rxdata[31], rxdata[7:0]);

    // End simulation
    #50;
    $finish;
  end

endmodule
`default_nettype wire
