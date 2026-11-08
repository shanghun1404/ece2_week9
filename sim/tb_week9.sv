`timescale 1us/1ns
module tb_week9;
    reg clk=0, nrst=0;
    always #0.5 clk=~clk;
    reg [9:0] number_btn=0;
    reg [1:0] control_btn=0;
    wire LCD_E,LCD_RS,LCD_RW;
    wire [7:0] LCD_DATA,LED_out;
    lcd_cursor basic(.clk(clk),.nrst(nrst),.number_btn(number_btn),
        .control_btn(control_btn),.line_select(1'b0),
        .LCD_E(LCD_E),.LCD_RS(LCD_RS),.LCD_RW(LCD_RW),
        .LCD_DATA(LCD_DATA),.LED_out(LED_out));
    integer transactions=0, writes=0, lefts=0, rights=0;
    reg [7:0] digits[0:1];
    reg [7:0] init_seq[0:7];
    real raised=0, changed=0, last_fall=-10000;
    always @(LCD_RS or LCD_DATA) if(nrst) begin
        if(LCD_E) $fatal(1,"FAIL: data changes while E high");
        changed=$realtime;
    end
    always @(posedge LCD_E) if(nrst) begin
        if($realtime-changed<0.999) $fatal(1,"FAIL: setup time");
        raised=$realtime;
    end
    always @(negedge LCD_E) if(nrst) begin
        if(LCD_RW!==0) $fatal(1,"FAIL: R/W must remain zero");
        if($realtime-raised<499.999) $fatal(1,"FAIL: E high width");
        if($realtime-last_fall<999.999) $fatal(1,"FAIL: bus spacing");
        last_fall=$realtime;
        if(transactions<8) begin
            if(LCD_RS!==0 || LCD_DATA!==init_seq[transactions])
                $fatal(1,"FAIL: initialization %0d got %02h",transactions,LCD_DATA);
        end else if(LCD_RS) begin
            if(writes>=2 || LCD_DATA!==digits[writes]) $fatal(1,"FAIL: digit data");
            writes=writes+1;
        end else if(LCD_DATA==8'h10) lefts=lefts+1;
        else if(LCD_DATA==8'h14) rights=rights+1;
        else $fatal(1,"FAIL: unexpected idle command %02h",LCD_DATA);
        $display("BUS %0.3f us RS=%b DATA=%02h",$realtime,LCD_RS,LCD_DATA);
        transactions=transactions+1;
    end
    task press_number(input integer bit_index);
        @(negedge clk); number_btn=10'b1<<bit_index;
        #45000; @(negedge clk); number_btn=0;
        #15000;
    endtask
    task press_control(input [1:0] value);
        @(negedge clk); control_btn=value;
        #45000; @(negedge clk); control_btn=0;
        #15000;
    endtask
    initial begin
        init_seq[0]=8'h38; init_seq[1]=8'h38; init_seq[2]=8'h38;
        init_seq[3]=8'h0f; init_seq[4]=8'h06;
        init_seq[5]=8'h01; init_seq[6]=8'h80; init_seq[7]=8'h0f;
        digits[0]=8'h32; digits[1]=8'h39;
        #10; @(negedge clk); nrst=1;
        #280000;
        if(transactions!=8) $fatal(1,"FAIL: initialization expected 8 writes, got %0d",transactions);
        press_number(8); // 2: number_btn[8], same order as lesson
        press_number(1); // 9
        press_control(2'b10); // * left
        press_control(2'b01); // # right
        #10000;
        if(writes!=2 || lefts!=1 || rights!=1 || transactions!=12)
            $fatal(1,"FAIL: expected exactly 2 digits + left + right");
        $display("WEEK9_PASS: 2 digits, left/right once; 1MHz, 500us E, 1ms spacing");
        $finish;
    end
    initial begin #700000; $fatal(1,"FAIL: watchdog"); end
endmodule
