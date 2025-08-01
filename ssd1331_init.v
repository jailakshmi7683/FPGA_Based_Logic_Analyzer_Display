module ssd1331_init(
// SSD1331 OLED initialization FSM (NUM_CMDS = 37)
    input wire clk,
    input wire rst,
    output reg [7:0] spi_data,
    output reg spi_start,
    input wire spi_done,
    output reg dc,
    output reg res_n,
    output reg init_done
);
    parameter S_IDLE     = 3'd0;
    parameter S_RESET    = 3'd1;
    parameter S_WAIT     = 3'd2;
    parameter S_SEND_CMD = 3'd3;
    parameter S_WAIT_SPI = 3'd4;
    parameter S_DONE     = 3'd5;

    reg [2:0] state;
    parameter NUM_CMDS = 37;
    reg [7:0] init_cmds [0:NUM_CMDS-1];
    reg [5:0] cmd_idx;
    reg [19:0] rst_cnt; // 100MHz
    parameter RST_HOLD = 20'd200_000; // 2ms @ 100MHz

    initial begin
        init_cmds[0]  = 8'hAE; // Display off
        init_cmds[1]  = 8'hA0; // Set re-map & color depth
        init_cmds[2]  = 8'h72; // RGB color
        init_cmds[3]  = 8'hA1; // Set display start line
        init_cmds[4]  = 8'h00;
        init_cmds[5]  = 8'hA2; // Set display offset
        init_cmds[6]  = 8'h00;
        init_cmds[7]  = 8'hA4; // Normal display
        init_cmds[8]  = 8'hA8; // Set multiplex ratio
        init_cmds[9]  = 8'h3F;
        init_cmds[10] = 8'hAD; // Set master config
        init_cmds[11] = 8'h8E;
        init_cmds[12] = 8'hB0; // Power save
        init_cmds[13] = 8'h0B;
        init_cmds[14] = 8'hB1; // Phase 1 & 2 period
        init_cmds[15] = 8'h31;
        init_cmds[16] = 8'hB3; // Display clock div
        init_cmds[17] = 8'hF0;
        init_cmds[18] = 8'h8A; // Precharge
        init_cmds[19] = 8'h64;
        init_cmds[20] = 8'h8B; // Precharge 
        init_cmds[21] = 8'h78;
        init_cmds[22] = 8'h8C; // Precharge 
        init_cmds[23] = 8'h64;
        init_cmds[24] = 8'hBB; // Precharge level
        init_cmds[25] = 8'h3A;
        init_cmds[26] = 8'hBE; // VCOMH
        init_cmds[27] = 8'h3E;
        init_cmds[28] = 8'h87; // Master current
        init_cmds[29] = 8'h06;
        init_cmds[30] = 8'h81; // Contrast A (Red)
        init_cmds[31] = 8'h91;
        init_cmds[32] = 8'h82; // Contrast B (Green)
        init_cmds[33] = 8'h50;
        init_cmds[34] = 8'h83; // Contrast C (Blue)
        init_cmds[35] = 8'h7D;
        init_cmds[36] = 8'hAF; // Display ON
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= S_RESET;
            cmd_idx   <= 0;
            spi_start <= 0;
            spi_data  <= 0;
            dc        <= 0;
            res_n     <= 0;
            init_done <= 0;
            rst_cnt   <= 0;
        end else begin
           case (state)
                S_RESET: begin
                    res_n   <= 0;
                    rst_cnt <= rst_cnt + 1;
                    if (rst_cnt > RST_HOLD) begin
                        res_n   <= 1; // Release reset
                        rst_cnt <= 0;
                        state   <= S_WAIT;
                    end
                end
                S_WAIT: begin
                    rst_cnt <= rst_cnt + 1;
                    if (rst_cnt > RST_HOLD) begin
                        rst_cnt <= 0;
                        state   <= S_SEND_CMD;
                    end
                end
                S_SEND_CMD: begin
                    if (cmd_idx < NUM_CMDS) begin
                        spi_data  <= init_cmds[cmd_idx];
                        spi_start <= 1;
                        dc        <= 0;
                        state     <= S_WAIT_SPI;
                    end else begin
                        state     <= S_DONE;
                        init_done <= 1;
                    end
                end
                S_WAIT_SPI: begin
                    spi_start <= 0;
                    if (spi_done) begin
                        cmd_idx <= cmd_idx + 1;
                        state   <= S_SEND_CMD;
                    end
                end
                S_DONE: begin
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
