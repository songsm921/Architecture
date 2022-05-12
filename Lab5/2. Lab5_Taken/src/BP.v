`include "opcodes.v"
module BP(input reset, input clk, input [31:0]pc, input [31:0] updatedPC, input [31:0]actualPC, input notMatch, input notMatch2, output reg[31:0] pred_pc);
    reg [57:0]BTB[0:31];
    always @(posedge clk) begin
        if(reset) begin
            BTB[0][57:0] <= 0;
            BTB[1][57:0] <= 0;
            BTB[2][57:0] <= 0;
            BTB[3][57:0] <= 0;
            BTB[4][57:0] <= 0;
            BTB[5][57:0] <= 0;
            BTB[6][57:0] <= 0;
            BTB[7][57:0] <= 0;
            BTB[8][57:0] <= 0;
            BTB[9][57:0] <= 0;
            BTB[10][57:0] <= 0;
            BTB[11][57:0] <= 0;
            BTB[12][57:0] <= 0;
            BTB[13][57:0] <= 0;
            BTB[14][57:0] <= 0;
            BTB[15][57:0] <= 0;
            BTB[16][57:0] <= 0;
            BTB[17][57:0] <= 0;
            BTB[18][57:0] <= 0;
            BTB[19][57:0] <= 0;
            BTB[20][57:0] <= 0;
            BTB[21][57:0] <= 0;
            BTB[22][57:0] <= 0;
            BTB[23][57:0] <= 0;
            BTB[24][57:0] <= 0;
            BTB[25][57:0] <= 0;
            BTB[26][57:0] <= 0;
            BTB[27][57:0] <= 0;
            BTB[28][57:0] <= 0;
            BTB[29][57:0] <= 0;
            BTB[30][57:0] <= 0;
            BTB[31][57:0] <= 0;
        end // intialization
        else begin
            if(notMatch || notMatch2) begin //jalr...?
                BTB[updatedPC[6:2]][57] <= 1; //valid bit
                BTB[updatedPC[6:2]][56:32] <= updatedPC[31:7];
                BTB[updatedPC[6:2]][31:0] <= actualPC;
            end
        end
    end
    always @(*) begin
        if((BTB[pc[6:2]][56:32] == pc[31:7])&& BTB[pc[6:2]][57] == 1) begin //
            pred_pc = BTB[pc[6:2]][31:0];
        end
        else
            pred_pc = pc + 4;
    end
endmodule