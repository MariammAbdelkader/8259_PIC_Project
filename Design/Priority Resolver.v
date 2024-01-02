
/***********************************************************
 * File: Priority Resolver.v
 * Author: Mariam Mohamed Abdelkader
 * Description:
 ************************************************************/
 
module Priority_Resolver (
  //inputs
  input  [7:0]  irr,  //8-bit input representing the interrupt request register.
  input   [7:0]  isr, // 8-bit input representing the in-service register.
  input  [7:0]  imr,  //8-bit input representing the interrupt mask.
  input  [2:0]  priority_rotate, //3-bit input representing the priority rotation value.
  
  // Outputs
  inout [7:0]  interrupt_vector_wire // 8-bit output representing the resolved interrupt.
);
  reg [7:0]  interrupt_vector;
assign interrupt_vector_wire = interrupt_vector;
  // Masked flags
  wire [7:0]  masked_irr;
  wire [7:0]  masked_isr ;
  //Masking Disabled Interrupts:
  assign masked_irr= irr & ~imr;   //filters out disabled interrupts from the IRR
  assign masked_isr = isr & ~ imr;    //filters out disabled interrupts from the ISR

  // Resolve priority
  wire [7:0]  rotated_irr;    //Stores results of irr aftr rotation operations
  reg [7:0]   rotated_isr;   //Stores results of isr aftr rotation operations
 reg [7:0]  priority_mask;        // 8-bit representing priority mask based on the highest priority bit set in the rotated_isr register.
  wire [7:0]  rotated_interrupt;    // 8-bit representing calculated rotated interrupt based on the rotated_irr, priority_mask, and bitwise AND operations.

   //Rotating Interrupt Request

  assign rotated_irr = (masked_irr >> priority_rotate)|(masked_irr <<(8-priority_rotate))& 8'hFF;
  // Rotate in_service 
  always @* begin
  	rotated_isr= (masked_isr >> priority_rotate)|(masked_isr <<(8-priority_rotate))& 8'hFF;
    


  // Priority mask calculation
  //based on the heighest prioity bit set in rotated_isr
  	priority_mask = ( rotated_isr[0]) ? 8'b00000000 :
                         ( rotated_isr[1]) ? 8'b00000001 :
                         ( rotated_isr[2]) ? 8'b00000011 :
                         ( rotated_isr[3]) ? 8'b00000111 :
                         ( rotated_isr[4]) ? 8'b00001111 :
                         ( rotated_isr[5]) ? 8'b00011111 :
                         ( rotated_isr[6]) ? 8'b00111111 :
                         ( rotated_isr[7]) ? 8'b01111111 :
                                             8'b11111111;
                                                

  end

  assign rotated_interrupt = resolv_priority(rotated_irr) & priority_mask;
// final interrupt vector after de-rotation
  always @* begin
  assign interrupt_vector = (rotated_interrupt << priority_rotate)|(rotated_interrupt>>(8-priority_rotate))&8'hFF;
  end
function [7:0] resolv_priority (input [7:0] request);
  integer i;
  begin 
    for (i = 0; i < 8; i = i + 1) begin
      if (request[i] == 1'b1) begin
        resolv_priority = 8'b1 << i;
        i=8;//break
      end
    end

    if (i == 8) resolv_priority = 8'b00000000;
  end  
endfunction

endmodule



