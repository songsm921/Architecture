# 2022 Computer Architecture Lab 2
#### 20180085 컴퓨터공학과 송수민
## I. Introduction
    Lab 2에서는 Single - cycle CPU를 구현한다. Single cycle CPU는 한 cycle에 instruction의 5개의 stage를 instruction의 종류와 상관없이 실행한다. 예를 들어, RISC - V의 R-type instruction은 instruction fetch, decoding, execution, write-back만을 필요로 한다. 이는 memory에 접근 할 필요가 없다는 것이다. 반면, load와 같은 경우 memory stage가 필요하다. Memory에 접근하는 process는 Register process에 비해 매우 느리기 때문에 이 방법은 성능면으로 보아서는 비효율적이다. 하지만, 모든 instruction이 한 cycle에서 실행된다는 점은 구현에서 보았을 때 매우 간편하고, 가시적일 것이다. 
## II. Design
    Design은 Lecture Note 5(page 34)를 토대로 하였다. 
![design](./Design.png)
## III. Implementation
    다음은 구현 방법이다. CPU를 일종의 top-level module로 사용하였고, 나머지 module을 설명하고 Top을 마지막에 설명하고자 한다.
    
- 1. PC <br>
 ```verilog    
 module PC(input reset, input clk, input [`word_size-1:0] next_pc, output reg [`word_size - 1: 0] current_pc);
    always @(posedge clk) begin
        if(reset)
            current_pc <= `word_size'd0;
        else
            current_pc <= next_pc; 
    end 
endmodule
```
> PC는 clock이 posedge일 때 synchronously update하도록 구현하였다. 구현 할 때 한 Cycle을 posedge - posedge로 생각하고 구현하였기 때문에, pc update는 한 Cycle의 시작 부분에서 실행되어야 한다. 따라서, reset이 1이면 output을 0으로 초기화하고, reset이 0이라면 다른 모듈에서 구한 next_pc를 current_pc로 update하였다. 
- 2. RegisterFile
```verilog
module RegisterFile
    ...
  // TODO
  // Asynchronously read register file
  // Synchronously write data to the register file
  always @(*) begin
    rs1_dout = rf[rs1];
    rs2_dout = rf[rs2];
  end
  always @(posedge clk) begin
    if(write_enable && rd) // key point!
      rf[rd] <=rd_din;
  end 
  ...
endmodule
```
> RegisterFile은 register number가 input으로 들어오면 해당 register에 있는 값을 가져오는 Read와 register에 값을 쓸 경우 해당 register에 값을 write하는 과정이다. 먼저 Read의 경우 instruction을 읽어오는 과정이므로 매번 일어날 것이다. 따라서, rs1, rs2의 값이 input으로 들어오면, 즉 변화가 생기면 rs1_dout, rs2_dout으로 내보내게 Asynchronously하게 구현하였다. Write는 store의 경우 register write를 하지 않기 때문에 control이 필요하다. 또한, 이 과정은 write back으로 위에서 언급하였던 한 cycle 중 2번째 posedge에 실행된다고 생각하고 구현하였기 때문에 clk이 posedge이면서 write_enable일 때 해당 register에 data를 쓰게 구현하였다. 추가로 rd가 0, 즉 x0에 쓰는 경우 이 경우는 write 하지 못하게 구현하였다. 
- 3. ALU
```verilog
module ALU(input [3:0] alu_op, input signed [`word_size-1:0] alu_in_1,
input signed [`word_size-1:0] alu_in_2,output reg signed [`word_size-1:0] alu_result,output reg alu_bcond);
    always @(*) begin
        case(alu_op)
            `ALU_ADD : alu_result = alu_in_1 + alu_in_2;
            `ALU_SUB : alu_result = alu_in_1 - alu_in_2;
            `ALU_SLL: alu_result = alu_in_1 << alu_in_2[4:0];
            `ALU_XOR: alu_result = alu_in_1 ^ alu_in_2;
            `ALU_OR: alu_result = alu_in_1 | alu_in_2;
            `ALU_AND: alu_result = alu_in_1 & alu_in_2;
            `ALU_SRL: alu_result = alu_in_1 >> alu_in_2[4:0];
            `ALU_BEQ: begin
                alu_result = alu_in_1 - alu_in_2;
                if(alu_result == 0)
                    alu_bcond = 1;
                else
                    alu_bcond = 0;
            end
            `ALU_BNE: begin
                alu_result = alu_in_1 - alu_in_2;
                if(alu_result != 0)
                    alu_bcond = 1;
                else
                    alu_bcond = 0;
            end
            `ALU_BLT: begin
                alu_result = alu_in_1 - alu_in_2;
                if(alu_result< 0)
                    alu_bcond = 1;
                else
                    alu_bcond = 0;
            end
            `ALU_BGE: begin
                alu_result = alu_in_1 - alu_in_2;
                if(alu_result >= 0)
                    alu_bcond = 1;
                else
                    alu_bcond = 0;
            end
        endcase

    end
endmodule

module ALUControlUnit(input [`word_size-1:0] part_of_inst, output reg [3:0] alu_op);
    always @(*) begin
        case(part_of_inst[6:0])
            `ARITHMETIC: begin 
                if(part_of_inst[30])
                    alu_op = `ALU_SUB;
                else begin
                    case(part_of_inst[14:12])
                        `FUNCT3_ADD: alu_op = `ALU_ADD;
                        `FUNCT3_SLL: alu_op = `ALU_SLL;
                        `FUNCT3_XOR: alu_op = `ALU_XOR;
                        `FUNCT3_OR: alu_op = `ALU_OR;
                        `FUNCT3_AND: alu_op = `ALU_AND;
                        `FUNCT3_SRL: alu_op = `ALU_SRL;
                    endcase
                end
            end
            `ARITHMETIC_IMM: begin
                case(part_of_inst[14:12]) 
                    `FUNCT3_ADD: alu_op = `ALU_ADD;
                    `FUNCT3_SLL: alu_op = `ALU_SLL;
                    `FUNCT3_XOR: alu_op = `ALU_XOR;
                    `FUNCT3_OR: alu_op = `ALU_OR;
                    `FUNCT3_AND: alu_op = `ALU_AND;
                    `FUNCT3_SRL: alu_op = `ALU_SRL;
                endcase
            end
            `LOAD: alu_op = `ALU_ADD;
            `STORE: alu_op = `ALU_ADD;
            `JALR: alu_op = `ALU_ADD;
            `BRANCH: begin
                case(part_of_inst[14:12])
                    `FUNCT3_BEQ: alu_op = `ALU_BEQ;
                    `FUNCT3_BNE: alu_op = `ALU_BNE;
                    `FUNCT3_BLT: alu_op = `ALU_BLT;
                    `FUNCT3_BGE: alu_op = `ALU_BGE;
                endcase
            end
        endcase
    end
endmodule
```
> ALU.v에는 alu module과 alu control module을 함께 구현하였다. <br>
> 1. ALUControlUnit Module <br>
> Instruction 전체를 Input으로 받아 각 opcode를 기준으로 case문을 사용하였다. ARITHMETIC OPCODE의 경우 구현해야 할 것 중 sub만 30번 째 bit의 값이 1이므로 이 값이 1인 경우 sub로 alu_op값을 sub로 정하였다. alu_op에 들어가는 값은 opcodes.v에 ALU constant를 4Bit로 새롭게 지정하였다. LOAD, STORE,JALR의 경우 ADD로 지정하였으며, BRANCH의 경우 초기에는 SUB로 통일하였으나, 이후 ALU에서의 통제를 간편하게 하기위해 새로 지정하였다. <br>
> 2. ALU <br>
> ALUControlUnit에서 이미 ALU에서 필요한 과정을 정하여 이를 input으로 넘어오기 때문에, 그 option에 따라 계산만 해준다. Branch의 경우 alu_result를 두 input의 뺄셈으로 계산하고 result 값으로 각 조건 충족을 판별하였다. 
- 4. ControlUnit
```verilog
module ControlUnit(input [6:0] part_of_inst, output reg is_jal, output reg is_jalr, output reg branch, output reg mem_read, 
output reg mem_to_reg, output reg mem_write, output reg alu_src, output reg write_enable, output reg pc_to_reg, output reg is_ecall);
    always @(*) begin
        is_jal = part_of_inst == `JAL;
        is_jalr = part_of_inst == `JALR;
        branch = part_of_inst == `BRANCH;
        mem_read = part_of_inst == `LOAD;
        mem_to_reg = part_of_inst == `LOAD;
        mem_write = part_of_inst == `STORE;
        alu_src = ((part_of_inst != `ARITHMETIC) && (part_of_inst != `BRANCH));
        write_enable = ((part_of_inst != `STORE) && (part_of_inst != `BRANCH) && (part_of_inst != `ECALL));
        pc_to_reg = (part_of_inst == `JAL || part_of_inst == `JALR);
        is_ecall = part_of_inst == `ECALL;
    end
endmodule
```
> ControlUnit에서는 각 module에서의 통제 방향을 정한다. 기준은 instruction의 opcode를 기준으로 판별한다. 각 값은 Lecture Note 5(page 35)를 참조하였다. 추가로, 이번 lab 2를 원활히 종료하기 위해서는 ecall을 추가로 구현해야 하는데, 간단하게 opcode가 ecall이면 이 값을 Cpu module의 output인 is_halted에 넣어 Top module에 전달한다.
- 5. Memory
```verilog
module InstMemory 
  integer i;
  // Instruction memory
  reg [31:0] mem[0:MEM_DEPTH - 1];
  // Do not touch imem_addr
  wire [31:0] imem_addr;
  assign imem_addr = {2'b00, addr >> 2};

  // TODO
  // Asynchronously read instruction from the memory 
  // (use imem_addr to access memory)
  always @(*) begin
    if(!reset) begin
      dout = mem[imem_addr];
    end
  end
  ...
endmodule

module DataMemory
  integer i;
  // Data memory
  reg [31:0] mem[0: MEM_DEPTH - 1];
  // Do not touch dmem_addr
  wire [31:0] dmem_addr;
  assign dmem_addr = {2'b00, addr >> 2};

  // TODO
  // Asynchrnously read data from the memory
  // Synchronously write data to the memory
  // (use dmem_addr to access memory)
  always @(*) begin
    if(mem_read) begin
      dout = mem[dmem_addr];
    end
  end
  always @(posedge clk) begin
    if(mem_write)
      mem[dmem_addr] <= din;
  end
endmodule
```
> 1. InstMemory <br>
> Instruction Memory는 instruction을 담고 있는 memory이다. 이는 별도의 source file이 존재하며 이를 파일 입출력으로 받아오는 형식이다. imem_addr은 alu 계산을 통해 넘어온 addr 값을 4Byte allignment를 고려하여 계산된 일종의 Index 값이다. 이를 이용하여 memory에 접근하여 dout에 담아 output으로 보낸다. 이는 instruction을 읽는 과정으로 asynchornously하게 구현하였다. <br>
> 2. DataMemory <br>
> DataMemory는 흔히 생각하는 memory와 동일하다. 두개를 구분해 놓은 이유는 구현의 편의성을 고려한 것이라고 한다. 실제로는 두 메모리는 나누어져 있지 않다. 마찬가지로, Read의 경우 asynchronously하게 구현하되, memory를 읽어오는 과정이 있는 load와 같은 instruction을 고려하여 mem_read가 참인 경우 읽어온다. write는 일종의 write - back으로 생각하여 register write-back과 동일한 생각으로 cycle의 두 번째 posedge에 저장되게 synchronously로 구현하였다. STORE instruction을 고려하여 mem_write가 참인 경우 write하게 구현하였다.
- 6. Immediate
```verilog
module ImmediateGenerator (input [`word_size -1 : 0] inst, output reg [`word_size - 1 : 0] immediate);
    always @(*) begin
        case(inst[6:0])
            `ARITHMETIC_IMM: immediate = {{20{inst[31]}},inst[31:20]};
            `LOAD: immediate = {{20{inst[31]}},inst[31:20]};
            `STORE: immediate = {{20{inst[31]}},inst[31:25],inst[11:7]};
            `BRANCH: immediate = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
            `JAL: immediate = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
            `JALR: immediate = {{20{inst[31]}},inst[31:20]};
        endcase

    end
endmodule
> Instruction 전체를 input으로 받고, asynchronously하게 작동하게 구현하였다. Output에 Input의 opcode의 따라 sign-extending을 진행한다.
```
- 7. CPU
```verilog
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
        //immediate = {{20{inst[31]}},inst[31:20]};
      end
      `LOAD: begin
        rd = inst[11:7];
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        //immediate = {{20{inst[31]}},inst[31:20]};
      end
      `STORE: begin
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        //immediate = {{20{inst[31]}},inst[31:25],inst[11:7]};
      end
      `BRANCH: begin
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        //immediate = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
        end
        `JAL: begin
          rd = inst[11:7];
          //immediate = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
        end
        `JALR: begin
          rd = inst[11:7];
          funct3 = inst[14:12];
          rs1 = inst[19:15];
          //immediate = {{20{inst[31]}},inst[31:20]};
        end
        `ECALL: begin
          rs1 = 5'b10001;
        end
    endcase
    immediate = imm_after;
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
    if(is_jalr)
      next_pc = alu_result;
    else begin
      if(is_jal || (branch && alu_bcond))
        next_pc = immediate + current_pc;
      else
        next_pc = current_pc + 4;
    end      
  end
```
> 이전의 module들에서는 Design에서 박스들의 요소들의 기능을 구현하였다면, cpu.v에서는 이 module들에서 나오는 결과를 이용하여 각 stage들이 원활히 이루어지게 흐름을 통제하는 역할을 수행한다. 추가로, cpu에서 instruction decoding을 진행한다.. 본 report에서는 cpu.v에서 always 구문 만 설명하며, 그 이외에는 port connection이다. Always 구문 시작으로 instruction decoding을 진행한다. opcode에 따라 rs1,rs2,rd등을 부여한다. 이 기준은 RISC-V spec의 instruction 설명을 토대로 작성하였다.Case가 끝나면 multiplexer의 기능을 하는 if문들과 이후 이어질 stage의 통제를 위한 값들을 기준으로 if - else문이 사용된다. PC를 case에 따라 add + update 할 때는 adder를 module로 따로 구현하진 않았고, '+'를 이용하여 구현하였다. Multiplexer 또한 if-else로 처리하였다. 다음과 같이 한 이유는 module을 사용하면 code의 가독성이 높아지지만, 구현하는 입장에서는 if-else가 흐름을 한눈에 볼 수 있어 위와 같이 구현하였다. ECALL은 x17의 값을 확인하여 10인 경우 is_halted를 1로 만들어 code를 종료한다. 
- 7. opcodes
```verilog
...
//wordsize
`define word_size 32
//ALU CODE
`define ALU_ADD 4'b0000
`define ALU_SUB 4'b0001
`define ALU_SLL 4'b0010
`define ALU_XOR 4'b0011
`define ALU_OR 4'b0100
`define ALU_AND 4'b0101
`define ALU_SRL 4'b0110
`define ALU_BEQ 4'b0111
`define ALU_BNE 4'b1000
`define ALU_BLT 4'b1001
`define ALU_BGE 4'b1010
```
> ALU option과 32bit system을 고려한 macro를 추가로 지정하였다. ALU option은 기존의 funct3 code를 사용하고자 하였으나, 겹치는 것이 있어 한꺼번에 처리하기 위해 4bit의 macro를 정의하였다.
## 4. Discussion
1. reg vs. wire
> 이번 과제에서 가장 어려웠던 부분이다. 기존에 해오던 C,C++등과 달리 Verilog의 wire, reg개념은 매우 혼동스러웠다. 특히, 스스로의 판단으로는 wire를 써야 할 것 같아 wire로 선언하여 사용하면 compile 과정에서 'illegal reference net' 오류가 발생하여 원인을 모른채 reg로 바꾸어 사용하는 상황이 있었다. 이는 차기 과제에서도 어려울 것으로 생각된다. 하지만 이번 과제를 통해 세운 기준은, 값을 저장할 필요가 없으면, 즉 어디에 담아두었다가 보내는 경우가 아니면 대부분 wire를 사용한다는 것이다. Register에 Wire를 꽂아 사용한다고 생각하면 조금 수월할 것 같기도 하다. <br>
2. Time
> Module들이 늘어나면서 각 module간의 dependency에 대해 고민을 많이 하였다. 구현 할 당시에는 해당 고민을 해결하기 위해 적용한 방법이 cpu.v에서 흐름을 통제하는 것이다. 이로 인해 몇몇 module을 구현하지 않은 점이 있다. 보고서를 작성 할 시점에 다시 생각해보니, always구문의 sensetive list들이 있어 이 문제가 해결 될 수 있겠다고 생각하였다. <br>
3. x0 must be zero.
> Code를 작성하고 시뮬레이션을 돌려보았을 때, x0에 값이 0으로 고정되지 않고 변화하여 알고 있던 내용과 상충하였다. x0는 0으로 hardcoding 되어 있어 바뀌지 않는다고 배운 것 같은데 값이 변화하였다. 이를 해결하기 위해 registerfile에서 rd가 0이 아닌 값에만 write를 허용하게 구현하였다. 이를 통해 발생했던 문제를 해결하고 simulation을 통과하였다.
## 5. Conclusion
    이번 과제를 통해 single cycle cpu를 구현해 보았다. 회로 디자인과 작동 방식은 Lecture Note를 통해 이해하였지만, 과제를 하면서 clock과 더불어 작동하는 과정을 알게 되었다. 또한, 본격적으로 디버깅이 필요한 시점이 오면서 wave를 보는법과 $monitor과 같은 방법을 익히게 되었다. 다만, 현재는 memory의 형식을 일차원 array로 편하게 구현하였기 때문에, 실제 memory에서는 어떻게 구현 될지는 좀더 고민이 필요할 것 같다.