`default_nettype none
`timescale 1ns/1ps
module tb;
    reg clk, rst_n, ena;
    reg [7:0] ui_in, uio_in;
    wire [7:0] uo_out, uio_out, uio_oe;
    // Limit waveform size during the long V4 timeout test.
    initial begin
        $dumpfile("tb.fst");
        $dumpvars(0, tb);
        #1000000;
        $dumpoff;
    end
`ifdef GL_TEST
    wire VPWR = 1'b1;
    wire VGND = 1'b0;
`endif
    tt_um_digital_multifunction user_project (
`ifdef GL_TEST
        .VPWR(VPWR), .VGND(VGND),
`endif
        .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
        .uio_out(uio_out), .uio_oe(uio_oe),
        .ena(ena), .clk(clk), .rst_n(rst_n)
    );
endmodule
`default_nettype wire
