module Priority_Resolver_tb;

  // Inputs
  reg [7:0] irr;
  reg [7:0] isr;
  reg [7:0] imr;
  reg [2:0] priority_rotate;

  // Outputs
  wire [7:0] interrupt_vector;

  // Instantiate the Priority_Resolver module
  Priority_Resolver dut (
    .irr(irr),
    .isr(isr),
    .imr(imr),
    .priority_rotate(priority_rotate),
    .interrupt_vector(interrupt_vector)
  );

  // Clock
  reg clk;

  // Initialize inputs
  initial begin
    irr = 8'b00000000;
    isr = 8'b00000000;
    imr = 8'b00000000;
    priority_rotate = 3'b000;
    clk = 0;
  end

  // Toggle clock
  always #5 clk = ~clk;

  // Apply inputs and display outputs for each test case
  initial begin
    // Test case 1
    irr = 8'b11010010;
    isr = 8'b00100000;
    imr = 8'b11111111;
    priority_rotate = 3'b001;

    #10;
    $display("Test Case 1:");
    $display("irr = %b", irr);
    $display("isr = %b", isr);
    $display("imr = %b", imr);
    $display("priority_rotate = %b", priority_rotate);
    $display("interrupt_vector = %b", interrupt_vector);

    // Test case 2
    irr = 8'b11111111;
    isr = 8'b00000000;
    imr = 8'b11111111;
    priority_rotate = 3'b000;

    #10;
    $display("Test Case 2:");
    $display("irr = %b", irr);
    $display("isr = %b", isr);
    $display("imr = %b", imr);
    $display("priority_rotate = %b", priority_rotate);
    $display("interrupt_vector = %b", interrupt_vector);

    // Add more test cases if needed

    // End simulation
    #10;
    $finish;
  end

  // Display outputs on every positive edge of the clock
  always @(posedge clk) begin
    $display("interrupt_vector = %b", interrupt_vector);
  end

endmodule
