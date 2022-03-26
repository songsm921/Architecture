// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required
`include "opcodes.v"
`include "PC.v"
`include "RegisterFile.v"
`include "Memory.v"
`include "ALU.v"
`include "ControlUnit.v"
module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [`word_size -1 : 0] current_pc;
  wire [`word_size - 1: 0] inst;
  wire write_enable;
  reg [6:0] opcode;
  reg [4:0] rs1,rs2,rd;
  reg [2:0] funct3;
  reg [6:0] funct7;
  wire signed [`word_size - 1: 0] rs1_dout,rs2_dout;
  reg signed [`word_size - 1: 0] alu_in_1,alu_in_2;
  wire signed [`word_size - 1: 0] alu_result;
  reg signed [`word_size - 1: 0] immediate;
  wire is_jal,is_jalr,branch,mem_read,mem_to_reg,mem_write,alu_src,pc_to_reg;
  wire is_ecall;
  wire [3:0] alu_op;
  wire alu_bcond;
  reg [`word_size-1:0] addr;
  wire [`word_size-1:0] memorydata;
  reg [`word_size-1:0] final_data;
  /***** Register declarations *****/
  reg [`word_size - 1: 0] next_pc;
  reg [`word_size - 1: 0] regdata;
  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(inst)     // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (rs2),          // input
    .rd (rd),           // input
    .rd_din (regdata),       // input
    .write_enable (write_enable),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(opcode),  // input
    .is_jal(is_jal),        // output
    .is_jalr(is_jalr),       // output
    .branch(branch),        // output
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),     // output
    .pc_to_reg(pc_to_reg),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  //ImmediateGenerator imm_gen(
    //.part_of_inst(),  // input
   // .imm_gen_out()    // output
  //);

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(inst),  // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (addr),       // input
    .din (rs2_dout),        // input
    .mem_read (mem_read),   // input
    .mem_write (mem_write),  // input
    .dout (memorydata)        // output
  );
  assign is_halted = (is_ecall && rs1_dout == `ECODE) ? 1 : 0;
  always @(*) begin
    opcode = inst[6:0];
    case(opcode)
      `ARITHMETIC: begin
        rd = inst[11:7];
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        funct7 = inst[31:25];
      end
      `ARITHMETIC_IMM: begin
        rd = inst[11:7];
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        immediate = {{20{inst[31]}},inst[31:20]};
      end
      `LOAD: begin
        rd = inst[11:7];
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        immediate = {{20{inst[31]}},inst[31:20]};
      end
      `STORE: begin
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        immediate = {{20{inst[31]}},inst[31:25],inst[11:7]};
      end
      `BRANCH: begin
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        immediate = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
        end
        `JAL: begin
          rd = inst[11:7];
          immediate = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
        end
        `JALR: begin
          rd = inst[11:7];
          funct3 = inst[14:12];
          rs1 = inst[19:15];
          immediate = {{20{inst[31]}},inst[31:20]};
        end
        `ECALL: begin
          rs1 = 5'b10001;
        end
    endcase
    alu_in_1 = rs1_dout;
    if(alu_src)
      alu_in_2 = immediate;
    else
      alu_in_2 = rs2_dout;
    if(mem_read || mem_write)
      addr = alu_result;
    if(mem_to_reg)
      final_data = memorydata;
    else
      final_data = alu_result;
    if(pc_to_reg)
      regdata = current_pc + 4;
    else
      regdata = final_data;

    ///
    if(is_jalr)
      next_pc = alu_result & 32'hFFFFFFFE;
    else begin
      if(is_jal || (branch && alu_bcond))
        next_pc = immediate + current_pc;
      else
        next_pc = current_pc + 4;
    end

      
  end
endmodule
