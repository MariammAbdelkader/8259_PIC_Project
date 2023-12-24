// TestBench
module IRR_tb;

  // Inputs
  reg [7:0] interrupt_Requests;
  reg rst;

  // Outputs
  wire [7:0] IRR_Output;

  // Instantiate the module under test
  IRR2 test (
    .interrupt_Requests(interrupt_Requests),
    .rst(rst),
    .IRR_Output(IRR_Output)
  );

  // Initial stimulus
  initial begin
    // Initialize inputs
    interrupt_Requests = 8'b00000010;  // Initial interrupt requests
    rst = 1;
    #10 rst = 0;  // Assert reset
    #10 interrupt_Requests = 8'b01000000;
    #10 interrupt_Requests = 8'b01001000;
    #10 rst = 1;  // Release Reset
    #10 rst = 0;

    #100 $stop;  // Stop simulation after some time
  end

  // Monitor for observing outputs
  always @(*) begin
    $display("Time %0t: interrupt_Requests = %b, IRR_Output = %b", $time, interrupt_Requests, IRR_Output);
  end

endmodule
