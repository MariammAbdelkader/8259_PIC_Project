module testbench;

  // Parameters
  parameter CLOCK_PERIOD = 10;  // Time period of the clock 
  
  // Inputs
  reg [7:0] interrupt_request;
  reg [7:0] interrupt_mask;
  reg [7:0] eoi;

  // Outputs
  wire [7:0] in_service_register;

  // Clock generation
  reg clock = 0;

  // Instantiate the ISR module
  PIC_ISR isr_module (
    .interrupt_request(interrupt_request),
    .interrupt_mask(interrupt_mask),
    .eoi(eoi),
    .in_service_register(in_service_register)
  );

  // Initial stimulus
  initial begin
    // Initialize inputs
    interrupt_request = 8'b00000000;
    interrupt_mask = 8'b00000000;
    eoi = 8'b00000000;

    // Apply stimulus
    #10 interrupt_request = 8'b00000001;  // Assuming interrupt is requested
    #10 interrupt_mask = 8'b00000000;     // Unmask the interrupt
    #10 eoi = 8'b00000000;                // No End of Interrupt yet

    
    $display("test1");
    #10 $display("In-Service Register: %b", in_service_register);
    
    
    #10 interrupt_request = 8'b00000001;  // Assuming interrupt is requested
    #10 interrupt_mask = 8'b00000000;     // Unmask the interrupt
    #10 eoi = 8'b00000001;                //  End of Interrupt yet

    
    $display("test2 ");
    #10 $display("In-Service Register: %b", in_service_register);
    
    // Apply stimulus
    #10 interrupt_request = 8'b01010001;  // Assuming interrupt is requested
    #10 interrupt_mask = 8'b01000000;     // Unmask the interrupt
    #10 eoi = 8'b00000000;                // No End of Interrupt yet

    $display("test3");
    #10 $display("In-Service Register: %b", in_service_register);
    
    
    // Apply stimulus
    #10 interrupt_request = 8'b01101001;  // Assuming interrupt is requested
    #10 interrupt_mask =    8'b01010101;     // mask the interrupt
    #10 eoi = 8'b00000000;                // No End of Interrupt yet

    $display("test4");
    #10 $display("In-Service Register: %b", in_service_register);
    
    

    // End simulation
    #10 $finish;
  end

  // Clock generation
/*  always #((CLOCK_PERIOD)/2) $monitor("Time=%0t: ISR=%b", $time, in_service_register);*/

endmodule

