`include "opcodes.v"

module BP(input reset, input clk, input [31:0]PC, input [4:0]target_idx, input [24:0]target_tag,input [31:0]actual_PC, input isBJ, input correct, input correct2, input [31:0]ID_EX_pred_pc,
 output reg [31:0] predict_PC, output reg istaken); // isBJ -> branch or JAL
    reg [59:0]BTB[0:31]; // 59 valid bit / tag = (58,34) / taken (33,32) / pc (31,0)
    //integer i;
    always @(*) begin
            if((PC[31:7] == BTB[PC[6:2]][58:34]) && (BTB[PC[6:2]][33:32] == 2'b10 || BTB[PC[6:2]][33:32] == 2'b11)&&(BTB[PC[6:2]][59] == 1)) begin
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
           BTB[0][59:0] <= 0;
            BTB[1][59:0] <= 0;
            BTB[2][59:0] <= 0;
            BTB[3][59:0] <= 0;
            BTB[4][59:0] <= 0;
            BTB[5][59:0] <= 0;
            BTB[6][59:0] <= 0;
            BTB[7][59:0] <= 0;
            BTB[8][59:0] <= 0;
            BTB[9][59:0] <= 0;
            BTB[10][59:0] <= 0;
            BTB[11][59:0] <= 0;
            BTB[12][59:0] <= 0;
            BTB[13][59:0] <= 0;
            BTB[14][59:0] <= 0;
            BTB[15][59:0] <= 0;
            BTB[16][59:0] <= 0;
            BTB[17][59:0] <= 0;
            BTB[18][59:0] <= 0;
            BTB[19][59:0] <= 0;
            BTB[20][59:0] <= 0;
            BTB[21][59:0] <= 0;
            BTB[22][59:0] <= 0;
            BTB[23][59:0] <= 0;
            BTB[24][59:0] <= 0;
            BTB[25][59:0] <= 0;
            BTB[26][59:0] <= 0;
            BTB[27][59:0] <= 0;
            BTB[28][59:0] <= 0;
            BTB[29][59:0] <= 0;
            BTB[30][59:0] <= 0;
            BTB[31][59:0] <= 0;
        end
        else begin
            if(isBJ)begin
                BTB[target_idx][59] <= 1; // valid bit
                BTB[target_idx][58:34] <= target_tag;
                if(!correct || !correct2)
                    BTB[target_idx][31:0] <= actual_PC;
                else
                    BTB[target_idx][31:0] <= ID_EX_pred_pc;
                case(BTB[target_idx][33:32])
                    2'b00: begin
                        if(correct) BTB[target_idx][33:32] <= 2'b00;
                        else BTB[target_idx][33:32] <= 2'b01;
                    end
                    2'b01: begin
                        if(correct) BTB[target_idx][33:32] <= 2'b00;
                        else BTB[target_idx][33:32] <= 2'b10;
                    end
                    2'b10: begin
                        if(correct) BTB[target_idx][33:32] <= 2'b11;
                        else BTB[target_idx][33:32] <= 2'b01;
                    end
                    2'b11: begin
                        if(correct) BTB[target_idx][33:32] <= 2'b11;
                        else BTB[target_idx][33:32] <= 2'b10;
                    end
                endcase
            end
        end
    end
endmodule
