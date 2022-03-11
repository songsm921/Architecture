`include "alu_func.v"
module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C,
    output reg OverflowFlag
	);
// Do not use delay in your implementation.
// Classification 
/*
1. control overflow -> A+B(0000), A-B(0001) <0,1>
2. input is only A -> 0010, 0011, 1010, 1011, 1100, 1101, 1110, 1111(exceptional) <2,3,10,11,12,13,14,15>
3. inputs are A & B and not overflow -> else <4,5,6,7,8,9>
*/
// You can declare any variables as needed.
/*
	YOUR VARIABLE DECLARATION...
*/
	wire overflow;
	wire [data_width-1:0] OP1;
	wire [data_width -1 : 0] OP2;
	wire [data_width - 1 : 0] OP3;
	ALU_OP1 #(.data_width(16)) op1(.A(A), .B(B), .FuncCode(FuncCode), .C(OP1), .OverflowFlag(overflow));
	ALU_OP2 #(.data_width(16)) op2(.A(A), .FuncCode(FuncCode), .C(OP2));
	ALU_OP3 #(.data_width(16)) op3(.A(A), .B(B), .FuncCode(FuncCode), .C(OP3));
	initial begin
		C = 0;
		OverflowFlag = 0;
	end   	

	always @(*) begin
		if(FuncCode >=0 && FuncCode <=1) begin
			C <= OP1;
			OverflowFlag <= overflow;
		end
		else if(FuncCode>= 2 && FuncCode <=3) begin
			C<= OP2;
		end
		else if(FuncCode >= 10 && FuncCode <=15) begin
			C<=OP2;
		end
		else begin
			C<= OP3;
		end
	end
// TODO: You should implement the functionality of ALU!
// (HINT: Use 'always @(...) begin ... end')
/*
	YOUR ALU FUNCTIONALITY IMPLEMENTATION...
*/

endmodule

module ALU_OP1 #(parameter data_width = 16)
(
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C,
	output reg OverflowFlag
);
	always @(*) begin
		case(FuncCode)
			`FUNC_ADD : begin
				C <= A+B;
				if((A[data_width - 1] == B[data_width - 1]) && (A[data_width - 1] != C[data_width - 1]))
					OverflowFlag <=1;
				else
					OverflowFlag <= 0;
			end
			`FUNC_SUB : begin
				C <= A-B;
				if((A[data_width-1] == 0 && B[data_width-1] == 1 && C[data_width-1] == 1) || (A[data_width-1] == 1 && B[data_width-1] == 0 && C[data_width-1] == 0))
					OverflowFlag <=1;
				else
					OverflowFlag <= 0;
			end
			default : C<=0;
		endcase
	end
endmodule

module ALU_OP2 #(parameter data_width = 16) //2. input is only A -> 0010, 0011, 1010, 1011, 1100, 1101, 1110, 1111(exceptional) <2,3,10,11,12,13,14,15>
(
	input [data_width - 1 : 0] A,  
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C
);
	always @(*) begin
		case(FuncCode)
			`FUNC_ID: 
				C<=A;
			`FUNC_NOT:
				C<=~A;
			`FUNC_LLS:
				C <= A << 1;
			`FUNC_LRS:
				C <= A >> 1;
			`FUNC_ALS:
				C <= A <<< 1;
			`FUNC_ARS: begin
				C <= A >>> 1;
				if(A[data_width - 1] == 1) C[data_width - 1] <= 1; // Arithmetic right shift : Copy own sign bit.
			end
			`FUNC_TCP: 
				C <= ~A + 1;
			`FUNC_ZERO: 
				C<=0;
			default: C<=0;
		endcase


	end

endmodule

module ALU_OP3 #(parameter data_width = 16) //<4,5,6,7,8,9>
(
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C
);
	always @(*) begin
		case(FuncCode)
			`FUNC_AND: 
				C<= A & B;
			`FUNC_OR:
				C<= A | B;
			`FUNC_NAND:
				C <= ~(A & B);
			`FUNC_NOR:
				C <= ~(A | B);
			`FUNC_XOR:
				C <= A ^ B;
			`FUNC_XNOR:
				C <= ~(A ^ B);
			default: C<=0;
		endcase
	end
endmodule