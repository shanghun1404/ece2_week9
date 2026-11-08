// Synchronize, debounce and detect rising edges on active-high switches.
module key_onepulse #(
    parameter integer WIDTH=12, STABLE_CYCLES=5000
)(
    input wire clk, nrst,
    input wire [WIDTH-1:0] raw,
    output reg [WIDTH-1:0] pulse
);
    localparam integer CW=(STABLE_CYCLES<2)?1:$clog2(STABLE_CYCLES);
    (* ASYNC_REG="TRUE" *) reg [WIDTH-1:0] sync1,sync2;
    reg [WIDTH-1:0] stable;
    reg [CW-1:0] count[0:WIDTH-1];
    integer i;
    always @(posedge clk or negedge nrst) begin
        if(!nrst) begin
            sync1<=0; sync2<=0; stable<=0; pulse<=0;
            for(i=0;i<WIDTH;i=i+1) count[i]<=0;
        end else begin
            sync1<=raw; sync2<=sync1; pulse<=0;
            for(i=0;i<WIDTH;i=i+1) begin
                if(sync2[i]==stable[i]) count[i]<=0;
                else if(count[i]==STABLE_CYCLES-1) begin
                    stable[i]<=sync2[i]; count[i]<=0;
                    pulse[i]<=sync2[i];
                end else count[i]<=count[i]+1'b1;
            end
        end
    end
endmodule
