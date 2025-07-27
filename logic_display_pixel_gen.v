module logic_display_pixel_gen(
    input [3:0] sample,
    input [6:0] x,
    input [5:0] y,
    output reg [15:0] pixel_color
);

    // RGB565 colors
    localparam COLOR_RED    = 16'hF800;  // CH0
    localparam COLOR_GREEN  = 16'h07E0;  // CH1
    localparam COLOR_BLUE   = 16'h001F;  // CH2
    localparam COLOR_YELLOW = 16'hFFE0;  // CH3
    localparam COLOR_WHITE  = 16'hFFFF;
    localparam COLOR_BLACK  = 16'h0000;

    always @(*) begin
        // Label zones on the left (x = 0-7)
        if (x < 8) begin
            if (y < 16)        pixel_color = COLOR_RED;    // CH0 stripe
            else if (y < 32)   pixel_color = COLOR_GREEN;  // CH1 stripe
            else if (y < 48)   pixel_color = COLOR_BLUE;   // CH2 stripe
            else               pixel_color = COLOR_YELLOW; // CH3 stripe
        end
        // Waveform zone
        else begin
            if (y < 16)
                pixel_color = sample[0] ? COLOR_RED : COLOR_BLACK;
            else if (y < 32)
                pixel_color = sample[1] ? COLOR_GREEN : COLOR_BLACK;
            else if (y < 48)
                pixel_color = sample[2] ? COLOR_BLUE : COLOR_BLACK;
            else
                pixel_color = sample[3] ? COLOR_YELLOW : COLOR_BLACK;
        end
    end
endmodule
