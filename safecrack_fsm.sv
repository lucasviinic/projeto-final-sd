module safecrack_fsm (
    input  logic       clk,
    input  logic       rstn,
    input  logic [2:0] btn,        // buttons inputs (BTN[2:0])
    output logic led_green1,
	 output logic led_green2,
    output logic led_green3,	 // green LEDs for progress indication
    output logic led_red     // red LEDs for error indication
);
    // one-hot encoding
    typedef enum logic [5:0] {
        S0       = 6'b000001,  // initial state - waiting for 1st digit
        S1       = 6'b000010,  // 1st digit correct - waiting for 2nd digit
        S2       = 6'b000100,  // 2nd digit correct - waiting for 3rd digit
        ERROR    = 6'b001000,  // error state - show red LED for 3s
        SUCCESS  = 6'b010000,  // success state - show all green LEDs for 5s
        IDLE     = 6'b100000   // return to initial after success
    } state_t;

    state_t state, next_state;
    logic [2:0] btn_prev, btn_edge, btn_pos;
    logic       any_btn_edge;

    localparam int MAX_DELAY     = 250_000_000;  // maximum delay value

    logic [$clog2(MAX_DELAY)-1:0] delay_cnt, next_delay_cnt;
     
     always_comb begin
        btn_pos	= ~btn; // invert buttons to active high
        btn_edge = btn_pos & ~btn_prev; // get 0 -> 1 edges
        any_btn_edge = (|btn_edge); // any button edge detected
     end 
     
    // sequential logic
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            btn_prev    <= 3'b000;
            delay_cnt   <= '0;
            state       <= S0;
        end
        else begin
            btn_prev    <= btn_pos;
            delay_cnt   <= next_delay_cnt;
            state       <= next_state;
        end
    end

    // transition logic
    always_comb begin
        // default assignments
        next_state     = state;
        next_delay_cnt = delay_cnt;

        unique case (state)
            S0: begin
                if (btn_edge == 3'b001) begin
                    // button 0 pressed -> correct 1st digit
                    next_state = S1;
                end else if (any_btn_edge) begin
                    // any other button -> error
                    next_state = ERROR;
                    next_delay_cnt = 250000000;
                end
            end

            S1: begin
                if (btn_edge == 3'b010) begin
                    // button 1 pressed -> correct 2nd digit
                    next_state = S2;
                end else if (any_btn_edge) begin
                    // any other button -> error
                    next_state = ERROR;
                    next_delay_cnt = 250000000;
                end
            end

            S2: begin
                if (btn_edge == 3'b100) begin
                    // button 2 pressed -> correct 3rd digit
                    next_state = SUCCESS;
                    next_delay_cnt = 250000000;
                end else if (any_btn_edge) begin
                    // any other button -> error
                    next_state = ERROR;
                    next_delay_cnt = 250000000;
                end
            end

            ERROR: begin
                if (delay_cnt > 100000000) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    // after 3 seconds, return to initial state
                    next_state = S0;
                    next_delay_cnt = 250000000;
                end
            end

            SUCCESS: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    // after 5 seconds, return to initial state
                    next_state = S0;
                    next_delay_cnt = 250000000;
                end
            end

            IDLE: begin
                next_state = S0;
            end

            default: next_state = S0;
        endcase
    end

    // output logic
    always_comb begin
        
		  led_green1 = (state == S0 || state == SUCCESS);
		  
		  led_green2 = (state == S1 || state == SUCCESS);
		  
		  led_green3 = (state == S2 || state == SUCCESS);
		   
		  led_red = (state == ERROR);
		 
    end

endmodule
