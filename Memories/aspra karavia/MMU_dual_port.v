
module memory_management_unit(
    input clk,
    input reset,
    input [31:0] DataAddress,
    input [31:0] DataIn,
    input [31:0] PC,
    input write_enable,
    input read_enable,
    input instr_enable,
    input [3:0] byte_select_vector,
    output reg [31:0] DataOut,
    output reg [31:0] InstOut,
    output reg stall
);

    // States (STATE_InstRes_DataRes)
    parameter STATE_CACHE = 4'd0;
    parameter STATE_MAIN_MEMORY = 4'd1;
    parameter STATE_INST_TO_CACHE = 4'd2;
    parameter STATE_WAIT =  4'd3;
    parameter STATE_WRITE_DATA =  4'd4;
    parameter STATE_HIT_MAIN_MEMORY =  4'd5;

    // FSM
    reg [3:0] current_state;
    reg [3:0] next_state;
    reg [3:0] test = 0;

    // Cache
    reg [31:0] CacheAddress;
    reg [31:0] CacheData_in;
    reg [31:0] Instruction;
    reg cache_write_enable = 0;
    reg cache_read_enable = 1;
    reg hit_reg; 
    wire hit;
    wire [31:0] temp_out;

    // Main Memory
    wire [31:0] MainMem_data_out;
    reg [31:0] MainMem_PC;
    wire [31:0] MainMem_instr_out;
    reg MainMem_write_enable;
    reg MainMem_read_enable;
    wire ready;
    reg [31:0] HoldData;

    memory memory_inst(
        .clk(clk),
        .PC(MainMem_PC),
        .reset(reset),
        .instr(MainMem_instr_out),
        .data_addr(DataAddress),
        .wen(MainMem_write_enable),
        .ren(MainMem_read_enable),
        .data_in(DataIn),
        .data_out(MainMem_data_out),
        .byte_select_vector(byte_select_vector),
        .ready(ready)
    );


    direct_mapped_cache #(
        .DATA_WIDTH(32),
        .ADDR_SIZE(32),
        .CACHE_LINES(64)
    ) InstCache (
        .clk(clk),
        .reset(reset),
        .address(PC),
        .data_in(Instruction),
        .write_enable(cache_write_enable),
        .read_enable(cache_read_enable),
        .data_out(temp_out),
        .hit(hit)
    );

    always  @(posedge clk or posedge reset) begin
        if(reset) begin
            current_state <= STATE_CACHE;
            InstOut <= 32'b0;
            MainMem_PC <= 0;
            MainMem_write_enable <= 0;
            MainMem_read_enable <= 0;
        end
        else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
       case(current_state)
            STATE_CACHE: begin
                if(reset)begin
                    stall = 1;
                    next_state = STATE_WAIT;
                end
                else begin
                    cache_read_enable = 0;
                    stall = 1;
                    if(hit) begin
                        stall = 1;
                        hit_reg = 1;
                        InstOut = temp_out;
                        cache_read_enable = 1;
                        next_state = STATE_CACHE;
                    end
                    else begin
                        hit_reg = 0;
                        MainMem_PC = PC;
                        next_state = STATE_MAIN_MEMORY;
                        stall = 0;
                        cache_read_enable = 0;
                    end

                    if(write_enable) begin
                        stall = 0;
                        MainMem_write_enable = 1;
                        next_state = STATE_MAIN_MEMORY;
                    end
                    
                    if(read_enable) begin
                        stall = 0;
                        MainMem_read_enable = 1;
                        next_state = STATE_MAIN_MEMORY;
                    end
                end
            end

            STATE_WAIT: begin
                stall = 0;
                cache_read_enable = 1;
                next_state = STATE_CACHE;
            end

            STATE_MAIN_MEMORY: begin
                if(!ready) begin
                    stall = 0;
                    next_state = STATE_MAIN_MEMORY;
                end
                else begin
                    stall = 1;
                    MainMem_write_enable = 0;
                    MainMem_read_enable = 0;
                    HoldData = MainMem_data_out;
                    next_state = STATE_INST_TO_CACHE;

                    if(!hit) begin
                        Instruction = MainMem_instr_out;
                        InstOut = MainMem_instr_out;
                        cache_write_enable = 1;
                        cache_read_enable = 0;
                    end
                    
                end
            end

            STATE_INST_TO_CACHE: begin
                DataOut = HoldData;
                stall = 0;
                if(instr_enable) begin
                    cache_write_enable = 0;
                    cache_read_enable = 1;
                    next_state = STATE_CACHE;
                end
                else begin
                    next_state = STATE_INST_TO_CACHE;
                end
            end

            default: begin
                cache_read_enable = 1;
                next_state = STATE_CACHE;
            end

        endcase
    end


    endmodule
