module pc_updater(pc, imm, alu_result, s, pc_next);

input signed [7:0] pc;
input [2:0] s;
input signed [31:0] imm;
input [31:0] alu_result;
output reg signed [7:0] pc_next;

always@* begin
	casez (s)
		3'b11?: pc_next = pc + (imm << 1);
		3'b01?: pc_next = alu_result;
		3'b001: pc_next = pc + (imm << 1);
		default: pc_next = pc + 4;
	endcase
end

endmodule
