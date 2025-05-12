module processor(CLOCK_50);

input CLOCK_50;
wire rst, locked, clk, clk_shifted;
pll_shifted pll(.refclk(CLOCK_50), .rst(rst), .locked(locked), .outclk_0(clk), .outclk_1(clk_shifted));
// IFID wires

reg signed [7:0] pc;

wire [31:0] reg_read_data1, reg_read_data2, imm, fetched_instruction;
reg [31:0] instruction;
reg [2:0] alu_opcode;
wire [2:0] alu_opcode_out;
reg branch, memtoreg, memwrite, alusrc, regwrite, halted;
wire branch_out, memtoreg_out, memwrite_out, alusrc_out, regwrite_out; 

// EX wires

reg signed [7:0] pc_ex;

reg [2:0] alu_opcode_ex;
reg branch_ex, memtoreg_ex, memwrite_ex, alusrc_ex, regwrite_ex;
reg [31:0] reg_read_data1_ex, reg_read_data2_ex, imm_ex, instruction_ex;

wire z_flag, eq_flag, forward1, forward2, halt;
wire [31:0] alu_input1, alu_input2_pre, alu_input2, alu_result;
wire signed [7:0] pc_next;

// MEMWB wires

reg signed [7:0] pc_memwb;

reg [31:0] mem_write_addr, mem_write_data, instruction_memwb;
reg memtoreg_memwb, memwrite_memwb, regwrite_memwb;

wire [31:0] mem_read_data, reg_write_data;

//////////////////////////////////////////////////////////////////////////////

// IFID stage

initial begin
	pc = 0; pc_ex = 0; pc_memwb = 0;
	branch_ex = 0; halted = 0;
	alu_opcode = 0; alu_opcode_ex = 0;
	branch = 0; memtoreg = 0; memwrite = 0; alusrc = 0; regwrite = 0;
	branch_ex = 0; memtoreg_ex = 0; memwrite_ex = 0; alusrc_ex = 0; regwrite_ex = 0;
	reg_read_data1_ex = 0; reg_read_data2_ex = 0; imm_ex = 0; instruction_ex = 0;
	mem_write_addr = 0; mem_write_data = 0; instruction_memwb = 0;
	memtoreg_memwb = 0; memwrite_memwb = 0; regwrite_memwb = 0;
end
assign rst = 0;

always@(posedge clk) begin
	if (halt) halted <= halt;
	if (!halted) pc <= branch_ex ? pc_next : pc + 4;
end

always@* begin
	if (branch_ex || halt || halted) begin
		branch = 0;
		memtoreg = 0; 
		memwrite = 0;
		alusrc = 0; 
		regwrite = 0;
		alu_opcode = 3'b0;
		instruction = 8'h00000033;
	end else begin
		branch = branch_out;
		memtoreg = memtoreg_out; 
		memwrite = memwrite_out;
		alusrc = alusrc_out; 
		regwrite = regwrite_out;
		alu_opcode = alu_opcode_out;
		instruction = fetched_instruction;
	end
end

rom instruction_mem(.addr(pc), .data(fetched_instruction));

control_unit control(.instruction(instruction), .branch(branch_out), .memtoreg(memtoreg_out), 
							.alu_opcode(alu_opcode_out), .memwrite(memwrite_out), .alusrc(alusrc_out), .regwrite(regwrite_out));
							
register_file rf(
	.clk(clk), .regwrite_en(regwrite_memwb),
	.read_addr1(instruction[19:15]), .read_addr2(instruction[24:20]), .write_addr(instruction_memwb[11:7]), 
	.read_data1(reg_read_data1), .read_data2(reg_read_data2), .write_data(reg_write_data));

imm_gen immgen(.instruction(instruction), .imm(imm));

// EX stage

always@(posedge clk) begin
	pc_ex <= pc;
	alu_opcode_ex <= alu_opcode;
	branch_ex <= branch;
	memtoreg_ex <= memtoreg;
	memwrite_ex <= memwrite;
	alusrc_ex <= alusrc;
	regwrite_ex <= regwrite;
	reg_read_data1_ex <= reg_read_data1;
	reg_read_data2_ex <= reg_read_data2;
	imm_ex <= imm;
	instruction_ex <= instruction;
end

assign halt = &instruction_ex[6:0];
assign eq_flag = instruction_ex[12] ? ~z_flag : z_flag;
assign alu_input1 = forward1 ? reg_write_data : reg_read_data1_ex;
assign alu_input2_pre = forward2 ? reg_write_data : reg_read_data2_ex;
assign alu_input2 = alusrc_ex ? imm_ex : alu_input2_pre;
alu alu(.input1(alu_input1), .input2(alu_input2), .opcode(alu_opcode_ex), .result(alu_result), .z_flag(z_flag));
pc_updater pc_u(.pc(pc_ex), .imm(imm_ex), .alu_result(alu_result), .s({instruction_ex[3:2], eq_flag}), .pc_next(pc_next));
forwarding_unit fu(.rd(instruction_memwb[11:7]), .rs1(instruction_ex[19:15]), .rs2(instruction_ex[24:20]), .regwrite(regwrite_memwb), .forward1(forward1), .forward2(forward2));

// MEMWB Stage

always@(posedge clk) begin
	pc_memwb <= pc_ex;
	mem_write_addr <= alu_result;
	mem_write_data <= alu_input2_pre;
	instruction_memwb <= instruction_ex;
	memtoreg_memwb <= memtoreg_ex;
	memwrite_memwb <= memwrite_ex;
	regwrite_memwb <= regwrite_ex;
end

ram_ip data_mem(.address(mem_write_addr), .clock(clk_shifted), .data(mem_write_data), .wren(memwrite_memwb), .q(mem_read_data));
reg_write_data_selector reg_wd_sel(.pc(pc_memwb), .s({instruction_memwb[2], memtoreg_memwb}), .mem_read_data(mem_read_data), .alu_result(mem_write_addr), .reg_write_data(reg_write_data));

endmodule