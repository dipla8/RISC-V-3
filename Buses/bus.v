`ifndef TESTBENCH
`include "config.vh"
`else
`include "../includes/config.vh"
`endif
module bus( input clk,
            input write_pc,
            input [31:0] PC,
            input [31:0] data_addr,
            input ren,
            input wen,
            input btn_out,
            input [31:0] memory_out,
            input [31:0] flash_out,
            input [31:0] uart_out,
            input [31:0] counter27M,
            input [31:0] counter1M,
            input [31:0] program_mem_out, // ADD
            input [31:0] usb_out,
            input [31:0] clint_data_out,

            input [31:0] boot_instr,
            input [31:0] program_instr,

            output reg clint_ren,
            output reg clint_wen,
            output reg mem_ren,
            output reg mem_wen,
            output reg program_mem_ren,  // ADD
            output reg program_mem_wen,  // ADD
            output reg screen_ren,
            output reg screen_wen,
            output reg flash_ren,
            output reg flash_wen,
            output reg uart_ren,
            output reg btn_ren,
            output reg usb_ren,

            output[31:0] data_out,
            output reg [31:0] instr_out
);
reg [31:0]data_read;
reg [31:0]data_read_reg;
reg write_pc_reg;
assign data_out = (write_pc)?data_read:data_read_reg;

always@(posedge clk)begin
    write_pc_reg<=write_pc;
    if(write_pc)begin
        data_read_reg <= data_read;
    end
end


always@(*) begin
    
    //************************ INSTRUCTIONS ************************//

    if(PC <= `BOOTLOADER_END)begin
        instr_out = boot_instr;
    end
    else if( PC >= `PROGRAM_MEMORY_START && PC < `PROGRAM_MEMORY_END)begin
        instr_out = program_instr;
    end
    else
        instr_out = 32'b0;

    //************************ DATA ************************//

    program_mem_ren = 0;
    program_mem_wen = 0;
    mem_ren = 0;
    mem_wen = 0;
    screen_ren = 0;
    screen_wen = 0;
    flash_ren = 0;
    flash_wen = 0;
    btn_ren = 0;
    data_read = 0;
    uart_ren = 0;
    usb_ren = 0;
    clint_ren = 0;
    clint_wen = 0;

    // memory mapped screen, the range is times 2 due to the use of halfword
    if(data_addr >=`SCREEN_ADDRESS && data_addr <(`SCREEN_END)) begin
        screen_wen = wen;
        data_read = memory_out;
    end
    // memory mapped button
    else if(data_addr >= `BUTTON_ADDRESS && data_addr < (`BUTTON_ADDRESS+16)) begin
        btn_ren = ren;
        data_read = (btn_out==1'b1)?32'b0:32'h1010101;
    end
    else if(data_addr == `COUNTER1M_ADDRESS) begin
        data_read = counter1M;
    end
    else if(data_addr == `COUNTER27M_ADDRESS) begin
        data_read = counter27M;
    end
    else if(data_addr >= `FLASH_CONTROLLER_ADRESS && data_addr <(`FLASH_CONTROLLER_END)) begin
        flash_ren = ren;
        flash_wen = wen;
        data_read =  flash_out;
    end
    else if(data_addr >= `PROGRAM_MEMORY_START && data_addr < (`PROGRAM_MEMORY_END))begin
        program_mem_ren = ren;
        program_mem_wen = wen;
        data_read = program_mem_out;
    end
    else if(data_addr >= `UART_ADDRESS && data_addr < (`UART_END)) begin
        usb_ren = ren;
        data_read = usb_out;
    end
    else if(data_addr >= `USB_CONTROLLER_ADRESS && data_addr < (`USB_CONTROLLER_END)) begin
        usb_ren = ren;
        data_read = usb_out;
    end
    else if(data_addr >= `CLINT_START && data_addr < (`CLINT_END)) begin
        clint_ren = ren;
        clint_wen = wen;
        data_read = clint_data_out;
    end
    else begin
        mem_ren = ren;
        mem_wen = wen;
        data_read = memory_out;
    end
end


endmodule