`include "opcodes.v"

module BP(input reset, input clk, input [31:0]PC, input [4:0]target_idx, input [24:0]target_tag,input [31:0]actual_PC, input isBJ, input isBranch,
input correct, input correct2, input [31:0]ID_EX_pred_pc,
 output reg [31:0] predict_PC, output reg istaken); // isBJ -> branch or JAL
    reg [57:0]BTB[0:31]; // 59 valid bit / tag = (58,34) / taken (33,32) / pc (31,0)
    reg [1:0]counter;
    integer i;
    always @(*) begin
            if((PC[31:7] == BTB[PC[6:2]][56:32]) && (counter == 2'b10 || counter == 2'b11)&&(BTB[PC[6:2]][57] == 1)) begin
                predict_PC = BTB[PC[6:2]][31:0];
                istaken = 1;
            end
            else begin
                predict_PC = PC + 4;
                istaken = 0;
            end

    end
    always @(posedge clk) begin
        if(reset) begin
            counter <= 0;
            for(i = 0 ; i<32 ;i = i+1)
                BTB[i][57:0] <= 0;
        end
        else begin
            if(isBJ)begin
                BTB[target_idx][57] <= 1; // valid bit
                BTB[target_idx][56:32] <= target_tag;
                if(!correct || !correct2)
                    BTB[target_idx][31:0] <= actual_PC;
                else
                    BTB[target_idx][31:0] <= ID_EX_pred_pc;
                    case(counter)
                        2'b00: begin
                            if(correct) counter <= 2'b00;
                            else counter <= 2'b01;
                        end
                        2'b01: begin
                            if(correct) counter <= 2'b00;
                            else counter <= 2'b10;
                        end
                        2'b10: begin
                            if(correct) counter <= 2'b11;
                            else counter <= 2'b01;
                        end
                        2'b11: begin
                            if(correct) counter <= 2'b11;
                            else counter <= 2'b10;
                        end
                    endcase
            end
        end
    end
endmodule
