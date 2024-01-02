module ControlBus (

    input   wire           CS,				//chip_select_n
    input   wire           rd_enable,			//read_enable_n
    input   wire           wr_enable,			//write_enable_n
    input   wire           A1,				//A0 "A1 for 8086"
    input   wire   [7:0]   bi_data_bus,			//data_bus_in

    // Internal Bus
    output  reg   [7:0]    internal_bus,	//internal_data_bus
    output  wire           write_ICW_1,		//write_initial_command_word_1
    output  wire           write_ICW2_4,	//write_initial_command_word_2_4
    output  wire           write_OCW1,		//write_operation_control_word_1
    output  wire           write_OCW2,		//write_operation_control_word_2
    output  wire           write_OCW3,		//write_operation_control_word_3
    output  wire           read
);

    // Internal Signals
    wire   write;
    assign write = ~wr_enable & ~CS;

    // Write Control -> if CS and wr enable are low --> take data from databus and put it on internal bus
    always @(*) begin			
        if (write)					
            internal_bus = bi_data_bus;
        else
            internal_bus = internal_bus;
    end

    


    // Generate write request flags
    assign write_ICW_1 = (~wr_enable & ~CS & ~A1 & internal_bus[4])? 1'b1: 1'bZ ;   
    assign write_ICW2_4 = write & A1? 1'b1 : 1'bZ;
    
    assign write_OCW1 = write & A1? 1'b1 : 1'bZ;
    assign write_OCW2 = write & ~A1 & ~internal_bus[4] & ~internal_bus[3]? 1'b1 :1'bZ;
    assign write_OCW3 = write & ~A1 & ~internal_bus[4] & internal_bus[3]? 1'b1 : 1'bZ;

    //
    // Read Control
    //
    assign read = ~rd_enable & ~CS? 1'b1 : 1'bZ;

endmodule

