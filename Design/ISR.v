// Module: ISR
// Author: Carol Maged
//

module PIC_ISR (
   // inputs 
  input wire [7:0] interrupt_request,                // Input for interrupt requests
  input wire [7:0] interrupt_mask,                   // Input from interrupt mask register 
  input wire [7:0]  eoi,                              // Input for End of Interrupt (EOI) - It resets the bit of ISR
  
  // output
  output reg [7:0] in_service_register                // Output for in-service register
);

  reg [7:0] isr_reg;  // Internal register to store the in-service interrupt
  
  //
  // Asynchronous set logic with priority and mask handling
  //
  always @* begin
    //
    // Check if the interrupt is higher priority, not masked, and not EOI
    //
    if ((interrupt_request & ~interrupt_mask & ~eoi) != 8'b00000000)
    begin
      isr_reg = interrupt_request & ~interrupt_mask;  // Set isr_reg based on interrupt_request and interrupt_mask
    end
     else if((interrupt_request & ~interrupt_mask & ~eoi) == 8'b00000000)
    begin
      isr_reg = 8'b00000000;  // Set isr_reg based on interrupt_request and interrupt_mask
    end
    
    // 
    // Check end of interrupt ------> set interrupt register = 0  
    //
    if (eoi)
    begin
      isr_reg =8'b00000000;  // Reset isr_reg when EOI is true
    end
    
  end

  // Output the ISR
  always @* begin
    in_service_register <= isr_reg;  // Output in-service register
  end

endmodule
