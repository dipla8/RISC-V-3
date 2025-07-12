module direct_mapped_cache #(
    parameter DATA_WIDTH = 32, 
    parameter ADDR_SIZE = 32,  
    parameter CACHE_LINES = 16  // Total lines, divided into sets
)(
    input clk,                       
    input reset,                     
    input [ADDR_SIZE-1:0] address,     
    input [DATA_WIDTH-1:0] data_in,   
    input write_enable,             
    input read_enable,                           
    output reg [DATA_WIDTH-1:0] data_out, 
    output reg hit,
    output reg stall
);

    localparam NUM_SETS = CACHE_LINES / 2;  // Number of sets for 2-way associativity

    reg [DATA_WIDTH-1:0] data_mem [0:NUM_SETS-1][0:1];  
    reg [ADDR_SIZE-1:0] tag_mem [0:NUM_SETS-1][0:1];    
    reg valid [0:NUM_SETS-1][0:1];                     

    wire [ADDR_SIZE-5:0] tag = address[ADDR_SIZE-1:4];  
    wire [3:0] index = address[3:0] % NUM_SETS;         

    integer i;
    reg way_to_replace;  // Replacement policy bit (0 or 1)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all cache lines
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                valid[i][0] <= 1'b0;
                valid[i][1] <= 1'b0;
            end
            hit <= 1'b0;
            stall <= 1'b0;
        end 
        else begin
            hit <= 1'b0;  // Default no hit unless read matches

            // READ OPERATION 
            if (read_enable) begin
                if (valid[index][0] && (tag_mem[index][0] == tag)) begin
                    data_out <= data_mem[index][0];
                    hit <= 1'b1;
                end
                else if (valid[index][1] && (tag_mem[index][1] == tag)) begin
                    data_out <= data_mem[index][1];
                    hit <= 1'b1;
                end
            end

            // WRITE OPERATION 
            if (write_enable) begin
                way_to_replace = valid[index][0] ? 1 : 0;  // Choose invalid way or use LRU policy

                data_mem[index][way_to_replace] <= data_in;
                tag_mem[index][way_to_replace] <= tag;
                valid[index][way_to_replace] <= 1'b1;

                hit <= 1'b0;  // Ensure no hit signal on writes
            end
        end
    end
endmodule
