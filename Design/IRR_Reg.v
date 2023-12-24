module IRR(
  // inputs from control logic.....
  input wire [7:0] interrupt_Requests,
  input wire rst,
  output reg [7:0] IRR_Output
);

  // Combinational logic for updating IRR
  always @(interrupt_Requests or ~rst) begin
    if (~rst) begin
      // Reset only the bits that are set in interrupt_Requests
      if (interrupt_Requests[0]) IRR_Output[0] <= 1'b0;
      else if (interrupt_Requests[1]) IRR_Output[1] <= 1'b0;
      else if (interrupt_Requests[2]) IRR_Output[2] <= 1'b0;
      else if (interrupt_Requests[3]) IRR_Output[3] <= 1'b0;
      else if (interrupt_Requests[4]) IRR_Output[4] <= 1'b0;
      else if (interrupt_Requests[5]) IRR_Output[5] <= 1'b0;
      else if (interrupt_Requests[6]) IRR_Output[6] <= 1'b0;
      else if (interrupt_Requests[7]) IRR_Output[7] <= 1'b0;
    end 
    else begin
      // Update IRR based on incoming interrupt requests
      IRR_Output <= interrupt_Requests;
    end
  end

endmodule

// TestBench
/*
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
*/