module IRR(
  input wire [7:0] interrupt_Requests,
  //input from control logic
  input[7:0] clear_IRR,
  //input wire rst,
  output reg [7:0] IRR_Output
);
 
  // Combinational logic for updating IRR
  always @(interrupt_Requests or clear_IRR) begin

// Reset only the bits that will be served at that time
    if (clear_IRR) 
      IRR_Output=IRR_Output& (~clear_IRR);

    else 
      // Update IRR based on incoming interrupt requests
      IRR_Output <= interrupt_Requests;
  end

endmodule
