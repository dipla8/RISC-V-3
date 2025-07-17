/*module mmu_fsm_logic 

    parameter CACHE_STATE = 2'b01;
    parameter MEM_STATE = 2'b10;
    parameter RESET_STATE = 2'b00;
    

    input clk, reset;

    reg [2:0] current_state, next_state;

    always @(negedge clk or posedge reset) begin
        
        if (reset) 
           current_state <= RESET_STATE;
        else 
            current_state <= next_state;
    end



    always @(*) begin
        
        case (current_state)

            RESET_STATE: begin
                cache_ren <= 1;
                cache_wen <= 0;
                mem_ren <= 0;
                next_state <= CACHE_STATE;
            end

            CACHE_STATE: begin
                
                if (miss) begin
                    
                    mem_ren <= 1;
                    cache_ren <= 0;
                    cache_wen <= 0;
                    next_state <= MEM_STATE;

                end
                else 
                   next_state <= CACHE_STATE; 
                
            end

            MEM_STATE: begin
                cache_ren <= 1;
                cache_wen <= 1;
                mem_ren <= 0;
                next_state <= CACHE_STATE;
            end
            default:

        endcase
    end
endmodule
*/
