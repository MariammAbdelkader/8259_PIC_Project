
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
    
            wire  out_control_logic_data;
       wire [7:0]   control_logic_data;
       wire       level_edge_triggered;
    wire      read_reg_en;
        wire     read_reg_isr_or_irr;
       reg[7:0]   interrupt;
      wire [7:0]   int_mask ;
     wire [7:0]   eoi;
      wire [2:0]   priority_rotate;
      wire         freeze;
  
      wire [7:0]   clear_IRR;
	wire [7:0]in_service_register ;

 control u_Control_Logic (
        // External input/output
        .cascade_i                        (cascade_i),
        .cascade_o                        (cascade_o),

        .SP_EN                    (SP_EN),

        .int_ack            (int_ack),
        .interrupt_to_cpu                   (interrupt_to_cpu),

        // Internal bus
        . internal_data_bus                 (internal_bus),
        . write_ICW1      ( write_ICW_1),
        . write_ICW2_4     ( write_ICW2_4),
        . write_OCW1     ( write_OCW1),
        . write_OCW2    ( write_OCW2),
        .write_OCW3    (write_OCW3),
	.in_service_reg		(in_service_register),
        .read                               (read),
        .out_control_logic_data_wire             (out_control_logic_data),
        .control_logic_data_wire                 (control_logic_data),

        // Registers to interrupt detecting logics
        .level_edge_triggered_wire    (level_edge_triggered),
        // Registers to Read logics
        .read_reg_en_wire               (read_reg_en),
        .read_reg_isr_or_irr_wire           (read_reg_isr_or_irr),

        // Signals from interrupt detectiong logics
        .interrupt                          (interrupt),

        // Interrupt control signals
        .int_mask_wire                      (int_mask ),
        . eoi                  ( eoi),
        .priority_rotate_wire                    (priority_rotate),
        .freeze_wire                             (freeze),
        .clear_IRR_wire           (clear_IRR)
    );

    //
    // Interrupt Request
    //
   wire  [7:0]   IRR_Output;

    IRR u_Interrupt_Request (
        // Inputs from control logic
        //.level_or_edge_toriggered_config    (level_or_edge_toriggered_config),
        .freeze                             (freeze),
        .clear_IRR           (clear_IRR),

        // External inputs
        .interrupt_Requests              (interrupt_Requests),

        // Outputs
        .IRR_Output_wire         (IRR_Output)
    );

    //
    // Priority Resolver
 wire [7:0] interrupt_vector;

   Priority_Resolver u_Priority_Resolver (

  // Inputs from control logic

  .priority_rotate(priority_rotate),

  .imr(int_mask),
  // Inputs

  .irr(IRR_Output),

  .isr(in_service_register),

  // Outputs

  .interrupt_vector_wire(interrupt_vector)

);

    //
    // In Service
    //
    PIC_ISR u_In_Service (

        // Inputs
        .interrupt_request                       (interrupt_vector),
        .eoi                   (eoi),
        // Outputs
        .in_service_register_wire                (in_service_register),
	.interrupt_mask		(int_mask)
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
