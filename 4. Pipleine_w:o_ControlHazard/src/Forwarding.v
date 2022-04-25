`include "opcodes.v"
module Forwarding(input [4:0]ID_EX_rs1_num, input [4:0]ID_EX_rs2_num, input [4:0] EX_MEM_rd, input [4:0] MEM_WB_rd, 
input EX_MEM_reg_write, input MEM_WB_reg_write, output reg [1:0]Forward_A, output reg [1:0]Forward_B);
    always @(*) begin
        if(ID_EX_rs1_num!=0 && (ID_EX_rs1_num == EX_MEM_rd) && EX_MEM_reg_write)
            Forward_A = 2'b10;
        else if((ID_EX_rs1_num!=0) && (ID_EX_rs1_num == MEM_WB_rd) && MEM_WB_reg_write)
            Forward_A = 2'b01;
        else
            Forward_A = 0;
        if(ID_EX_rs2_num!=0 && (ID_EX_rs2_num == EX_MEM_rd) && EX_MEM_reg_write)
            Forward_B = 2'b10;
        else if((ID_EX_rs2_num!=0) && (ID_EX_rs2_num == MEM_WB_rd) && MEM_WB_reg_write)
            Forward_B = 2'b01;
        else
            Forward_B = 0;
    end
endmodule

module InternalForwarding(input [4:0]rs1, input [4:0]rs2, input [4:0] MEM_WB_rd,input MEM_WB_reg_write,
 output reg inter_forward_A, output reg inter_forward_B);
    always @(*) begin
        if((rs1!=0)&& (rs1 == MEM_WB_rd) && MEM_WB_reg_write ) // caution! add / / / sw case 
            inter_forward_A = 1;
        else
            inter_forward_A = 0;
        if((rs2!=0)&& (rs2 == MEM_WB_rd) && MEM_WB_reg_write )
            inter_forward_B = 1;
        else
            inter_forward_B = 0;
    end
endmodule