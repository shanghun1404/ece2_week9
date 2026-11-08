module lcd_cursor_pre #(
    parameter integer TICK_CYCLES=1000, DEBOUNCE_CYCLES=5000
)(
    input wire clk,nrst,
    input wire [9:0] number_btn,
    input wire [1:0] control_btn, // [1]=* left, [0]=# right
    output reg LCD_E,LCD_RS,
    output wire LCD_RW,
    output reg [7:0] LCD_DATA,LED_out
);
    localparam [2:0] DELAY=0, FUNCTION_SET=1, DISP_ONOFF=2,
        ENTRY_MODE=3, SET_ADDRESS=4, DELAY_T=5, WRITE=6, CURSOR=7;
    localparam integer PW=(TICK_CYCLES<2)?1:$clog2(TICK_CYCLES);
    reg [PW-1:0] phase;
    wire tick=(phase==TICK_CYCLES-1);
    reg pulse_pending;
    reg [2:0] state;
    reg [7:0] cnt;
    reg [6:0] cursor_addr,target_addr;
    reg [1:0] pending_kind; // 0=none, 1=digit, 2=left, 3=right
    reg [7:0] pending_data,latched_data;
    reg direction_right;
    wire [11:0] key_pulse;
    wire [9:0] number_btn_t=key_pulse[11:2];
    wire [1:0] control_btn_t=key_pulse[1:0];
    key_onepulse #(.WIDTH(12),.STABLE_CYCLES(DEBOUNCE_CYCLES)) keys(
        .clk(clk),.nrst(nrst),.raw({number_btn,control_btn}),.pulse(key_pulse));
    function [7:0] ascii_digit(input [9:0] mask);
        begin case(mask)
            10'h200:ascii_digit=8'h31; 10'h100:ascii_digit=8'h32;
            10'h080:ascii_digit=8'h33; 10'h040:ascii_digit=8'h34;
            10'h020:ascii_digit=8'h35; 10'h010:ascii_digit=8'h36;
            10'h008:ascii_digit=8'h37; 10'h004:ascii_digit=8'h38;
            10'h002:ascii_digit=8'h39; default:ascii_digit=8'h30;
        endcase end
    endfunction
    function [6:0] native_right(input [6:0] addr);
        native_right=(addr==7'h27)?7'h40:(addr==7'h67)?0:addr+1'b1;
    endfunction
    function [6:0] native_left(input [6:0] addr);
        native_left=(addr==0)?7'h67:(addr==7'h40)?7'h27:addr-1'b1;
    endfunction
    wire one_key=(key_pulse!=0) && ((key_pulse & (key_pulse-1'b1))==0);
    reg command_valid,command_rs;
    reg [7:0] command_data;
    always @* begin
        command_valid=0; command_rs=0; command_data=0;
        case(state)
            FUNCTION_SET: if(cnt==0 || cnt==5 || cnt==10) begin
                command_valid=1; command_data=8'h38;
            end
            DISP_ONOFF: if(cnt==0) begin command_valid=1; command_data=8'h0f; end
            ENTRY_MODE: if(cnt==0) begin command_valid=1; command_data=8'h06; end
            SET_ADDRESS: if(cnt==0 || cnt==5 || cnt==10) begin
                command_valid=1;
                command_data=(cnt==0)?8'h01:(cnt==5)?8'h80:8'h0f;
            end
            WRITE: if(cnt==20) begin
                command_valid=1; command_rs=1; command_data=latched_data;
            end
            CURSOR: if(cnt==20) begin
                command_valid=1; command_data=direction_right?8'h14:8'h10;
            end
            default: ;
        endcase
        LED_out=8'h80 >> state;
        if(!nrst) LED_out=0;
    end
    assign LCD_RW=1'b0;
    // Set RS/data, then raise E one clock later for half a tick.
    always @(posedge clk or negedge nrst) begin
        if(!nrst) begin
            phase<=0; LCD_E<=0; LCD_RS<=0; LCD_DATA<=0; pulse_pending<=0;
        end else if(tick) begin
            phase<=0; LCD_E<=0; pulse_pending<=command_valid;
            if(command_valid) begin LCD_RS<=command_rs; LCD_DATA<=command_data; end
        end else begin
            phase<=phase+1'b1;
            if(phase==0) LCD_E<=pulse_pending;
            if(phase==TICK_CYCLES/2) LCD_E<=0;
        end
    end
    always @(posedge clk or negedge nrst) begin
        if(!nrst) begin
            state<=DELAY; cnt<=0; cursor_addr<=0; target_addr<=0;
            pending_kind<=0; pending_data<=0;
            latched_data<=0; direction_right<=0;
        end else begin
            if(state>=DELAY_T && pending_kind==0 && one_key) begin
                if(|number_btn_t) begin pending_kind<=1; pending_data<=ascii_digit(number_btn_t); end
                else pending_kind<=control_btn_t[1]?2:3;
            end
            if(tick) begin
                case(state)
                    DELAY: if(cnt==69) begin cnt<=0; state<=FUNCTION_SET; end
                           else cnt<=cnt+1'b1;
                    FUNCTION_SET,DISP_ONOFF,ENTRY_MODE: begin
                        if(cnt==29) begin cnt<=0; state<=state+1'b1; end
                        else cnt<=cnt+1'b1;
                    end
                    SET_ADDRESS: if(cnt==99) begin cnt<=0; state<=DELAY_T; end
                                 else cnt<=cnt+1'b1;
                    DELAY_T: begin
                        cnt<=0;
                        if(pending_kind!=0) begin
                            pending_kind<=0;
                            if(pending_kind==1) begin latched_data<=pending_data; state<=WRITE; end
                            else begin
                                direction_right<=(pending_kind==3); state<=CURSOR;
                                target_addr<=(pending_kind==3)?native_right(cursor_addr):native_left(cursor_addr);
                            end
                        end
                    end
                    WRITE: begin
                        if(cnt==20) cursor_addr<=native_right(cursor_addr);
                        if(cnt==29) begin cnt<=0; state<=DELAY_T; end
                        else cnt<=cnt+1'b1;
                    end
                    CURSOR: begin
                        if(cnt==20) cursor_addr<=target_addr;
                        if(cnt==29) begin cnt<=0; state<=DELAY_T; end
                        else cnt<=cnt+1'b1;
                    end
                    default: begin state<=DELAY; cnt<=0; end
                endcase
            end
        end
    end
endmodule
