module IRR(
  input wire [7:0] interrupt_Requests,
  input [7:0] clear_IRR,
  input freeze,
  output reg [7:0] IRR_Output
);

// to store the output after the change of the clear signal
reg[7:0] store_request;
assign store_request=interrupt_Requests;
  
  // Combinational logic for updating IRR
  always @(*) begin

    // If freeze is active, maintain the current IRR state
    if (freeze) begin
     // no operation
    end

    // Reset only the bits that will be served at that time
    else if (clear_IRR) begin
      //store_request = interrupt_Requests;
      IRR_Output = store_request & (~clear_IRR);
      store_request = IRR_Output;
    end

    // Update IRR based on incoming interrupt requests
    else 
      IRR_Output = interrupt_Requests;
 
  end

endmodule
