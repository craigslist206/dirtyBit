`include "defines.v"
module cpu(clk, rst_n, hlt, pc);
  input clk, rst_n;
  output hlt;
	output [15:0] pc;

  wire [2:0] flags_EX_FF, branchOp_EX_FF, branchOp_FF_MEM, flags_FF_MEM;

  wire [15:0] FWD_reg1, FWD_reg2;

  wire [15:0] pc_IF_FF, pc_FF_ID, instr_IF_FF, instr_FF_ID, instr_ID_FF, instr_FF_EX,
              sext_FF_EX, sext_ID_FF, aluResult_EX_FF, aluResult_FF_MEM, targetAddr_EX_FF,
              targetAddr_FF_MEM, rdData_MEM_FF, rdData_FF_WB, aluResult_MEM_FF, aluResult_FF_WB,
              wrData_WB_ID, reg1_ID_FF, reg1_FF_EX, reg2_ID_FF, reg2_FF_EX, reg2_EX_FF, reg2_FF_MEM,
							pc_FF_EX, pc_ID_FF, pc_EX_FF, pc_FF_MEM, pc_MEM_FF, pc_FF_WB, instr_FF_MEM, instr_EX_FF,
							instr_FF_MUX, instr_MUX_EX;

  wire [3:0]  wrReg_FF_EX, wrReg_ID_FF, wrReg_FF_MUX, wrReg_MUX_EX,
              wrReg_EX_FF, wrReg_FF_MEM, wrReg_MEM_FF, wrReg_FF_WB, aluOp_ID_FF, aluOp_FF_EX,
              shAmt_ID_FF, shAmt_FF_EX, rdReg1_ID_FF, rdReg1_FF_EX, rdReg2_ID_FF, rdReg2_FF_EX;

  wire [1:0] reg1hazSel, reg2hazSel;

  wire IF_ID_EN, ID_EX_EN, EX_MEM_EN, MEM_WB_EN, memRd_FF_EX, memRd_ID_FF, memWr_FF_EX, memWr_ID_FF,
        mem2reg_ID_FF, mem2reg_FF_EX, sawBr_ID_FF, sawBr_FF_EX, sawJ_ID_FF, sawJ_FF_EX, aluSrc_ID_FF,
        aluSrc_FF_EX, hlt_ID_FF, hlt_FF_EX, memRd_EX_FF, memRd_FF_MEM, memWr_EX_FF, mem2reg_EX_FF,
        sawBr_EX_FF, sawBr_FF_MEM, sawJ_EX_FF, hlt_EX_FF, mem2reg_MEM_FF, mem2reg_FF_WB, hlt_MEM_FF,
        wrRegEn_ID_FF, wrRegEn_FF_EX, wrRegEn_EX_FF, wrRegEn_FF_MEM, wrRegEn_MEM_FF, wrRegEn_FF_WB,
				rst_n_IF_ID, rst_n_ID_EX, PCSrc_FF_WB, rst_n_EX_MEM, rst_n_MEM_WB, hlt_FF_MEM, hlt_FF_WB,
				rdReg1En_ID, rdReg2En_ID, memRd_FF_MUX, memWr_FF_MUX, sawBr_FF_MUX, sawJ_FF_MUX, hlt_FF_MUX,
				wrRegEn_FF_MUX, PCSrc_MEM_IF, memRd_MUX_EX, memWr_MUX_EX, sawBr_MUX_EX, sawJ_MUX_EX, hlt_MUX_EX,
				wrRegEn_MUX_EX, LW_Stall_ID, LW_Stall_EX, sawStall;

	assign IF_ID_EN = ~(hlt | LW_Stall_ID | LW_Stall_EX);
	assign ID_EX_EN = ~(hlt_MUX_EX | LW_Stall_EX);
	assign EX_MEM_EN = ~hlt_FF_MEM;
	assign MEM_WB_EN = ~hlt;

	assign rst_n_IF_ID = rst_n & ~PCSrc_MEM_IF;
	assign rst_n_ID_EX = rst_n & ~PCSrc_MEM_IF;
	assign rst_n_EX_MEM = rst_n;
	assign rst_n_MEM_WB = rst_n;

	assign pc = pc_FF_WB + 1;

IF IF(
  .clk(clk),
  .hlt(hlt),
  .nRst(rst_n),
  .altAddress(targetAddr_FF_MEM),
  .useAlt(PCSrc_MEM_IF),
  .pc(pc_IF_FF),
  .instr(instr_IF_FF)
);

//////////////////////////////////////////////////  IF/ID flops ///////////////////////////////////////////////////////
dff_16 ff00(.q(pc_FF_ID), .d(pc_IF_FF), .en(IF_ID_EN), .rst_n(rst_n_IF_ID), .clk(clk));
dff_16 ff01(.q(instr_FF_ID), .d(instr_IF_FF), .en(IF_ID_EN), .rst_n(rst_n_IF_ID), .clk(clk));

ID ID(
  .i_clk(clk),
  .i_nRst(rst_n),
  .i_hlt(hlt),
  .i_instr(instr_FF_ID),
  .i_pc(pc_FF_ID),
  .i_wrReg(wrReg_FF_WB),
  .i_wrData(wrData_WB_ID),
  .i_wrEn(wrRegEn_FF_WB),
	.i_Z(flags_EX_FF[1]),
  .o_port0(reg1_ID_FF),
  .o_port1(reg2_ID_FF),
  .o_sext(sext_ID_FF),
  .o_instr(instr_ID_FF),
  .o_wrReg(wrReg_ID_FF),
  .o_memRd(memRd_ID_FF),
  .o_memWr(memWr_ID_FF),
  .o_aluOp(aluOp_ID_FF),
  .o_mem2reg(mem2reg_ID_FF),
  .o_sawBr(sawBr_ID_FF),
  .o_sawJ(sawJ_ID_FF),
  .o_aluSrc(aluSrc_ID_FF),
  .o_shAmt(shAmt_ID_FF),
  .o_rdReg1(rdReg1_ID_FF),
  .o_rdReg2(rdReg2_ID_FF),
  .o_hlt(hlt_ID_FF),
  .o_wrRegEn(wrRegEn_ID_FF),
	.o_rdReg1En(rdReg1En_ID),
	.o_rdReg2En(rdReg2En_ID)
);

hzdDet hzd(
	.reg1_fwdCtrl(reg1hazSel), 
	.reg2_fwdCtrl(reg2hazSel), 
	.rdReg1_ID(rdReg1_ID_FF), 
	.rdReg2_ID(rdReg2_ID_FF), 
	.wrReg_EX(wrReg_MUX_EX), 
	.wrReg_MEM(wrReg_FF_MEM), 
	.wrReg_WB(wrReg_FF_WB), 
	.rdEn1_ID(rdReg1En_ID), 
	.rdEn2_ID(rdReg2En_ID), 
	.wrEn_EX(wrRegEn_MUX_EX), 
	.wrEn_MEM(wrRegEn_FF_MEM), 
	.wrEn_WB(wrRegEn_FF_WB)
);

assign FWD_reg1 = (reg1hazSel == `NO_FWD) ? reg1_ID_FF :
									(reg1hazSel == `FWD_FROM_EX) ? aluResult_EX_FF :
									(reg1hazSel == `FWD_FROM_MEM) ? //aluResult_FF_MEM :
											(instr_FF_MEM[15:12] == `LW) ? rdData_MEM_FF : aluResult_FF_MEM :
									(reg1hazSel == `FWD_FROM_WB) ? wrData_WB_ID :
									reg1_ID_FF;
									
