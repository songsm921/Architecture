// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  
  /***** Wire declarations *****/
  reg [4:0] rs1;
  reg [31:0]total_cyc;
  wire IF_ID_write;
  wire pc_write;
  wire [31:0] rs1_dout, rs2_dout;
  wire [31:0] imm;
  wire inter_forward_A, inter_forward_B;
  wire is_ecall;
  wire [6:0]alu_op;
  wire [3:0]alu_oper;         // will be used in EX stage
  wire alu_src;        // will be used in EX stage
  wire mem_write;      // will be used in MEM stage
  wire mem_read;       // will be used in MEM stage
  wire mem_to_reg;     // will be used in WB stage
  wire reg_write;      // will be used in WB stage
  wire pc_to_reg;
  wire isStall;
  wire is_branch;
  wire is_jal;
  wire is_jalr;
  reg [31:0]alu_in_1;
  reg [31:0]alu_in_1_temp;
  reg [31:0]alu_temp;
  reg [31:0]alu_in_2;
  wire [31:0]alu_result;
  wire alu_bcond;
  /***** Register declarations *****/
  wire [31:0]dout;
  wire [31:0]dout_dmem;
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
 
  /***** IF/ID pipeline registers *****/
  reg [31:0]IF_ID_inst;           // will be used in ID stage
  reg [31:0]IF_ID_pc;
  reg [31:0]IF_ID_pred_pc;
  reg IF_ID_prediction;
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [6:0]ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_pc_to_reg;
  reg ID_EX_is_branch;
  reg ID_EX_is_jal;
  reg ID_EX_is_jalr;
  // From others
  reg [31:0]ID_EX_inst;
  reg [31:0]ID_EX_rs1_data;
  reg [31:0]ID_EX_rs2_data;
  reg [4:0]ID_EX_rs1_num;
  reg [4:0]ID_EX_rs2_num;
  reg [31:0]ID_EX_imm;
  reg [4:0]ID_EX_rd;
  reg ID_EX_halt;
  reg [31:0]ID_EX_pc;
  reg [31:0]ID_EX_pred_pc;
  reg ID_EX_prediction;
  /////
  wire [1:0]Forward_A, Forward_B;
  reg for_ecall;
  ////


  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write; 
  reg EX_MEM_pc_to_reg;    // will be used in WB stage
  // From others
  reg [31:0]EX_MEM_alu_out;
  reg [31:0]EX_MEM_dmem_data;
  reg [4:0]EX_MEM_rd;
  reg [31:0]EX_MEM_pc;
  reg EX_MEM_halt;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;
  reg MEM_WB_pc_to_reg;      // will be used in WB stage
  // From others
  reg [4:0]MEM_WB_rd;
  reg [31:0]MEM_WB_mem_to_reg_src_1;
  reg [31:0]MEM_WB_mem_to_reg_src_2;
  reg [31:0]MEM_WB_pc;
  reg MEM_WB_halt;
  reg [31:0]final_data;
  reg [31:0]next_pc;
  wire [31:0]pred_pc;
  wire prediction;
  wire [31:0]current_pc;
  wire [31:0]actual_pc;
  reg correct;
  reg correct2;
  reg isBJ;
  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),  
    .pc_write(pc_write),       // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );

  BP BranchPredictor(
    .reset(reset),
    .clk(clk),
    .PC(current_pc),
    .target_idx(ID_EX_pc[6:2]),
    .target_tag(ID_EX_pc[31:7]),
    .actual_PC(actual_pc),
    .isBJ(isBJ),
    .correct(correct),
    .correct2(correct2),
    .ID_EX_pred_pc(ID_EX_pred_pc),
    .predict_PC(pred_pc),
    .istaken(prediction)
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(dout)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset || !correct || !correct2) begin
      IF_ID_inst <=0;
      IF_ID_pc <= 0;
      IF_ID_pred_pc <= 0;
      IF_ID_prediction <= 0;
      //total_cyc<=0;
    end
    else begin
      //total_cyc <= total_cyc + 1;
      if(IF_ID_write)
        IF_ID_inst <= dout;
        IF_ID_pc <= current_pc;
        IF_ID_pred_pc <= pred_pc;
        IF_ID_prediction <= prediction;
    end
  end

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (IF_ID_inst[24:20]),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (final_data),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );
  InternalForwarding internal(
      .rs1(IF_ID_inst[19:15]),
      .rs2(IF_ID_inst[24:20]),
      .MEM_WB_rd(MEM_WB_rd),
      .MEM_WB_reg_write(MEM_WB_reg_write),
      .inter_forward_A(inter_forward_A),
      .inter_forward_B(inter_forward_B)
  );
  HazardDetection hazard(
    .opcode(IF_ID_inst[6:0]),
    .inst(IF_ID_inst),
    .clk(total_cyc),
    .ID_EX_rd(ID_EX_rd),
    .ID_EX_mem_read(ID_EX_mem_read),
    .correct(correct),
    .correct2(correct2),
    .isStall(isStall),
    .IF_ID_write(IF_ID_write),
    .pc_write(pc_write)
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),  // input
    .isStall(isStall),
    .correct(correct),
    .correct2(correct2), //input
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(reg_write),  // output
    .pc_to_reg(pc_to_reg),     // output
    .alu_op(alu_op),        // output
    .is_ecall(is_ecall),       // output (ecall inst)
    .is_branch(is_branch),
    .is_jal(is_jal),
    .is_jalr(is_jalr)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .inst(IF_ID_inst),  // input
    .immediate(imm)    // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset || !correct || !correct2) begin
      ID_EX_rs1_data <=0;
      ID_EX_rs2_data <=0;
      ID_EX_inst <= 0;
      ID_EX_rs1_num <= 0;
      ID_EX_rs2_num <= 0;
      ID_EX_rd <= 0;
      ID_EX_imm <= 0;
      ////////////
      ID_EX_mem_read <= 0;
      ID_EX_mem_to_reg <= 0;
      ID_EX_mem_write <= 0;
      ID_EX_alu_src <= 0;
      ID_EX_reg_write <= 0;
      ID_EX_pc_to_reg <= 0;
      ID_EX_alu_op <= 0;
      ID_EX_pc_to_reg <= 0;
      ID_EX_is_branch <= 0;
      ID_EX_is_jal <=0;
      ID_EX_is_jalr <= 0;
      ID_EX_pc <= 0;
      ID_EX_pred_pc <=0;
      ID_EX_prediction <=0;
    end
    else begin
      if(inter_forward_A)
        ID_EX_rs1_data <= final_data;
      else
        ID_EX_rs1_data <= rs1_dout;
      if(inter_forward_B)
        ID_EX_rs2_data <= final_data;
      else
        ID_EX_rs2_data <= rs2_dout;
      ID_EX_inst <= IF_ID_inst;
      ID_EX_rs1_num <= IF_ID_inst[19:15];
      ID_EX_rs2_num <= IF_ID_inst[24:20];
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_imm <= imm;
      ID_EX_halt <= for_ecall;
      ////////////
      ID_EX_mem_read <= mem_read;
      ID_EX_mem_to_reg <= mem_to_reg;
      ID_EX_mem_write <= mem_write;
      ID_EX_alu_src <= alu_src;
      ID_EX_reg_write <= reg_write;
      ID_EX_pc_to_reg <= pc_to_reg;
      ID_EX_alu_op <= alu_op;
      ID_EX_pc_to_reg <= pc_to_reg;
      ID_EX_is_branch <= is_branch;
      ID_EX_is_jal <= is_jal;
      ID_EX_is_jalr <= is_jalr;
      ID_EX_pc <= IF_ID_pc;
      ID_EX_pred_pc <=IF_ID_pred_pc;
      ID_EX_prediction <=IF_ID_prediction;
    end
  end


  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(ID_EX_alu_op),
    .inst(ID_EX_inst),  // input
    .alu_op(alu_oper)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_oper),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );
  ActualPC act(
    .correct(correct),
    .correct2(correct2),
    .isJAL(ID_EX_is_jal),
    .isBranch(ID_EX_is_branch),
    .isJALR(ID_EX_is_jalr),
    .PC(ID_EX_pc),
    .immediate(ID_EX_imm),
    .alu_result(alu_result),
    .alu_bcond(alu_bcond),
    .actualPC(actual_pc)  
    );
  Forwarding forward(
    .ID_EX_rs1_num(ID_EX_rs1_num),
    .ID_EX_rs2_num(ID_EX_rs2_num),
    .EX_MEM_rd(EX_MEM_rd),
    .MEM_WB_rd(MEM_WB_rd),
    .EX_MEM_reg_write(EX_MEM_reg_write),
    .MEM_WB_reg_write(MEM_WB_reg_write),
    .Forward_A(Forward_A),
    .Forward_B(Forward_B)
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
      EX_MEM_mem_read <= 0;
      EX_MEM_mem_to_reg <= 0;
      EX_MEM_mem_write <= 0;
      EX_MEM_reg_write <= 0;
      EX_MEM_pc_to_reg <= 0;
      EX_MEM_pc <= 0;
    end
    else begin
      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= alu_temp;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_mem_read <= ID_EX_mem_read;
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
      EX_MEM_mem_write <= ID_EX_mem_write;
      EX_MEM_reg_write <= ID_EX_reg_write;
      EX_MEM_pc_to_reg <= ID_EX_pc_to_reg;
      EX_MEM_halt <= ID_EX_halt;
      EX_MEM_pc <= ID_EX_pc;
    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (dout_dmem)        // output
  );


  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_rd <= 0;
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_pc_to_reg <= 0;
      MEM_WB_pc <= 0;
    end
    else begin
        MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
        MEM_WB_reg_write <= EX_MEM_reg_write;
        MEM_WB_rd <= EX_MEM_rd;
        MEM_WB_mem_to_reg_src_1 <= dout_dmem;
        MEM_WB_mem_to_reg_src_2 <= EX_MEM_alu_out;
        MEM_WB_pc_to_reg <= EX_MEM_pc_to_reg;
        MEM_WB_halt <= EX_MEM_halt;
        MEM_WB_pc <= EX_MEM_pc;
    end
  end
  /////////////////////
  assign is_halted = (MEM_WB_halt) ? 1:0;
  always @(*) begin
    if(is_ecall)
      rs1 = 17;
    else
      rs1 = IF_ID_inst[19:15];
    if(is_ecall && ID_EX_imm == 10)
      for_ecall = 1;
    else
      for_ecall = 0;
    if(Forward_A == 2'b00)
      alu_in_1_temp = ID_EX_rs1_data;
    else if(Forward_A == 2'b01)
      alu_in_1_temp = final_data;
    else if(Forward_A == 2'b10)
      alu_in_1_temp = EX_MEM_alu_out;
    if(ID_EX_is_jal)
      alu_in_1 = ID_EX_pc;
    else
      alu_in_1 = alu_in_1_temp;




    if(Forward_B == 2'b00)
      alu_temp= ID_EX_rs2_data;
    else if(Forward_B == 2'b01)
      alu_temp = final_data;
    else if(Forward_B == 2'b10)
      alu_temp = EX_MEM_alu_out;
    if(ID_EX_alu_src)
      alu_in_2 = ID_EX_imm;
    else
      alu_in_2 = alu_temp;
    if(ID_EX_is_branch || ID_EX_is_jal || ID_EX_is_jalr)
      isBJ = 1;
    else
      isBJ = 0;
    if((ID_EX_is_branch &&(alu_bcond && !ID_EX_prediction)) || (ID_EX_is_branch &&(!alu_bcond && ID_EX_prediction)) || (ID_EX_is_jal && !ID_EX_prediction) || (ID_EX_is_jalr && !ID_EX_prediction))
      correct = 0; // 그냥 예측이 틀렸을 때
    else
      correct = 1;
    if((ID_EX_is_branch &&(alu_bcond && ID_EX_prediction) && ID_EX_pred_pc!= ID_EX_pc + ID_EX_imm)||(ID_EX_is_branch &&(!alu_bcond && !ID_EX_prediction) && ID_EX_pred_pc!= ID_EX_pc + 4) || (ID_EX_is_jal && ID_EX_prediction && ID_EX_pred_pc!= ID_EX_pc + ID_EX_imm) || 
    (ID_EX_is_jalr && ID_EX_prediction && ID_EX_pred_pc!= alu_result)) // 예측은 맞았지만 predict PC가 틀렸을 때
      correct2 = 0;
    else
      correct2 = 1;

    if(MEM_WB_mem_to_reg)
      final_data = MEM_WB_mem_to_reg_src_1;
    else
      final_data = MEM_WB_mem_to_reg_src_2;
    if(MEM_WB_pc_to_reg)
      final_data = MEM_WB_pc + 4;
    if(!correct || !correct2)
      next_pc = actual_pc;
    else
      next_pc = pred_pc;
  end
  
endmodule
