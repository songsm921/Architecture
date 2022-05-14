`include "opcodes.v"
module ControlUnit(input [6:0]part_of_inst, input isStall,input correct,input correct2, output reg mem_read, output reg mem_to_reg, 
output reg mem_write, output reg alu_src, output reg write_enable,output reg pc_to_reg, output reg [6:0]alu_op, output reg is_ecall,
 output reg is_branch, output reg is_jal, output reg is_jalr);
    always @(*) begin
      if(isStall || !correct || !correct2) begin
        mem_read = 0; mem_to_reg = 0; mem_write = 0; write_enable = 0; alu_op = 7'b0110111; is_ecall = 0;
        pc_to_reg = 0; is_branch = 0; is_jal = 0; is_jalr = 0;
      end
      else begin
        mem_read = part_of_inst == `LOAD;
        mem_to_reg = part_of_inst == `LOAD;
        mem_write = part_of_inst == `STORE;
        alu_src = ((part_of_inst != `ARITHMETIC) && (part_of_inst != `BRANCH));
        write_enable = ((part_of_inst != `STORE) && (part_of_inst != `BRANCH) && (part_of_inst != `ECALL));
        pc_to_reg = (part_of_inst == `JAL || part_of_inst == `JALR);
        is_ecall = part_of_inst == `ECALL;
        is_branch = part_of_inst == `BRANCH;
        is_jal = part_of_inst == `JAL;
        is_jalr = part_of_inst == `JALR;
        case(part_of_inst[6:0])
          `ARITHMETIC: alu_op = `ARITHMETIC;
          `ARITHMETIC_IMM : alu_op = `ARITHMETIC_IMM;
          `LOAD : alu_op = `LOAD;
          `STORE : alu_op = `STORE;
          `BRANCH : alu_op = `BRANCH;
          `JAL: alu_op = `JAL;
          `JALR : alu_op = `JALR;
        //`ECALL: alu_op = `ECALL;
        endcase
      end
    end
endmodule