assign FWD_reg2 = (reg2hazSel == `NO_FWD) ? reg2_ID_FF :
									(reg2hazSel == `FWD_FROM_EX) ? aluResult_EX_FF :
									(reg2hazSel == `FWD_FROM_MEM) ? //aluResult_MEM_FF :
											(instr_FF_MEM[15:12] == `LW) ? rdData_MEM_FF : aluResult_FF_MEM :
									(reg2hazSel == `FWD_FROM_WB) ? wrData_WB_ID :
									reg2_ID_FF;

assign LW_Stall_ID = (((reg1hazSel == `FWD_FROM_EX) | (reg2hazSel == `FWD_FROM_EX)) & (instr_MUX_EX[15:12] == `LW)) & ~LW_Stall_EX;

/*
always @(*) begin
	$display("\n--------------------------------------------------------");
	$display("reg1hazSel: %h", reg1hazSel);
	$display("reg2hazSel: %h", reg2hazSel);
	$display("one: %b", (reg1hazSel == `FWD_FROM_EX));
	$display("two: %b", (reg2hazSel == `FWD_FROM_EX));
	$display("three: %b", ((reg1hazSel == `FWD_FROM_EX) | (reg2hazSel == `FWD_FROM_EX)));
	$display("four: %b", (instr_MUX_EX[15:12] == `LW));
	$display("sawStall: %b", sawStall);
	$display("lw_stall: %b", LW_Stall);
end
*/

