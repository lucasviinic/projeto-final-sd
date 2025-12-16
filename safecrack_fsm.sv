module safecrack_fsm (
    input  logic       clk,
    input  logic       rstn,
    input  logic [2:0] btn,        // buttons inputs (BTN[2:0])
    output logic       unlocked    // output: 1 when the safe is unlocked
);
    // one-hot encoding
    typedef enum logic [4:0] { 
        S0      = 5'b00001,  // initial state
        S1      = 5'b00010,  // BTN = 1 right
        S2      = 5'b00100,  // BTN = 2 right
        UNLOCKED_ON   = 5'b01000,  // BTN = 3 right -> unlock ON
        UNLOCKED_OFF  = 5'b10000   // unlock OFF

    } state_t;

    state_t state, next_state;
    logic [2:0] btn_prev, btn_edge, btn_pos;
    logic       any_btn_edge;

    localparam int BLINK_DELAY = 50_000_000;    // 1 second delay at 50MHz clock
    logic [$clog2(BLINK_DELAY)-1:0] delay_cnt, next_delay_cnt;
     
     always_comb begin
        btn_pos	= ~btn; // invert buttons to active high
        btn_edge = btn_pos & ~btn_prev; // get 0 -> 1 edges
        any_btn_edge = (|btn_edge); // any button edge detected
     end 
     
    // sequential logic
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            btn_prev    <= 3'b000;
            delay_cnt   <= BLINK_DELAY;
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
                    if (btn_edge == 3'b001) next_state = S1;	// button 0 pressed -> correct input
                    else if (any_btn_edge) next_state = S0; 	// any other invalid input -> restart
                    else next_state = S0;					    // no button pressed -> stay
                end
            S1: begin
                    if (btn_edge == 3'b010) next_state = S2; 		// button 1 pressed -> correct input
                    else if (any_btn_edge) next_state = S0; 	// any other invalid input -> restart
                    else next_state = S1;				// no button pressed -> stay
                end
            S2: begin
                    if (btn_edge == 3'b100) next_state = UNLOCKED_ON;		// button 2 pressed -> correct input
                    else if (any_btn_edge) next_state = S0; 	// any other invalid input -> restart	
                    else next_state = S2;				// no button pressed -> stay
                end
            UNLOCKED_ON: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = UNLOCKED_OFF;
                    next_delay_cnt = BLINK_DELAY;       // reset delay counter
                end
            end

            UNLOCKED_OFF: begin
                if (delay_cnt > 0) begin
                    next_delay_cnt = delay_cnt - 1;
                end else begin
                    next_state     = UNLOCKED_ON;
                    next_delay_cnt = BLINK_DELAY;       // reset delay counter
                end
            end

            default: next_state = S0;
        endcase
    end

    // output logic
    always_comb begin
        unlocked = (state == UNLOCKED_ON);
    end

endmodule
