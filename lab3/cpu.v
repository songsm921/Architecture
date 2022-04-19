// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required
`include "opcodes.v"
`include "RegisterFile.v"
`include "Memory.v"
`include "ALU.v"
`include "Immediate.v"
module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire alu_bcond, mem_to_reg, mem_write, mem_read, IorD, pc_write, pc_src, pc_writenotcond, ir_write, mdr_write, write_enable;
  wire A_write, B_write, ALUOut_write,alu_src_A;
  wire bcond_write;
  wire [1:0] alu_src_B;
  wire [6:0] alu_op_type;
  wire is_ecall;
  wire [6:0] opcode;
  reg [4:0] rs1;
  wire [5:0] rs2;
  wire [5:0] rd;
  wire [31:0] immediate;
  wire [3:0] alu_op;
  reg [31:0] in_1;
  reg [31:0] in_2;
  wire [31:0] rs1_dout,rs2_dout; 
  wire [31:0] alu_result; 
  reg [31:0] addr;
  wire [31:0] dout;
  reg [31:0] rd_din;
  reg bcond_branch;
  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  reg [31:0] next_pc;
  wire [31:0] current_pc;

  // Do not modify and use registers declared above.

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),
    .pc_write(pc_write),
    .pc_writenotcond(pc_writenotcond),
    .alu_bcond(alu_bcond),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(rs1),          // input
    .rs2(IR[24:20]),          // input
    .rd(IR[11:7]),           // input
    .rd_din(rd_din),       // input
    .write_enable(write_enable),    // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout)      // output
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(addr),         // input
    .din(B),          // input caution here! B right?
    .mem_read(mem_read),     // input
    .mem_write(mem_write),    // input
    .dout(dout)          // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .clk(clk),
    .reset(reset),
    .part_of_inst(IR[6:0]),
    .bcond_branch(bcond_branch),
    .mem_to_reg(mem_to_reg),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .IorD(IorD),
    .pc_write(pc_write),
    .pc_src(pc_src),
    .pc_writenotcond(pc_writenotcond),
    .ir_write(ir_write),
    .mdr_write(mdr_write),
    .write_enable(write_enable), // regwrite,
    .A_write(A_write),
    .B_write(B_write),
    .ALUOut_write(ALUOut_write),
    .alu_src_A(alu_src_A),
    .alu_src_B(alu_src_B),
    .alu_op_type(alu_op_type),
    .is_ecall(is_ecall),
    .bcond_write(bcond_write)      
  );
  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .inst(IR),  // input
    .immediate(immediate)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst(alu_op_type),
    .inst(IR),  // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(alu_op),      // input
    .alu_in_1(in_1),    // input  
    .alu_in_2(in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );
  
  assign is_halted = is_ecall;
  always @(*) begin
    if(IR[6:0] == `ECALL) 
      rs1 = 17;
    else
      rs1 = IR[19:15];
    if(alu_src_A == 0)
      in_1 = current_pc;
    else
      in_1 = A;
    if(alu_src_B == 2'b00)
      in_2 = B;
    else if(alu_src_B == 2'b01)
      in_2 = 4;
    else if(alu_src_B == 2'b10)
      in_2 = immediate;
    else
      in_2 = 10;
    if(IorD == 0)
      addr = current_pc;
    else
      addr = ALUOut;
    if(mem_to_reg == 0)   
      rd_din = ALUOut;
    else 
      rd_din = MDR;
    if(pc_src == 0)
      next_pc = alu_result;
    else
      next_pc = ALUOut;

  end
  always @(posedge clk) begin
    if(reset)begin
      IR <=0;
      MDR <=0;
      A <= 0;
      B <= 0;
      ALUOut <= 0;
    end
    else begin
      if(A_write) A <= rs1_dout;
      if(B_write) B <= rs2_dout;
      if(ALUOut_write) ALUOut <= alu_result;
      if(bcond_write) bcond_branch <= alu_bcond;
      if(ir_write) IR <= dout;
      if(mdr_write) MDR <= dout;
    end
  end
endmodule
