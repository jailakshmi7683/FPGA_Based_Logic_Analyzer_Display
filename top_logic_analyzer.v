module top_logic_analyzer(
   input clk,
    input rst,
    input [3:0] logic_in_external,
    input speed_switch,
    input mode_select,         // 1 = test signal mode, 0 = external input
    input freeze_button,       // 1 = freeze test signal counter
    output sclk,
    output mosi,
    output cs,
    output dc,
    output res_n,
    output vccen,
    output pmoden
);

    // SPI/Init Wiring
    wire spi_done, init_done;
    wire [7:0] spi_data;
    wire spi_start;

    // Sample buffer (96 pixels wide)
    reg [3:0] sample_mem [0:95];
    integer j;
    // Sampling rate
    reg [15:0] sample_counter = 0;
    reg [15:0] sample_rate = 16'd50000;

    // SPI drawing
    wire sclk_int, mosi_int, cs_int, dc_init, res_n_init;
    reg draw_dc = 0;
    reg draw_spi_start = 0;
    reg [7:0] draw_spi_data = 0;
    reg drawing = 0;

    // FSM coordinates
    reg [6:0] x = 0;
    reg [5:0] y = 0;
    reg [4:0] state = 0;

    // Pixel color
    wire [15:0] pixel_color;

    // Internal counter-based test signal generator
    reg [31:0] counter = 0;
    always @(posedge clk) begin
        if (!freeze_button)  // freeze when button is held
            counter <= counter + 1;
    end

    wire [3:0] logic_test;
    assign logic_test[0] = counter[24];                // CH0 - slow
    assign logic_test[1] = counter[23];                // CH1 - medium
    assign logic_test[2] = counter[22];                // CH2 - faster
    assign logic_test[3] = counter[21] ^ counter[20];  // CH3 - dynamic XOR
    // Select input source
    wire [3:0] logic_in;
    assign logic_in = (mode_select) ? logic_test : logic_in_external;

    // Sample and scroll logic
    always @(posedge clk) begin
        sample_rate <= (speed_switch) ? 16'd10000 : 16'd50000;

        sample_counter <= sample_counter + 1;
        if (sample_counter >= sample_rate) begin
            sample_counter <= 0;
            for (j = 0; j < 95; j = j + 1)
                sample_mem[j] <= sample_mem[j + 1];
            sample_mem[95] <= logic_in;
        end
    end

    // OLED Init FSM
    ssd1331_init oled_init (
        .clk(clk),
        .rst(rst),
        .spi_data(spi_data),
        .spi_start(spi_start),
        .spi_done(spi_done),
        .dc(dc_init),
        .res_n(res_n_init),
        .init_done(init_done)
    );

    // SPI Master
    spi_master spi (
        .clk(clk),
        .rst(rst),
        .data_in(drawing ? draw_spi_data : spi_data),
        .start(drawing ? draw_spi_start : spi_start),
        .sclk(sclk_int),
        .mosi(mosi_int),
        .cs(cs_int),
        .done(spi_done)
    );

    // Pixel color generator (you must use the version for 4 channels)
    logic_display_pixel_gen pixel_gen (
        .sample((x < 8) ? 4'b0000 : sample_mem[x - 8]),
        .x(x),
        .y(y),
        .pixel_color(pixel_color)
    );
    // OLED Drawing FSM (1 column per frame)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            x <= 0; y <= 0;
            draw_spi_start <= 0;
            draw_dc <= 0;
            drawing <= 0;
            draw_spi_data <= 0;
        end else if (init_done) begin
            draw_spi_start <= 0;

            case (state)
                0: begin
                    draw_spi_data <= 8'h15;
                    draw_spi_start <= 1;
                    draw_dc <= 0;
                    drawing <= 1;
                    state <= 1;
                end
                1: if (spi_done) begin
                    draw_spi_data <= x;
                    draw_spi_start <= 1;
                    state <= 2;
                end
                2: if (spi_done) begin
                    draw_spi_data <= x;
                    draw_spi_start <= 1;
                    state <= 3;
                end
                3: if (spi_done) begin
                    draw_spi_data <= 8'h75;
                    draw_spi_start <= 1;
                    state <= 4;
                end
                4: if (spi_done) begin
                    draw_spi_data <= 0;
                    draw_spi_start <= 1;
                    state <= 5;
                end
                5: if (spi_done) begin
                    draw_spi_data <= 63;
                    draw_spi_start <= 1;
                    state <= 6;
                end
                6: if (spi_done) begin
                    draw_dc <= 1;
                    y <= 0;
                    state <= 7;
                end
                7: begin
                    draw_spi_data <= pixel_color[15:8];
                    draw_spi_start <= 1;
                    state <= 8;
                end
                8: if (spi_done) begin
                    draw_spi_data <= pixel_color[7:0];
                    draw_spi_start <= 1;
                    state <= 9;
                end
                9: if (spi_done) begin
                    if (y < 63) begin
                        y <= y + 1;
                        state <= 7;
                    end else begin
                        y <= 0;
                        x <= (x + 1) % 96;
                        state <= 0;
                    end
                end
                default: state <= 0;
            endcase
        end
    end
    // Outputs
    assign sclk   = sclk_int;
    assign mosi   = mosi_int;
    assign cs     = cs_int;
    assign dc     = drawing ? draw_dc : dc_init;
    assign res_n  = res_n_init;
    assign vccen  = 1'b1;
    assign pmoden = 1'b1;
endmodule
