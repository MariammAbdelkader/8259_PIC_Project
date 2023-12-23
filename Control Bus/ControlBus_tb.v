`timescale 1ns/1ns

module ControlBus_tb;

  // Inputs
  reg reset;
  reg CS, rd_enable, wr_enable, A1;
  reg [7:0] bi_data_bus;

  // Outputs
  wire [7:0] internal_bus;
  wire write_ICW_1, write_ICW2, write_ICW4, write_OCW1, write_OCW2, write_OCW3, read;

  // Instantiate the module under test
  ContolBus dut (
    .reset(reset),
    .CS(CS),
    .rd_enable(rd_enable),
    .wr_enable(wr_enable),
    .A1(A1),
    .bi_data_bus(bi_data_bus),
    .internal_bus(internal_bus),
    .write_ICW_1(write_ICW_1),
    .write_ICW2(write_ICW2),
    .write_ICW4(write_ICW4),
    .write_OCW1(write_OCW1),
    .write_OCW2(write_OCW2),
    .write_OCW3(write_OCW3),
    .read(read)
  );

  // Initial block for test bench initialization
  initial begin
    // Initialize inputs
    reset = 0;
    CS = 1;
    rd_enable = 1;
    wr_enable = 1;
    A1 = 1;
    bi_data_bus = 8'b10101010; // Some initial data

    // Apply stimulus, Assuming some delay between operations
    #10 reset = 1; // Assert reset
    #10 reset = 0; // De-assert reset
    #10 CS = 0;  // Enable the chip
    #10 wr_enable = 0;  // Write operation
    #10 CS = 1;  // Disable the chip
    #10 rd_enable = 0;  // Read operation

  end

endmodule
