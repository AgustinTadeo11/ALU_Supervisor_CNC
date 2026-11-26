`default_nettype none
module supervisor_step #(
    parameter integer TIMEOUT = 20
)(
    input wire clk, reset, step_x, step_y, vigilar_movimiento,
    output reg falla
);
    localparam integer BITS_CONTADOR = (TIMEOUT > 1) ? $clog2(TIMEOUT) : 1;
    localparam integer LIMITE = TIMEOUT - 1;
    reg [BITS_CONTADOR-1:0] contador;
    reg x_meta, x_sync, x_anterior;
    reg y_meta, y_sync, y_anterior;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_meta <= 1'b0; x_sync <= 1'b0; x_anterior <= 1'b0;
            y_meta <= 1'b0; y_sync <= 1'b0; y_anterior <= 1'b0;
        end else begin
            x_meta <= step_x; x_sync <= x_meta; x_anterior <= x_sync;
            y_meta <= step_y; y_sync <= y_meta; y_anterior <= y_sync;
        end
    end
    wire pulso_x = x_sync && !x_anterior;
    wire pulso_y = y_sync && !y_anterior;
    wire pulso_step = pulso_x || pulso_y;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            contador <= {BITS_CONTADOR{1'b0}};
            falla <= 1'b0;
        end else if (falla) begin
            falla <= 1'b1;
        end else if (!vigilar_movimiento) begin
            contador <= {BITS_CONTADOR{1'b0}};
        end else if (pulso_step) begin
            contador <= {BITS_CONTADOR{1'b0}};
        end else if (contador >= LIMITE[BITS_CONTADOR-1:0]) begin
            falla <= 1'b1;
        end else begin
            contador <= contador + 1'b1;
        end
    end
endmodule
`default_nettype wire
