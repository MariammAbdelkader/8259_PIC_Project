module control (
    // external inputs & outputs
    //input reset,
    input int_ack, //interrupt ack
    input SP_EN, //slave_program_n
    input [2:0] cascade_i, //input cascade bus
    output reg[2:0] cascade_o, //output cascade bus
    output reg interrupt_to_cpu,
    // internal bus
    input [7:0] internal_data_bus,
    input write_ICW1, write_ICW2_4,
    input write_OCW1, write_OCW2, write_OCW3,
    input read,
    input[7:0] in_service_reg, 
    inout freeze_wire,
    
    inout out_control_logic_data_wire,
    inout [7:0] control_logic_data_wire,

    //signals from interrupt
    input [7:0] interrupt,

    //interrupt control signals
    inout [7:0] int_mask_wire, //interrupt mask
    output reg [7:0] eoi, //end of interrupt
    inout [2:0] priority_rotate_wire,
    inout level_edge_triggered_wire,
    inout read_reg_en_wire, 
    inout read_reg_isr_or_irr_wire,
    inout [7:0] clear_IRR_wire
);

    reg out_control_logic_data;
    reg [7:0] control_logic_data;
    reg single_or_cascade;
    reg set_icw4;
    reg auto_eoi_config;
    reg auto_rotate_mode;
    reg   [7:0]  interrupt_vector_address;
    reg call_address_interval;
    reg   [7:0]   cascade_config;
    reg cascade_slave_ON;


    reg cascade_slave;
  
    reg   cascade_ACK_2_out ;

    reg [7:0] acknowledge_interrupt;

    reg freeze;
    reg [7:0] int_mask;
    reg [7:0] priority_rotate;
    reg level_edge_triggered;
    reg read_reg_en;
    reg read_reg_isr_or_irr;
    reg [7:0] clear_IRR;

    assign out_control_logic_data_wire= out_control_logic_data;
    assign control_logic_data_wire = control_logic_data;
    assign freeze_wire = freeze;
    assign int_mask_wire = int_mask;
    assign priority_rotate_wire = priority_rotate;
    assign level_edge_triggered_wire = level_edge_triggered;
    assign read_reg_en_wire = read_reg_en;
    assign read_reg_isr_or_irr_wire = read_reg_isr_or_irr;
    assign clear_IRR_wire = clear_IRR;

    reg [1:0] command_state;
    reg [1:0] next_command_state;

    localparam CMD_READY = 2'b00;
    localparam CMD_WRITE_ICW2 = 2'b01;
    localparam CMD_WRITE_ICW3 = 2'b10;
    localparam CMD_WRITE_ICW4 = 2'b11;

    always @(next_command_state) begin
        command_state <= next_command_state;
    end

    // Initialization fsm

    always @* begin
        if(write_ICW1) next_command_state = CMD_WRITE_ICW2;
        else if (write_ICW2_4) begin
            case (command_state)
                CMD_WRITE_ICW2: begin
                    if (!single_or_cascade) begin
                        next_command_state = CMD_WRITE_ICW3;
                    end
                    else if (set_icw4) begin
                        next_command_state = CMD_WRITE_ICW4;
                    end
                    else 
                        next_command_state = CMD_READY;
                end
                CMD_WRITE_ICW3: begin
                    if(set_icw4) begin
                        next_command_state = CMD_WRITE_ICW4;
                    end
                    else 
                        next_command_state = CMD_READY;
                end
                default: begin
                    next_command_state = CMD_READY;
                end
            endcase
        end else
            next_command_state = command_state;
    end

    // command words status
    wire write_icw2  = (command_state == CMD_WRITE_ICW2) & write_ICW2_4;
    wire write_icw3  = (command_state == CMD_WRITE_ICW3) & write_ICW2_4;
    wire write_icw4  = (command_state == CMD_WRITE_ICW4) & write_ICW2_4;
    wire write_ocw1_reg = (command_state == CMD_READY) & write_OCW1;
    wire write_ocw2_reg = (command_state == CMD_READY) & write_OCW2;
    wire write_ocw3_reg = (command_state == CMD_READY) & write_OCW3;

    reg [1:0] control_state;
    reg [1:0] next_control_state;

    localparam CTRL_READY = 2'b00;
    
    localparam ACK1 = 2'b01;
    localparam ACK2 = 2'b10;
    

    //control fsm
    always @(control_state, write_ocw2_reg, int_ack) begin
        case (control_state)
            CTRL_READY: begin
                if (write_ocw2_reg || int_ack)
                    next_control_state = CTRL_READY;
                else 
                    next_control_state = ACK1;
            end 
            ACK1: begin
                if (!int_ack)
                    next_control_state = ACK2;
                else 
                    next_control_state = ACK1;
            end
            ACK2: begin
                if(int_ack)
                    next_control_state = ACK2;
                else
                    next_control_state = CTRL_READY;
            end
            default: next_control_state = CTRL_READY;
        endcase
    end

    always @(negedge int_ack, write_ICW1) begin
        if (write_ICW1)
            control_state <= CTRL_READY;
        else
            control_state <= next_control_state;
    end

    // End of acknowledge sequence
    wire    end_of_ack_seq =  (control_state != CTRL_READY) & (next_control_state == CTRL_READY);
    //wire    end_of_poll_command = (control_state != CTRL_READY) & (next_control_state == CTRL_READY);


        //...
    //
    // ICW 1 initialization
    //
    
    // A7-A5 & LTIM & call address interval 4 or 8 configureation & SNGL & ICW4
    always @* begin
        if (write_ICW1 == 1'b1) begin
            
            level_edge_triggered <= internal_data_bus[3];   //if level:1, edge:0
            call_address_interval <= internal_data_bus[2];
            single_or_cascade <= internal_data_bus[1];      //if single:1, cascade:0
            set_icw4 <= internal_data_bus[0];               //if icw4 needed:1 , not needed:0
            end
        else begin
            
            level_edge_triggered <= level_edge_triggered;
            call_address_interval <= call_address_interval;
            single_or_cascade <= single_or_cascade;
            set_icw4 <= set_icw4;
            end
    end

    //
    // ICW 2 initialization
    //
    always @* begin
        if (write_ICW1 == 1'b1) begin
            interrupt_vector_address[7:3] <= 5'b000;
        end
        else if (write_icw2 == 1'b1) begin
            interrupt_vector_address[7:3] <= internal_data_bus[7:3];
        end
        else
            interrupt_vector_address[7:3] <= interrupt_vector_address[7:3];
    end

    //
    // ICW 3
    //
   always @(write_icw3,write_ICW1) begin

 if (write_ICW1 == 1'b1)
            cascade_config <= 8'b00000000;
        else if (write_icw3 == 1'b1)
          cascade_config <= internal_data_bus; //read ID
        else
            cascade_config <= cascade_config;
    end

    //
    //ICW 4 initialization
    //
    // AEOI
    always @(*) begin
        if (write_ICW1)
            auto_eoi_config <= 1'b0;
        else if (write_icw4)
            auto_eoi_config <= internal_data_bus[1];
        else
            auto_eoi_config <= auto_eoi_config;
    end

    //Operation Control Word 1

    always @(*) begin
        if (write_ICW1 == 1'b1)
            int_mask <= 8'b11111111;
        else if (write_ocw1_reg == 1'b1)
            int_mask <= internal_data_bus;
        else
            int_mask <= int_mask;
    end

    //Operation Control Word 2
    
    always @(*) begin
        if (write_ICW1 == 1'b1)
            eoi = 8'b11111111; 
        else if (end_of_ack_seq == 1'b1 && auto_eoi_config == 1'b1)
            eoi = acknowledge_interrupt;
        else if (write_OCW2) begin
            case (internal_data_bus[6:5])
                //2'b01:   eoi = highest_level_in_service; 
                2'b11:   eoi = 8'b0000001 << (internal_data_bus[2:0]);
                default: eoi = 8'b00000000;
            endcase
        end
        else
            eoi = 8'b00000000;
    end
    //OCW3
    // RR/RIS
    always @(*) begin
        if (write_ICW1 == 1'b1) begin
            read_reg_en <= 1'b1;
            read_reg_isr_or_irr <= 1'b0;
        end
        else if (write_ocw3_reg == 1'b1) begin
            read_reg_en <= internal_data_bus[1];
            read_reg_isr_or_irr <= internal_data_bus[0];
        end
        else begin
            read_reg_en <= read_reg_en;
            read_reg_isr_or_irr <= read_reg_isr_or_irr;
        end
    end

    // Auto rotatation mode (equal periority devices)
    always @(*) begin
        // initially (before configuring OCW1), default: fully nested mode 
        if (write_ICW1== 1'b1)
            auto_rotate_mode <= 1'b0;
        else if (write_OCW2 == 1'b1) begin
            case(internal_data_bus[7:5]) //D7:D5
                //rotate in automatic EOI command (set)
                3'b100:  auto_rotate_mode <= 1'b1;
                //rotate in automatic EOI command (clear)
                3'b000:  auto_rotate_mode <= 1'b0;
                // for synthesis
                default: auto_rotate_mode <= auto_rotate_mode; 
            endcase
        end
        else  // for synthesis
            auto_rotate_mode <= auto_rotate_mode; 
    end

   // setting the value of periority rotate
    always@(*) begin
        if (write_ICW1 == 1'b1) begin
            priority_rotate <= 3'b111; // no rotaion (fully nested)
            interrupt_vector_address[2:0] <=  3'b111;
        end
        else if ((auto_rotate_mode == 1'b1) && (end_of_ack_seq == 1'b1)) begin //automatic rotation
            priority_rotate <= convert_bit_to_number(acknowledge_interrupt);
            interrupt_vector_address[2:0] <= convert_bit_to_number(acknowledge_interrupt);
        end
        else if ((write_OCW2 == 1'b1) && (internal_data_bus[7:5]==3'b101)) begin //rotate on non_specific EOI command
             priority_rotate <= convert_bit_to_number(in_service_reg);
             interrupt_vector_address[2:0] <= convert_bit_to_number(in_service_reg);
        end else begin  // for synthesis
            priority_rotate <= priority_rotate;
            interrupt_vector_address[2:0] <= interrupt_vector_address[2:0];
        end
     end

     // Interrupt control signals
    //
    // INT
    always @(*) begin
        if (write_ICW1 == 1'b1)
            interrupt_to_cpu <= 1'b0;
        else if (interrupt != 8'b00000000)
            interrupt_to_cpu <= 1'b1;
        else if (end_of_ack_seq == 1'b1)
            interrupt_to_cpu <= 1'b0;
        else
            interrupt_to_cpu <= interrupt_to_cpu;
    end

    // freeze
    always @(*) begin
        if (next_control_state == CTRL_READY)
            freeze <= 1'b0;
        else
            freeze <= 1'b1;
    end

    // clear_IRR
    always@(*) begin
        if (write_ICW1 == 1'b1)
            clear_IRR = 8'b11111111;
        else if (cascade_slave == 1'b0 && (!((control_state == CTRL_READY) & (next_control_state != CTRL_READY))))
            clear_IRR = 8'b00000000;
        else
            clear_IRR = interrupt;//ns2al mariam
    end

    // interrupt buffer
    always @(*) begin
        if (write_ICW1 == 1'b1)
            acknowledge_interrupt <= 8'b00000000;
        else if (end_of_ack_seq)
            acknowledge_interrupt <= 8'b00000000;
        else
            acknowledge_interrupt <= interrupt;
    end

    always@(*) begin
        if (int_ack == 1'b0) begin
            // Acknowledge
            case (control_state)
                CTRL_READY: begin
                    out_control_logic_data = 1'b0;
                    control_logic_data     = 8'b00000000;
                end
                ACK1: begin
                    out_control_logic_data = 1'b0;
                    control_logic_data     = 8'b0000;
                end
                ACK2: begin
                    if (  cascade_ACK_2_out  == 1'b1) begin
                        out_control_logic_data = 1'b1;

                        /*if (cascade_slave == 1'b1)
                            control_logic_data[2:0] = bit2num(interrupt_when_ack1);
                        else
                            control_logic_data[2:0] = bit2num(acknowledge_interrupt);*/
                        control_logic_data = interrupt_vector_address;
                        
                    end
                    else begin
                        out_control_logic_data = 1'b0;
                        control_logic_data     = 8'b00000000;
                    end
                end
                default: begin
                    out_control_logic_data = 1'b0;
                    control_logic_data     = 8'b00000000;
                end
            endcase
        end
        else begin
            // Nothing
            out_control_logic_data = 1'b0;
            control_logic_data     = 8'b00000000;
        end
    end

// SNGL
    always @(write_ICW1) begin  
       if (write_ICW1 == 1'b1)
            single_or_cascade  <= internal_data_bus[1];
        else
          single_or_cascade <= single_or_cascade; 
    end

always@ (single_or_cascade) begin
        if (single_or_cascade == 1'b1)
            cascade_slave = 1'b0;
        else
            cascade_slave = !(SP_EN);
    end

 always@* begin
        if (cascade_slave == 1'b0)
            cascade_slave_ON = 1'b0;
        else if (cascade_config[2:0] != cascade_i) //work as comparator
            cascade_slave_ON = 1'b0; 
        else
            cascade_slave_ON = 1'b1; //enable on match
    end

 wire    interrupt_from_slave_device = (acknowledge_interrupt & cascade_config) != 8'b00000000;

   // output ACK2 
    always@* begin
        if (single_or_cascade == 1'b1)
            cascade_ACK_2_out = 1'b1;
        else if (cascade_slave_ON == 1'b1)
             cascade_ACK_2_out = 1'b1;
        else if ((cascade_slave == 1'b0) && (interrupt_from_slave_device == 1'b0))
            cascade_ACK_2_out = 1'b1;
        else
             cascade_ACK_2_out = 1'b0;
    end

always @* begin
       if (cascade_slave == 1'b1) 
            cascade_o <= 3'b000;
        else if ((control_state != ACK1) && (control_state != ACK2)) //NO ACK
            cascade_o <= 3'b000;
        else if (interrupt_from_slave_device == 1'b0)
            cascade_o <= 3'b000;
        else
            cascade_o <= convert_bit_to_number(acknowledge_interrupt);
    end

function[2:0] convert_bit_to_number (input [7:0] INPUT);
        if(INPUT[0] == 1'b1) 
            convert_bit_to_number = 3'b000;
        else if (INPUT[1] == 1'b1) 
            convert_bit_to_number = 3'b001;
        else if (INPUT[2] == 1'b1) 
            convert_bit_to_number = 3'b010;
        else if (INPUT[3] == 1'b1) 
            convert_bit_to_number = 3'b011;
        else if (INPUT[4] == 1'b1) 
            convert_bit_to_number = 3'b100;
        else if (INPUT[5] == 1'b1) 
            convert_bit_to_number = 3'b101;
        else if (INPUT[6] == 1'b1) 
            convert_bit_to_number = 3'b110;
        else if (INPUT[7] == 1'b1) 
            convert_bit_to_number = 3'b111;
        else  
            convert_bit_to_number = 3'b111;
endfunction

endmodule
