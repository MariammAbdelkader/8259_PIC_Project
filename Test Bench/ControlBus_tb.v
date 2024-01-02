`timescale 1ns/1ns

module ControlBus_tb;

  // Inputs
  reg CS, rd_enable, wr_enable, A1;
  reg [7:0] bi_data_bus;

  // Outputs
  wire [7:0] internal_bus;
  wire write_ICW_1, write_ICW2_4, write_OCW1, write_OCW2, write_OCW3, read;

  // Instantiate the module under test
  ControlBus dut (
    .CS(CS),
    .rd_enable(rd_enable),
    .wr_enable(wr_enable),
    .A1(A1),
    .bi_data_bus(bi_data_bus),
    .internal_bus(internal_bus),
    .write_ICW_1(write_ICW_1),
    .write_ICW2_4(write_ICW2_4),
    .write_OCW1(write_OCW1),
    .write_OCW2(write_OCW2),
    .write_OCW3(write_OCW3),
    .read(read)
  );

  // Initial block for test bench initialization
  initial begin
    // Initialize inputs
    
/*    CS = 1;
    rd_enable = 1;
    wr_enable = 1;
    A1 = 1;
    bi_data_bus = 8'b10111010; // Some initial data

    // Apply stimulus, Assuming some delay between operations
    #10 CS = 1;
    #10 CS = 0;  // Enable the chip
    #10 wr_enable = 0;  // Write operation
    #10 A1 = 0;
    #10 A1 = 1;
    #10 bi_data_bus = 8'b11100001;
    #10 bi_data_bus = 8'b11101000;
    #10 rd_enable = 0;  // Read operation
    #10 CS = 1;

*/
 	CS =1'b1;
        rd_enable=1'b1;
        wr_enable=1'b1;
        A1=1'b0;
        bi_data_bus= 8'b00000000;
              
       // Task : Write data
        //ICW1
       #10 CS=1'b0;
       wr_enable=1'b0;
       A1=1'b0;
       bi_data_bus= 8'b00010011; 

       //ICW2
       #10 CS=1'b0;
       wr_enable=1'b0;
       A1=1'b1;
       bi_data_bus= 8'b00010000;  
       //ICW3

       //ICW4
       #10 CS=1'b0;
       wr_enable=1'b0;
       A1=1'b1;
       bi_data_bus= 8'b00000X01;

	//OCW1
	#10 CS=1'b0;
	wr_enable = 1'b0;
	A1 = 1'b1;
	bi_data_bus = 8'b00000000;

	//OCW2
	#10 CS=1'b0;
	wr_enable = 1'b0;
	A1 = 1'b0;
	bi_data_bus = 8'b00000000;		//lsb 3 bits??IR level to be acted upon

	//OCW3
	#10 CS=1'b0;
	wr_enable = 1'b0;
	A1 = 1'b0;
	bi_data_bus = 8'b00001000;
	#10;

  end


endmodule
