`default_nettype none
module alu_4bits (
    input wire [3:0] A, B, SEL,
    output reg [3:0] R,
    output reg Carry,
    output wire Zero
);
    reg [7:0] temp;
    assign Zero = (R == 4'b0);
    always @(*) begin
        R = 4'b0;
        Carry = 1'b0;
        temp = 8'b0;
        case (SEL)
            4'b0000: begin
                temp = {4'b0,A} + {4'b0,B};
                R = temp[3:0];
                Carry = temp[4];
            end
            4'b0001: begin
                temp = {4'b0,A} - {4'b0,B};
                R = temp[3:0];
                Carry = temp[4];
            end
            4'b0010: R = A & B;
            4'b0011: R = A | B;
            4'b0100: R = A ^ B;
            4'b0101: R = ~A;
            4'b0110: R = (A == B) ? 4'd1 : 4'd0;
            4'b0111: R = (A < B) ? 4'd1 : 4'd0;
            4'b1000: begin
                temp = {4'b0,A} * {4'b0,B};
                R = temp[3:0];
                Carry = |temp[7:4];
            end
            4'b1001: begin
                if (B != 4'b0) begin
                    R = A / B;
                    Carry = 1'b0;
                end else begin
                    R = 4'b0;
                    Carry = 1'b1;
                end
            end
            default: R = 4'b0;
        endcase
    end
endmodule
`default_nettype wire
