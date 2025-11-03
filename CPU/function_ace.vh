function [4:0] first_ace_func(input [31:0] in_num2);
    integer i;
    reg found;
    begin
        first_ace_func = 5'd0;
        found = 1'b0;
        for (i = 31; i >= 0; i = i - 1) begin
            if (in_num2[i] && !found) begin
                first_ace_func = i[4:0];
                found = 1'b1;
            end
        end
    end
endfunction

