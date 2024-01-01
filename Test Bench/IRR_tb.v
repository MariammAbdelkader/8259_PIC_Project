module IRR_tb;

  // Inputs
  reg [7:0] interrupt_Requests;
  reg [7:0] clear_bits;

  // Outputs
  wire [7:0] IRR_Output;

  // Instantiate the module under test
  IRR test (
    .interrupt_Requests(interrupt_Requests),
    .clear_IRR(clear_bits),
    .IRR_Output(IRR_Output)
  );

  // Initial stimulus
  initial begin
    // Initialize inputs
    interrupt_Requests = 8'b00010010;  // Initial interrupt requests
    #10 clear_bits = 8'b00000010;
    #10 clear_bits = 8'b00010000;
    #10 interrupt_Requests = 8'b10000000;
    #10 clear_bits = 8'b10000000;

    #100 $stop;  // Stop simulation after some time
  end

  // Monitor for observing outputs
  always @(*) begin
    $display("Time %0t: interrupt_Requests = %b, IRR_Output = %b", $time, interrupt_Requests, IRR_Output);
  end

endmodule
