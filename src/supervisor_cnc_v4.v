/* Supervisor CNC V4 - Tiny Tapeout (GF)
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none
module supervisor_cnc_v4 #(
    parameter [13:0] PRESCALE = 14'd10000,
    parameter [10:0] TIMEOUT_TICKS = 11'd2000
)(
    input wire clk, rst, step_x, step_y, vigilar_x, vigilar_y,
    output wire falla_x, falla_y, falla_general, salida_segura
);
    localparam [13:0] PRESCALE_MAX = PRESCALE - 14'd1;
    localparam [10:0] TIMEOUT_MAX = TIMEOUT_TICKS - 11'd1;
    reg [13:0] divisor;
    wire tick_ms = (divisor == PRESCALE_MAX);
    reg [10:0] tiempo_x, tiempo_y;
    reg fx, fy;
    reg x_meta, x_sync, x_prev;
    reg y_meta, y_sync, y_prev;
    reg vx_meta, vx_sync, vy_meta, vy_sync;
    wire pulso_x = x_sync & ~x_prev;
    wire pulso_y = y_sync & ~y_prev;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            divisor <= 14'd0;
            tiempo_x <= 11'd0; tiempo_y <= 11'd0;
            fx <= 1'b0; fy <= 1'b0;
            x_meta <= 1'b0; x_sync <= 1'b0; x_prev <= 1'b0;
            y_meta <= 1'b0; y_sync <= 1'b0; y_prev <= 1'b0;
            vx_meta <= 1'b0; vx_sync <= 1'b0;
            vy_meta <= 1'b0; vy_sync <= 1'b0;
        end else begin
            x_meta <= step_x; x_sync <= x_meta; x_prev <= x_sync;
            y_meta <= step_y; y_sync <= y_meta; y_prev <= y_sync;
            vx_meta <= vigilar_x; vx_sync <= vx_meta;
            vy_meta <= vigilar_y; vy_sync <= vy_meta;
            if (tick_ms) divisor <= 14'd0;
            else divisor <= divisor + 14'd1;
            if (!fx) begin
                if (!vx_sync || pulso_x) tiempo_x <= 11'd0;
                else if (tick_ms) begin
                    if (tiempo_x == TIMEOUT_MAX) fx <= 1'b1;
                    else tiempo_x <= tiempo_x + 11'd1;
                end
            end
            if (!fy) begin
                if (!vy_sync || pulso_y) tiempo_y <= 11'd0;
                else if (tick_ms) begin
                    if (tiempo_y == TIMEOUT_MAX) fy <= 1'b1;
                    else tiempo_y <= tiempo_y + 11'd1;
                end
            end
        end
    end
    assign falla_x = fx;
    assign falla_y = fy;
    assign falla_general = fx | fy;
    assign salida_segura = ~(fx | fy);
endmodule
`default_nettype wire
