module IRR(
  input wire [7:0] interrupt_Requests,
  input [7:0] clear_IRR,
  input freeze,
  inout reg [7:0] IRR_Output_wire
);

// to store the output after the change of the clear signal
reg [7:0] store_request;
reg [7:0] IRR_Output;
assign IRR_Output_wire = IRR_Output;
  
  // Combinational logic for updating IRR
always @(*) begin
    store_request=interrupt_Requests;
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
