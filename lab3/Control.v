`include "opcodes.v"

  //control bit ->Memtoreg, memwrite,memread,IorD, pcwrite, pcwritenotcond, pc_src, [6:0]alu_op_type,[1:0]alusrcB, write_enable(reg)
  ///A_write, B_write, ALUOut_write, ir_write, mdr_write
  // mem_to_reg = ALUOUT or MDR
  module ControlUnit(input clk, input reset, input [6:0] part_of_inst,input bcond_branch,output reg mem_to_reg, output reg mem_write, output reg mem_read, output reg IorD,
  output reg pc_write, output reg pc_src, output reg pc_writenotcond, output reg ir_write, output reg mdr_write, output reg write_enable,
  output reg A_write, output reg B_write, output reg ALUOut_write, output reg alu_src_A, output reg [1:0] alu_src_B,
  output reg [6:0] alu_op_type,output reg is_ecall, output reg bcond_write);
    reg [2:0] state, next_state;
    always @(posedge clk) begin
      if(reset)
        state <= 3'b000;
      else
        state <= next_state;
    end
    always @(*) begin
      case(state)
        `IF: begin
          mem_to_reg = 0 ; mem_write = 0; mem_read = 1; IorD = 0; pc_write = 0; pc_writenotcond = 0; ir_write = 1; mdr_write = 0; write_enable = 0;
          A_write = 0; B_write = 0; ALUOut_write = 0; is_ecall = 0; bcond_write = 0;
          next_state = `ID;
        end
        `ID: begin
          if(part_of_inst != `JAL) begin
          mem_to_reg = 0 ; mem_write = 0; mem_read = 0; IorD = 0; pc_write = 0; pc_writenotcond = 0; ir_write = 0; mdr_write = 0; write_enable = 0;
          A_write = 1; B_write = 1; ALUOut_write = 0; is_ecall = 0; bcond_write = 0;
          end
          if(part_of_inst == `BRANCH) begin
            alu_src_A = 0;
            alu_src_B = 2'b10;
            alu_op_type = `TEMP;
            ALUOut_write = 1;
          end
          if(part_of_inst == `ECALL) begin
            A_write = 1;
            B_write = 0;
          end
          next_state = `EXE;
        end
        `EXE: begin
          is_ecall = 0; pc_write = 0; pc_writenotcond = 0; ir_write = 0; mdr_write = 0;
          A_write = 0; B_write = 0; mem_read = 0; mem_write = 0; write_enable = 0; bcond_write = 0;
          IorD = 0;
          case(part_of_inst)
            `ARITHMETIC: begin
              alu_src_A = 1;
              alu_src_B = 0;
              ALUOut_write = 1;
              alu_op_type = `ARITHMETIC;
              next_state = `WB;
            end
            `ARITHMETIC_IMM: begin
              alu_src_A = 1;
              alu_src_B = 2'b10;
              ALUOut_write = 1;
              alu_op_type = `ARITHMETIC_IMM;
              next_state = `WB;
            end
            `LOAD: begin
              alu_src_A = 1;
              alu_src_B = 2'b10;
              ALUOut_write = 1;
              alu_op_type = `LOAD;
              next_state = `MEM;
            end
            `STORE: begin
              alu_src_A = 1;
              alu_src_B = 2'b10;
              ALUOut_write = 1;
              alu_op_type = `STORE;
              next_state = `MEM;
            end
            `JAL,`JALR: begin
              alu_src_A = 0;
              alu_src_B = 2'b01;
              alu_op_type = `TEMP;
              ALUOut_write = 1;
              next_state = `WB;
            end
            `BRANCH: begin
              alu_src_A = 1;
              alu_src_B = 2'b00;
              alu_op_type = `BRANCH;
              bcond_write = 1;
              ALUOut_write = 0;
              next_state = `PCUpdate;
            end
            `ECALL: begin
              alu_src_A = 1;
              alu_src_B = 2'b11;
              alu_op_type = `ECALL;
              bcond_write = 1;
              ALUOut_write = 0;
              next_state = `PCUpdate;
            end
          endcase
        end
        `MEM: begin 
          is_ecall = 0; pc_write = 0; pc_writenotcond = 0; ir_write =0;
          A_write = 0; B_write = 0; IorD = 1; ALUOut_write = 0; write_enable = 0; bcond_write = 0;
          case(part_of_inst)
          `LOAD: begin 
              mdr_write = 1;
              mem_read = 1;
              next_state = `WB;
          end
          `STORE: begin
            mem_write = 1;
            mdr_write =0;
            next_state = `PCUpdate;
          end
          endcase
        end
        `WB: begin
          is_ecall = 0; pc_write = 0; pc_writenotcond = 0; ir_write =0; mdr_write = 0;
          A_write = 0; B_write = 0; IorD = 0; ALUOut_write = 0; mem_read = 0; mem_write = 0; bcond_write = 0;
          write_enable = 1;
          case(part_of_inst)
          `ARITHMETIC,`ARITHMETIC_IMM,`JAL,`JALR: begin
            mem_to_reg = 0;
          end
          `LOAD: begin
            mem_to_reg = 1;
          end
          endcase
          next_state =`PCUpdate;
        end
        `PCUpdate: begin
          ir_write = 0; mdr_write = 0;
          A_write = 0; B_write = 0; IorD =0; mem_read = 0; mem_write = 0;
          write_enable = 0; bcond_write = 0;
          case(part_of_inst)
            `ARITHMETIC,`ARITHMETIC_IMM,`LOAD,`STORE: begin
              alu_src_A = 0;
              alu_src_B = 2'b01;
              alu_op_type = `TEMP;
              ALUOut_write = 0;
              pc_src = 0;
              pc_writenotcond = 0;
              pc_write = 1;
              next_state = `IF;
            end
            `JAL: begin
              alu_src_A = 0;
              alu_src_B = 2'b10;
              alu_op_type = `TEMP;
              ALUOut_write = 0;
              pc_src = 0;
              pc_writenotcond = 0;
              pc_write = 1;
              next_state = `IF;
            end
            `JALR: begin
              alu_src_A = 1;
              alu_src_B = 2'b10;
              alu_op_type = `TEMP;
              ALUOut_write = 0;
              pc_src = 0;
              pc_writenotcond = 0;
              pc_write = 1;
              next_state = `IF;
            end
            `BRANCH: begin 
              alu_src_A = 0;
              alu_src_B = 2'b01; // pc+4
              alu_op_type = `TEMP;
              ALUOut_write = 0;
              if(bcond_branch) begin
                pc_src = 1;
                pc_writenotcond = 0;
              end
              else begin
                pc_src = 0;
                pc_writenotcond = 1;
              end
              pc_write = 1;
              next_state = `IF;
            end
            `ECALL: begin
              alu_src_A = 0;
              alu_src_B = 2'b01;
              alu_op_type = `TEMP;
              ALUOut_write = 0;
              if(bcond_branch == 0) begin
                pc_src = 0;
                pc_writenotcond = 1;
                pc_write = 1;
                next_state = `IF;
              end
              else
                is_ecall = 1;
            end
          endcase

        end











      endcase
    end
  endmodule