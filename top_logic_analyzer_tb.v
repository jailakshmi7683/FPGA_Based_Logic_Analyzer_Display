module top_logic_analyzer_tb;
    // Inputs
    reg clk;
    reg rst;
    reg [3:0] logic_in_external;
    reg speed_switch;
    reg mode_select;
    reg freeze_button;

    // Outputs
    wire sclk;
    wire mosi;
    wire cs;
    wire dc;
    wire res_n;
    wire vccen;
    wire pmoden;

    // Instantiate the DUT
    top_logic_analyzer uut (
        .clk(clk),
        .rst(rst),
        .logic_in_external(logic_in_external),
        .speed_switch(speed_switch),
        .mode_select(mode_select),
        .freeze_button(freeze_button),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs),
        .dc(dc),
        .res_n(res_n),
        .vccen(vccen),
        .pmoden(pmoden)
    );

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;
    // Stimulus
    initial begin
        // Start with reset
        rst = 1;
        mode_select = 0;
        freeze_button = 0;
        logic_in_external = 4'b0000;
        speed_switch = 0;

        #100;
        rst = 0;
        // External signals active
        #1000 logic_in_external = 4'b1010;
        #1000 logic_in_external = 4'b1100;

        // =Toggle mode_select HIGH=
        #1000 mode_select = 1;
        #2000 mode_select = 0;

        // === Press freeze_button ===
        #2000 freeze_button = 1;
        #2000 freeze_button = 0;
        // === Toggle again ===
        #2000 mode_select = 1;
        #2000 freeze_button = 1;
        #2000 mode_select = 0;
        #2000 freeze_button = 0;
        #10000;
        $finish;
    end
endmodule