/////////////////////////////////////////////// ID/EX passthrough /////////////////////////////////////////////////////
assign pc_ID_FF = pc_FF_ID;

//////////////////////////////////////////////////  ID/EX flops ///////////////////////////////////////////////////////
dff_16 ff02(.q(pc_FF_EX), .d(pc_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_16 ff03(.q(reg1_FF_EX), .d(FWD_reg1), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_16 ff04(.q(reg2_FF_EX), .d(FWD_reg2), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_16 ff05(.q(instr_FF_MUX), .d(instr_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_16 ff06(.q(sext_FF_EX), .d(sext_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_4  ff07(.q(wrReg_FF_MUX), .d(wrReg_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_4  ff08(.q(aluOp_FF_EX), .d(aluOp_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_4  ff09(.q(shAmt_FF_EX), .d(shAmt_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_4  ff10(.q(rdReg1_FF_EX), .d(rdReg1_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff_4  ff11(.q(rdReg2_FF_EX), .d(rdReg2_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff    ff12(.q(memRd_FF_MUX), .d(memRd_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff    ff13(.q(memWr_FF_MUX), .d(memWr_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff    ff14(.q(mem2reg_FF_EX), .d(mem2reg_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff    ff15(.q(sawBr_FF_MUX), .d(sawBr_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff    ff16(.q(sawJ_FF_MUX), .d(sawJ_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff    ff17(.q(aluSrc_FF_EX), .d(aluSrc_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff    ff18(.q(hlt_FF_MUX), .d(hlt_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff    ff19(.q(wrRegEn_FF_MUX), .d(wrRegEn_ID_FF), .en(ID_EX_EN), .rst_n(rst_n_ID_EX), .clk(clk));
dff		 ff51(.q(LW_Stall_EX), .d(LW_Stall_ID), .en(1'b1), .rst_n(rst_n_ID_EX), .clk(clk));

assign memRd_MUX_EX 	= (LW_Stall_EX == 1'b1) ? 1'b0 : memRd_FF_MUX;
assign memWr_MUX_EX 	= (LW_Stall_EX == 1'b1) ? 1'b0 : memWr_FF_MUX;
assign sawBr_MUX_EX 	= (LW_Stall_EX == 1'b1) ? 1'b0 : sawBr_FF_MUX;
assign sawJ_MUX_EX  	= (LW_Stall_EX == 1'b1) ? 1'b0 : sawJ_FF_MUX;
assign hlt_MUX_EX   	= (LW_Stall_EX == 1'b1) ? 1'b0 : hlt_FF_MUX;
assign wrRegEn_MUX_EX = (LW_Stall_EX == 1'b1) ? 1'b0 : wrRegEn_FF_MUX;
assign wrReg_MUX_EX		= (LW_Stall_EX == 1'b1) ? 4'h0 : wrReg_FF_MUX;
assign instr_MUX_EX		= (LW_Stall_EX == 1'b1) ? 16'd0: instr_FF_MUX;


EX EX(
  .pc(pc_FF_EX),
  .instr(instr_MUX_EX),
  .reg1(reg1_FF_EX),
  .reg2(reg2_FF_EX),
  .sextIn(sext_FF_EX),
  .aluSrc(aluSrc_FF_EX),
  .aluOp(aluOp_FF_EX),
  .shAmt(shAmt_FF_EX),
  .aluResult(aluResult_EX_FF),
  .flags(flags_EX_FF),
  .targetAddr(targetAddr_EX_FF)
);

////////////////////////////////////////////// EX/MEM passthrough /////////////////////////////////////////////////////
assign wrReg_EX_FF = wrReg_MUX_EX;
assign memRd_EX_FF = memRd_MUX_EX;
assign memWr_EX_FF = memWr_MUX_EX;
assign mem2reg_EX_FF = mem2reg_FF_EX;
assign sawBr_EX_FF = sawBr_MUX_EX;
assign sawJ_EX_FF = sawJ_MUX_EX;
assign hlt_EX_FF = hlt_MUX_EX;
assign wrRegEn_EX_FF = wrRegEn_MUX_EX;
assign reg2_EX_FF = reg2_FF_EX;
assign branchOp_EX_FF = instr_FF_EX[11:9];
assign pc_EX_FF = pc_FF_EX;
assign instr_EX_FF = instr_MUX_EX;

////////////////////////////////////////////////// EX/MEM flops ///////////////////////////////////////////////////////
dff_16 ff20(.q(aluResult_FF_MEM), .d(aluResult_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff_16 ff21(.q(targetAddr_FF_MEM), .d(targetAddr_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff_16 ff22(.q(reg2_FF_MEM), .d(reg2_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff_16 ff39(.q(pc_FF_MEM), .d(pc_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff_16 ff42(.q(instr_FF_MEM), .d(instr_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff_4  ff23(.q(wrReg_FF_MEM), .d(wrReg_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff_3  ff24(.q(flags_FF_MEM), .d(flags_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff_3  ff25(.q(branchOp_FF_MEM), .d(branchOp_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff    ff26(.q(memRd_FF_MEM), .d(memRd_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff    ff27(.q(memWr_FF_MEM), .d(memWr_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff    ff28(.q(mem2reg_FF_MEM), .d(mem2reg_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff    ff29(.q(sawBr_FF_MEM), .d(sawBr_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff    ff30(.q(sawJ_FF_MEM), .d(sawJ_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff    ff31(.q(hlt_FF_MEM), .d(hlt_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
dff    ff32(.q(wrRegEn_FF_MEM), .d(wrRegEn_EX_FF), .en(EX_MEM_EN), .rst_n(rst_n_EX_MEM), .clk(clk));
//dff		 ff50(.q(sawStall), .d(LW_Stall), .en(1'b1), .rst_n(rst_n_EX_MEM), .clk(clk));


MEM MEM(
  .clk(clk),
  .memAddr(aluResult_FF_MEM),
  .flags(flags_FF_MEM),
  .wrData(reg2_FF_MEM),
  .memWr(memWr_FF_MEM),
  .memRd(memRd_FF_MEM),
  .branchOp(branchOp_FF_MEM),
  .sawBr(sawBr_FF_MEM),
  .sawJ(sawJ_FF_MEM),
  .rdData(rdData_MEM_FF),
  .PCSrc(PCSrc_MEM_IF)
);

////////////////////////////////////////////// MEM/WB passthrough /////////////////////////////////////////////////////
assign wrReg_MEM_FF = wrReg_FF_MEM;
assign aluResult_MEM_FF = aluResult_FF_MEM;
assign mem2reg_MEM_FF = mem2reg_FF_MEM;
assign hlt_MEM_FF = hlt_FF_MEM;
assign wrRegEn_MEM_FF = wrRegEn_FF_MEM;
assign pc_MEM_FF = pc_FF_MEM;
assign PCSrc_MEM_FF = PCSrc_MEM_IF;

////////////////////////////////////////////////// MEM/WB flops ///////////////////////////////////////////////////////
dff_16 ff33(.q(rdData_FF_WB), .d(rdData_MEM_FF), .en(MEM_WB_EN), .rst_n(rst_n_MEM_WB), .clk(clk));
dff_16 ff34(.q(aluResult_FF_WB), .d(aluResult_MEM_FF), .en(MEM_WB_EN), .rst_n(rst_n_MEM_WB), .clk(clk));
dff_16 ff40(.q(pc_FF_WB), .d(pc_MEM_FF), .en(MEM_WB_EN), .rst_n(rst_n_MEM_WB), .clk(clk));
dff_4  ff35(.q(wrReg_FF_WB), .d(wrReg_MEM_FF), .en(MEM_WB_EN), .rst_n(rst_n_MEM_WB), .clk(clk));
dff    ff36(.q(mem2reg_FF_WB), .d(mem2reg_MEM_FF), .en(MEM_WB_EN), .rst_n(rst_n_MEM_WB), .clk(clk));
dff    ff37(.q(hlt), .d(hlt_MEM_FF), .en(MEM_WB_EN), .rst_n(rst_n_MEM_WB), .clk(clk));
dff    ff38(.q(wrRegEn_FF_WB), .d(wrRegEn_MEM_FF), .en(MEM_WB_EN), .rst_n(rst_n_MEM_WB), .clk(clk));
dff    ff41(.q(PCSrc_FF_WB), .d(PCSrc_MEM_FF), .en(MEM_WB_EN), .rst_n(rst_n_MEM_WB), .clk(clk));

WB WB(
  .memData(rdData_FF_WB),
  .aluResult(aluResult_FF_WB),
  .mem2reg(mem2reg_FF_WB),
  .wrData(wrData_WB_ID), 
	.pc(pc_FF_WB),
	.PCSrc(PCSrc_FF_WB)
);

endmodule
