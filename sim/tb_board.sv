`timescale 1us/1ns
module tb_board;
    reg clk=0,reset_sw=1,line_sw=0;
    reg [11:0] key=0;
    always #0.5 clk=~clk;
    wire en,rs,rw;
    wire [7:0] data,led;
    lab9_c_wrap dut(.clk(clk),.reset_sw(reset_sw),.line_sw(line_sw),.key(key),
        .LCD_E(en),.LCD_RS(rs),.LCD_RW(rw),.LCD_DATA(data),.LED_out(led));
    integer writes=0;
    reg [7:0] expected;
    always @(negedge en) if(!reset_sw && rs) begin
        if(rw || data!==expected) $fatal(1,"FAIL: physical keypad map got %02h expected %02h",data,expected);
        writes=writes+1;
    end
    task press(input integer physical,input [7:0] value);
        expected=value;
        @(negedge clk); key=12'b1<<physical; #45000;
        @(negedge clk); key=0; #15000;
    endtask
    integer i;
    initial begin
        #10; reset_sw=0; #280000;
        for(i=0;i<9;i=i+1) press(i,8'h31+i);
        press(10,8'h30);
        if(writes!=10) $fatal(1,"FAIL: missing board key event");
        @(negedge clk); key=12'b1<<9; #45000;
        @(negedge clk); key=0; #15000;
        if(dut.U0.cursor_addr!=9) $fatal(1,"FAIL: SM10 left mapping");
        @(negedge clk); key=12'b1<<11; #45000;
        @(negedge clk); key=0; #15000;
        if(dut.U0.cursor_addr!=10) $fatal(1,"FAIL: SM12 right mapping");
        line_sw=1; #45000;
        if(dut.U0.cursor_addr!=7'h4a) $fatal(1,"FAIL: SW2 row selection");
        reset_sw=1; #1;
        if(en!==0 || led!==0) $fatal(1,"FAIL: SW1 reset polarity");
        #10; reset_sw=0; line_sw=0; #280000;
        if(dut.U0.cursor_addr!=0 || dut.U0.state!=5) $fatal(1,"FAIL: board reset restart");
        $display("BOARD_PASS: physical 12-key map, SW1 reset, SW2 rows, 1MHz timing");
        $finish;
    end
    initial begin #1500000; $fatal(1,"FAIL: board watchdog"); end
endmodule
