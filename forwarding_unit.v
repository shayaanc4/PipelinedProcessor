module forwarding_unit(rd, rs1, rs2, regwrite, forward1, forward2);

input [4:0] rs1, rs2, rd;
input regwrite;
output forward1, forward2;

assign forward1 = regwrite && (|rd) && (rd == rs1);
assign forward2 = regwrite && (|rd) && (rd == rs2);

endmodule