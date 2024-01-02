
module Top_module(
    input             CS,
    input             rd_enable,
    input              wr_enable,
    input              A1,
    input   [7:0]   bi_data_bus,
    output    reg [7:0]   data_bus_out,
    output reg            data_bus_io,
    input     [2:0]  cascade_i,   //input cascade bus 
    output   [2:0]   cascade_o,   //output cascade bus 
    
    input              SP_EN,
    input             int_ack, 
    output             interrupt_to_cpu,  
    input      [7:0]   interrupt_request
);
 //
    // Data Bus Buffer & Read/Write Control Logic (1)
    //
  wire [7:0]    internal_bus;
               wire   write_ICW_1;
              wire  write_ICW2_4;
            wire   write_OCW1;
            wire    write_OCW2;
         wire    write_OCW3;
        wire   read;

   ControlBus u_Bus_Control_Logic (
        // Bus
        . CS                      ( CS),
        .rd_enable                      (rd_enable),
        .wr_enable                     (wr_enable),
        . A1                           ( A1),
        .bi_data_bus                        (bi_data_bus),

        // Control signals
        .internal_bus                  (internal_bus),
        .write_ICW_1       ( write_ICW_1),
        .write_ICW2_4    (write_ICW2_4),
        .write_OCW1    (write_OCW1),
        .write_OCW2     (write_OCW2),
        .write_OCW3     (write_OCW3),
        .read                               (read)
    );

    //
    // Interrupt (Service) Control Logic
    
            reg  out_control_logic_data;
       reg [7:0]   control_logic_data;
       reg       level_edge_triggered;
    reg      read_reg_en;
        reg     read_reg_isr_or_irr;
       reg[7:0]   interrupt;
      reg[7:0]   int_mask ;
     wire [7:0]   eoi;
      reg [2:0]   priority_rotate;
      reg         freeze;
  
      reg [7:0]   clear_IRR;

 control u_Control_Logic (
        // External input/output
        .cascade_i                        (cascade_i),
        .cascade_o                        (cascade_o),

        .SP_EN                    (SP_EN),

        .int_ack            (int_ack),
        .interrupt_to_cpu                   (interrupt_to_cpu),

        // Internal bus
        . internal_bus                 (internal_bus),
        . write_ICW_1      ( write_ICW_1),
        . write_ICW2_4     ( write_ICW2_4),
        . write_OCW1     ( write_OCW1),
        . write_OCW2    ( write_OCW2),
        .write_OCW3    (write_OCW3),

        .read                               (read),
        .out_control_logic_data             (out_control_logic_data),
        .control_logic_data                 (control_logic_data),

        // Registers to interrupt detecting logics
        .level_edge_triggered    (level_edge_triggered),
        // Registers to Read logics
        .read_reg_en               (read_reg_en),
        .read_reg_isr_or_irr           (read_reg_isr_or_irr),

        // Signals from interrupt detectiong logics
        .interrupt                          (interrupt),

        // Interrupt control signals
        .int_mask                      (int_mask ),
        . eoi                  ( eoi),
        .priority_rotate                    (priority_rotate),
        .freeze                             (freeze),
        .clear_IRR           (clear_IRR)
    );

    //
    // Interrupt Request
    //
   reg  [7:0]   IRR_Output;

    IRR u_Interrupt_Request (
        // Inputs from control logic
        //.level_or_edge_toriggered_config    (level_or_edge_toriggered_config),
        .freeze                             (freeze),
        .clear_IRR           (clear_IRR),

        // External inputs
        .interrupt_Requests              (interrupt_Requests),

        // Outputs
        .IRR_Output         (IRR_Output)
    );

    //
    // Priority Resolver
     reg [7:0]in_service_register ;
 reg [7:0] interrupt_vector;

   Priority_Resolver u_Priority_Resolver (

  // Inputs from control logic

  .priority_rotate(priority_rotate),

  .imr(int_mask),
  // Inputs

  .irr(IRR_Output),

  .isr(in_service_register),

  // Outputs

  .interrupt_vector(interrupt_vector)

);

    //
    // In Service
    //
    PIC_ISR u_In_Service (

        // Inputs
        .interrupt_request                       (interrupt_vector),
        .eoi                   (eoi),
        // Outputs
        .in_service_register                (in_service_register)
    );

    //
    // Data Bus Buffer & Read/Write Control Logic (2)
    //
    // Data bus
   always @* begin
        if (out_control_logic_data == 1'b1)begin
            data_bus_io  = 1'b0;
            data_bus_out = control_logic_data;
        end
        else if (read == 1'b0) begin
            data_bus_io  = 1'b1;
            data_bus_out = 8'b00000000;
        end
        else if ( A1 == 1'b1) begin
            data_bus_io  = 1'b0;
            data_bus_out =  int_mask ;
        end
        else if ((read_reg_en == 1'b1) && (read_reg_isr_or_irr == 1'b0)) begin
            data_bus_io  = 1'b0;
            data_bus_out = IRR_Output;
        end
        else if ((read_reg_en == 1'b1) && (read_reg_isr_or_irr == 1'b1)) begin
            data_bus_io  = 1'b0;
            data_bus_out = in_service_register;
        end
        else begin
            data_bus_io  = 1'b1;
            data_bus_out = 8'b00000000;
        end
    end

endmodule
