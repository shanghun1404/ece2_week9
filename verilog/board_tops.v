module lab9_a_input(
    input wire clk,reset_sw,line_sw,
    input wire [11:0] key,
    output wire LCD_E,LCD_RS,LCD_RW,
    output wire [7:0] LCD_DATA,LED_out
);
    // SW1 ON asserts reset; asynchronous assertion, synchronous release.
    (* ASYNC_REG="TRUE" *) reg [1:0] release_sync=0;
    always @(posedge clk or posedge reset_sw)
        if(reset_sw) release_sync<=0;
        else release_sync<={release_sync[0],1'b1};
    lcd_cursor #(.ENABLE_LINE(0),.WRAP(0)) U0(
        .clk(clk),.nrst(release_sync[1]),
        .number_btn({key[0],key[1],key[2],key[3],key[4],
                      key[5],key[6],key[7],key[8],key[10]}),
        .control_btn({key[9],key[11]}),.line_select(line_sw),
        .LCD_E(LCD_E),.LCD_RS(LCD_RS),.LCD_RW(LCD_RW),
        .LCD_DATA(LCD_DATA),.LED_out(LED_out));
endmodule

module lab9_b_line(
    input wire clk,reset_sw,line_sw,
    input wire [11:0] key,
    output wire LCD_E,LCD_RS,LCD_RW,
    output wire [7:0] LCD_DATA,LED_out
);
    // SW1 ON asserts reset; asynchronous assertion, synchronous release.
    (* ASYNC_REG="TRUE" *) reg [1:0] release_sync=0;
    always @(posedge clk or posedge reset_sw)
        if(reset_sw) release_sync<=0;
        else release_sync<={release_sync[0],1'b1};
    lcd_cursor #(.ENABLE_LINE(1),.WRAP(0)) U0(
        .clk(clk),.nrst(release_sync[1]),
        .number_btn({key[0],key[1],key[2],key[3],key[4],
                      key[5],key[6],key[7],key[8],key[10]}),
        .control_btn({key[9],key[11]}),.line_select(line_sw),
        .LCD_E(LCD_E),.LCD_RS(LCD_RS),.LCD_RW(LCD_RW),
        .LCD_DATA(LCD_DATA),.LED_out(LED_out));
endmodule

module lab9_c_wrap(
    input wire clk,reset_sw,line_sw,
    input wire [11:0] key,
    output wire LCD_E,LCD_RS,LCD_RW,
    output wire [7:0] LCD_DATA,LED_out
);
    // SW1 ON asserts reset; asynchronous assertion, synchronous release.
    (* ASYNC_REG="TRUE" *) reg [1:0] release_sync=0;
    always @(posedge clk or posedge reset_sw)
        if(reset_sw) release_sync<=0;
        else release_sync<={release_sync[0],1'b1};
    lcd_cursor #(.ENABLE_LINE(1),.WRAP(1)) U0(
        .clk(clk),.nrst(release_sync[1]),
        .number_btn({key[0],key[1],key[2],key[3],key[4],
                      key[5],key[6],key[7],key[8],key[10]}),
        .control_btn({key[9],key[11]}),.line_select(line_sw),
        .LCD_E(LCD_E),.LCD_RS(LCD_RS),.LCD_RW(LCD_RW),
        .LCD_DATA(LCD_DATA),.LED_out(LED_out));
endmodule
