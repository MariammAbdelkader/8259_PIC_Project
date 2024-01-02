module tOPmodule_TB;
                reg CS;
                 reg rd_enable;
               reg wr_enable;
              reg  A1;
        reg[7:0]  bi_data_bus;
       wire [7:0]  data_bus_out;
               wire  data_bus_io;
      reg [2:0]   cascade_i;
         wire  [2:0]   cascade_o;
             reg SP_EN;
             reg  int_ack;
           wire  interrupt_to_cpu;
        reg[7:0]   interrupt_request;
       Top_module U_8259(
       .CS(CS),
                 .rd_enable(rd_enable),
                .wr_enable(wr_enable),
               .A1(A1),
        .bi_data_bus(bi_data_bus),

         .data_bus_out(data_bus_out),
               .data_bus_io(data_bus_io),
             .cascade_i(cascade_i),
            .cascade_o(cascade_o),
            .SP_EN(SP_EN),
            .int_ack(int_ack),
           .interrupt_to_cpu(interrupt_to_cpu),
           .interrupt_request(interrupt_request)
       
       );
      // Task : Initialization 
      initial begin
                CS =1'b1;
                rd_enable=1'b1;
                wr_enable=1'b1;
                A1=1'b0;
                bi_data_bus= 8'b00000000;
                cascade_i = 3'b000;
                SP_EN= 1'b0;
                int_ack= 1'b1;
                interrupt_request= 8'b00000000;
              // Task : Write data
                  //ICW1
                  #12 CS=1'b0;
                   wr_enable=1'b0;
                   A1=1'b0;
                   bi_data_bus= 8'b00010011; 
                  //ICW2
                  #12 CS=1'b0;
                   wr_enable=1'b0;
                   A1=1'b1;
                   bi_data_bus= 8'b00010000;  //CASCADE HERE
                  // //ICW3


                   //ICW4
                    #12 CS=1'b0;
                        wr_enable=1'b0;
                        A1=1'b1;
                        bi_data_bus= 8'b00000X01;
      end
                   endmodule





