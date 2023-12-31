module control (
    // external inputs & outputs
    input reset,
    input int_ack, //interrupt ack
    output INT, // interrupt
    input SP_EN, //slave_program_n
    inout [2:0] cascade_io, //cascade bus

    // internal bus
    input [7:0] internal_data_bus,
    input write_ICW1, write_ICW2_4,
    input write_OCW1, write_OCW2, write_OCW3,
    input read,

    output out_control_logic_data,
    output [7:0] control_logic_data,

    //signals from interrupt
    input [7:0] highest_level_in_service,

    //interrupt control signals
    output reg [7:0] int_mask, //interrupt mask
    output reg [7:0] eoi, //end of interrupt
    output [2:0] priority_rotate,
    output reg latch_in_service,
    output reg level_edge_triggered,
    output reg read_reg_en, 
    output reg read_reg_isr_or_irr,
    output[7:0] clear_IRR
);
    reg single_or_cascade;
    reg set_icw4;
    reg buff_mode_config;
    reg buff_master_or_slave_config;
    reg auto_eoi_config;
    reg auto_rotate_mode;
    reg   [10:0]  interrupt_vector_address;
    reg call_address_interval;
    reg   [7:0]   cascade_config;

    reg cascade_slave;
    reg cascade_slave_enable;

    wire [7:0] acknowledge_interrupt;



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
    //localparam POLL = 2'b01;
    localparam ACK1 = 2'b01;
    localparam ACK2 = 2'b10;
    //localparam ACK3 = 3'b100;

    //control fsm
    //pedge_interrupt_acknowledge -> !int_ack
    //nedge_interrupt_acknowledge -> int_ack
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

    always @(negedge int_ack, posedge write_ocw2_reg, write_ICW1) begin
        if (write_ICW1)
            control_state <= CTRL_READY;
        else
            control_state <= next_control_state;
    end

    always @* begin
        if (write_ICW1 == 1'b1)
            latch_in_service = 1'b0;
        else if ((control_state == CTRL_READY))
            latch_in_service = 1'b1;
        else if (cascade_slave == 1'b0)
            latch_in_service = (control_state == CTRL_READY) & (next_control_state != CTRL_READY);
        else
            latch_in_service = (control_state == ACK2) & (cascade_slave_enable == 1'b1) & (int_ack == 1'b1);
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
        if (write_ICW1 == 1'b1)
            interrupt_vector_address[2:0] <= internal_data_bus[7:5];
            level_edge_triggered <= internal_data_bus[3];
            call_address_interval <= internal_data_bus[2];
            single_or_cascade <= internal_data_bus[1];
            set_icw4 <= internal_data_bus[0];
        else
            interrupt_vector_address[2:0] <= interrupt_vector_address[2:0];
            level_edge_triggered <= level_edge_triggered;
            call_address_interval <= call_address_interval;
            single_or_cascade <= single_or_cascade;
            set_icw4 <= set_icw4;
    end

    //
    // ICW 2 initialization
    //
    always @* begin
        if (write_ICW1 == 1'b1)
            interrupt_vector_address[10:3] <= 3'b000;
        else if (write_icw2 == 1'b1)
            interrupt_vector_address[10:3] <= internal_data_bus;
        else
            interrupt_vector_address[10:3] <= interrupt_vector_address[10:3];
    end

    //
    // ICW 3
    //
    always @* begin
        if (write_ICW1 == 1'b1)
            cascade_config <= 8'b00000000;
        else if (write_icw3 == 1'b1)
            cascade_config <= internal_data_bus;
        else
            cascade_config <= cascade_config;
    end

    //
    //ICW 4 initialization
    //
    // M/S & AEOI
    always @(*) begin
        if (write_ICW1)
            buff_master_or_slave_config <= 1'b0;
            auto_eoi_config <= 1'b0;
        else if (write_icw4)
            buff_master_or_slave_config <= internal_data_bus[2];
            auto_eoi_config <= internal_data_bus[1];
        else
            buff_master_or_slave_config= buff_master_or_slave_config;
            auto_eoi_config = auto_eoi_config;
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
    //incomplete & OCW3 missing
    always @(*) begin
        if (write_ICW1 == 1'b1)
            eoi = 8'b11111111; 
        else if (end_of_ack_seq == 1'b1)
            eoi = acknowledge_interrupt;
        else if (write_OCW2) begin
            case (internal_data_bus[6:5])
                2'b01:   eoi = highest_level_in_service; 
                //2'b11:   eoi = num2bit(internal_data_bus[2:0]);
                default: eoi = 8'b00000000;
            endcase
        end
        else
            eoi = 8'b00000000;
    end

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
        if (write_ICW1 == 1'b1)
            priority_rotate <= 3'b111; // no rotaion
        else if ((auto_rotate_mode == 1'b1) && (end_of_ack_seq == 1'b1)) // fully nested mode
            priority_rotate <= convert_bit_to_number(acknowledge_interrupt);
        else if (write_OCW2 == 1'b1) begin
            case (internal_data_bus[7:5]) //D7:D5
                // rotate on non_specific EOI command 
                3'b101:  priority_rotate <= convert_bit_to_number(highest_level_in_service); 
                // set periority command
                3'b110:  priority_rotate <= internal_data_bus[2:0];
                // for synthesis
                default: priority_rotate <= priority_rotate; 
            endcase
        end
        else   // for synthesis
            priority_rotate <= priority_rotate;  
    end

endmodule
