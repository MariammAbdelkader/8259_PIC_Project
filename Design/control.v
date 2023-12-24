module control (
    // external inputs & outputs
    input reset,
    input int_ack, //interrupt ack
    output INT, // interrupt
    inout SP_EN, //slave_program_n, slave_program_or_enable_buffer
    inout [2:0] cascade_io, //cascade bus

    // internal bus
    input [7:0] data_bus,
    input write_ICW1, write_ICW2_4,
    input write_OCW1, write_OCW2, write_OCW3,
    input read,

    output out_control_logic_data,
    output [7:0] control_logic_data,

    output latch_in_service,
    /*output read_reg_en, 
    output read_register_isr_or_irr,

    ...
    */
);
    reg single_or_cascade;
    reg set_icw4;

    reg cascade_slave;

    reg [1:0] command_state;
    reg [1:0] next_command_state;

    localparam CMD_WRITE_READY = 2'b00;
    localparam CMD_WRITE_ICW2 = 2'b01;
    localparam CMD_WRITE_ICW3 = 2'b10;
    localparam CMD_WRITE_ICW4 = 2'b11;

    always @(next_command_state or posedge reset) begin
        if(reset)
            command_state <= CMD_READY;
        else
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
    localparam POLL = 2'b01;
    localparam ACK = 2'b10;
    //localparam ACK2 = 3'b011;
    //localparam ACK3 = 3'b100;

    //control fsm
    //pedge_interrupt_acknowledge -> !int_ack
    //nedge_interrupt_acknowledge -> int_ack
    always @(*) begin
        case (control_state)
            CTRL_READY: begin
                if(write_ocw3_reg && data_bus[2])
                    next_control_state = POLL;
                else if (write_ocw2_reg || !int_ack)
                    next_control_state = CTRL_READY;
                else 
                    next_control_state = ACK;
            end 
            ACK: begin
                if (int_ack)
                    next_control_state = ACK;
                else 
                    next_control_state = CTRL_READY;
            end
            POLL: begin
                if (read) 
                    next_control_state = POLL;
                else
                    next_control_state = CTRL_READY;
            end
            default: next_control_state = CTRL_READY;
        endcase
    end

    always @(*) begin
        if (reset)
            control_state <= CTRL_READY;
        else if (write_ICW1)
            control_state <= CTRL_READY;
        else
            control_state <= next_control_state;
    end

    always @* begin
        if (write_ICW1 == 1'b1)
            latch_in_service = 1'b0;
        else if ((control_state == CTRL_READY) && (next_control_state == POLL))
            latch_in_service = 1'b1;
        else if (cascade_slave == 1'b0)
            latch_in_service = (control_state == CTRL_READY) & (next_control_state != CTRL_READY);
        else
            latch_in_service = (control_state == ACK) & (cascade_slave_enable == 1'b1) & (int_ack == 1'b1);
    end

    // End of acknowledge sequence
    wire    end_of_acknowledge_sequence =  (control_state != POLL) & (control_state != CTRL_READY) & (next_control_state == CTRL_READY);
    wire    end_of_poll_command         =  (control_state == POLL) & (control_state != CTRL_READY) & (next_control_state == CTRL_READY);


endmodule