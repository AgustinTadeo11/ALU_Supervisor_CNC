`default_nettype none

module tt_um_digital_multifunction (
    input wire [7:0] ui_in,
    output reg [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire ena,
    input wire clk,
    input wire rst_n
);
    wire [1:0] mode = uio_in[7:6];
    wire active_step = ena && (mode == 2'b01);
    wire active_v4 = ena && (mode == 2'b10);
    wire [3:0] r;
    wire carry, zero;
    wire falla_step, falla_x, falla_y, falla_general, salida_segura;

    alu_4bits u_alu (
        .A(ui_in[3:0]), .B(ui_in[7:4]), .SEL(uio_in[3:0]),
        .R(r), .Carry(carry), .Zero(zero)
    );
    supervisor_step #(.TIMEOUT(20)) u_step (
        .clk(clk), .reset(~rst_n),
        .step_x(ui_in[0]), .step_y(ui_in[1]),
        .vigilar_movimiento(active_step && ui_in[2]),
        .falla(falla_step)
    );
    supervisor_cnc_v4 #(.PRESCALE(14'd10000), .TIMEOUT_TICKS(11'd2000)) u_v4 (
        .clk(clk), .rst(~rst_n), .step_x(ui_in[0]), .step_y(ui_in[1]),
        .vigilar_x(active_v4 && ui_in[2]), .vigilar_y(active_v4 && ui_in[3]),
        .falla_x(falla_x), .falla_y(falla_y),
        .falla_general(falla_general), .salida_segura(salida_segura)
    );

    always @(*) begin
        uo_out = 8'b0;
        if (ena) begin
            case (mode)
                2'b00: uo_out = {2'b00, zero, carry, r};
                2'b01: uo_out = {7'b0, falla_step};
                2'b10: uo_out = {4'b0, salida_segura, falla_general, falla_y, falla_x};
                default: uo_out = 8'b0;
            endcase
        end
    end
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;
    wire _unused = &{uio_in[5:4], 1'b0};
endmodule
`default_nettype wire
