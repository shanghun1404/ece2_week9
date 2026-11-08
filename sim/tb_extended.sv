`timescale 1us/1ns
module tb_extended;
    reg clk=0,nrst=0,line_select=0;
    always #0.5 clk=~clk;
    reg [9:0] number_btn=0;
    reg [1:0] control_btn=0;
    wire [2:0] en,rs,rw;
    wire [7:0] data[0:2],led[0:2];
    integer address[0:2],writes[0:2],tx[0:2];
    reg [7:0] memory[0:2][0:127];
    genvar v;
    generate for(v=0;v<3;v=v+1) begin: variants
        lcd_cursor #(.TICK_CYCLES(10),.DEBOUNCE_CYCLES(3),
            .ENABLE_LINE(v!=0),.WRAP(v==2)) dut(
            .clk(clk),.nrst(nrst),.number_btn(number_btn),.control_btn(control_btn),
            .line_select(line_select),.LCD_E(en[v]),.LCD_RS(rs[v]),.LCD_RW(rw[v]),
            .LCD_DATA(data[v]),.LED_out(led[v]));
        integer m;
        always @(negedge nrst) begin address[v]=0; writes[v]=0; tx[v]=0; end
        // Independent LCD DDRAM model, driven only by external bus falling edges.
        always @(negedge en[v]) if(nrst) begin
            if(rw[v]!==0 || $isunknown({rs[v],data[v]})) $fatal(1,"FAIL: invalid bus");
            tx[v]=tx[v]+1;
            if(rs[v]) begin
                memory[v][address[v]]=data[v]; writes[v]=writes[v]+1;
                address[v]=(address[v]==7'h27)?7'h40:
                           (address[v]==7'h67)?0:address[v]+1;
            end else if(data[v][7]) address[v]=data[v]&8'h7f;
            else case(data[v])
                8'h01: begin
                    for(m=0;m<128;m=m+1) memory[v][m]=8'h20;
                    address[v]=0;
                end
                8'h02: address[v]=0;
                8'h10: address[v]=(address[v]==0)?7'h67:
                                   (address[v]==7'h40)?7'h27:address[v]-1;
                8'h14: address[v]=(address[v]==7'h27)?7'h40:
                                   (address[v]==7'h67)?0:address[v]+1;
                default: ;
            endcase
        end
    end endgenerate
    task reset_all;
        @(negedge clk); nrst=0; number_btn=0; control_btn=0; line_select=0;
        #10; @(negedge clk); nrst=1; #2800;
        if(tx[0]!=8 || tx[1]!=8 || tx[2]!=8) $fatal(1,"FAIL: initialization");
    endtask
    task number(input integer digit);
        @(negedge clk); number_btn=10'b1<<((digit==0)?0:10-digit);
        #400; @(negedge clk); number_btn=0; #100;
    endtask
    task shift(input bit rightward);
        @(negedge clk); control_btn=rightward?1:2;
        #400; @(negedge clk); control_btn=0; #100;
    endtask
    integer k,before_count;
    reg [119:0] target="2025440099 1103";
    initial begin
        #1; nrst=1; #1; reset_all;
        for(k=0;k<10;k=k+1) number(k);
        for(k=0;k<10;k=k+1)
            if(memory[2][k]!==8'h30+k) $fatal(1,"FAIL: digit %0d",k);
        $display("CHECK all ten digits");
        before_count=writes[2];
        @(negedge clk); number_btn=10'b1<<7; #1200;
        @(negedge clk); number_btn=0; #100;
        if(writes[2]!=before_count+1) $fatal(1,"FAIL: held key repeats");
        before_count=writes[2];
        repeat(10) begin @(negedge clk); number_btn=10'b1<<6;
            @(negedge clk); number_btn=0; end
        #400;
        if(writes[2]!=before_count) $fatal(1,"FAIL: bounce not rejected");
        @(negedge clk); number_btn=10'b1<<5; #10;
        @(negedge clk); number_btn=0; #400;
        if(writes[2]!=before_count+1 || memory[2][11]!==8'h35)
            $fatal(1,"FAIL: short valid press not retained");
        $display("CHECK debounce, long hold and short captured press");
        before_count=writes[2];
        @(negedge clk); number_btn=10'b11; #400;
        @(negedge clk); number_btn=0; #100;
        @(negedge clk); number_btn=10'b1; control_btn=1; #400;
        @(negedge clk); number_btn=0; control_btn=0; #100;
        if(writes[2]!=before_count) $fatal(1,"FAIL: multi-key must be ignored");
        $display("CHECK simultaneous keys ignored");
        line_select=1; #500;
        if(address[0]!=12 || address[1]!=7'h4c || address[2]!=7'h4c)
            $fatal(1,"FAIL: row change must preserve column");
        number(8);
        if(memory[1][7'h4c]!==8'h38 || memory[2][7'h4c]!==8'h38)
            $fatal(1,"FAIL: row2 data");
        $display("CHECK row selection preserves column and contents");
        reset_all;
        repeat(15) shift(1);
        if(address[2]!=15) $fatal(1,"FAIL: column15 setup");
        shift(1);
        if(address[0]!=16 || address[1]!=16 || address[2]!=0)
            $fatal(1,"FAIL: row1 hidden/native or wrap behavior");
        $display("CHECK A/B native hidden address and C 0F->00");
        line_select=1; #500;
        repeat(15) shift(1);
        if(address[2]!=7'h4f) $fatal(1,"FAIL: row2 column15 setup");
        shift(1);
        if(address[2]!=7'h40) $fatal(1,"FAIL: row2 4F->40");
        shift(0);
        if(address[2]!=7'h4f) $fatal(1,"FAIL: symmetric left wrap");
        number(9);
        if(memory[2][7'h4f]!==8'h39 || address[2]!=7'h40)
            $fatal(1,"FAIL: auto advance after last-column write");
        $display("CHECK row2 right/left wrap and after-write address repair");
        reset_all;
        for(k=0;k<10;k=k+1) number(target[119-k*8-:8]-8'h30);
        shift(1); // leave a blank instead of inserting a numeric character
        for(k=11;k<15;k=k+1) number(target[119-k*8-:8]-8'h30);
        for(k=0;k<15;k=k+1)
            if(memory[0][k]!==target[119-k*8-:8])
                $fatal(1,"FAIL: ID/date output at %0d",k);
        $display("CHECK task A exact student ID + space + 1103");
        reset_all;
        if(writes[2]!=0 || memory[2][0]!==8'h20 || en!==0)
            $fatal(1,"FAIL: reset must clear, reinitialize, and leave E low");
        $display("EXTENDED_PASS: all behavioral checks passed");
        $finish;
    end
    initial begin #100000; $fatal(1,"FAIL: extended watchdog"); end
endmodule
