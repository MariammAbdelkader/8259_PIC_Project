module IRR(
  input wire [7:0] interrupt_Requests,
  //inputs from control logic
  input[7:0] clear_IRR,
  //input wire rst,
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

