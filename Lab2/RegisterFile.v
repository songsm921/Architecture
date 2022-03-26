module RegisterFile(input	reset,
                    input clk,
                    input [4:0] rs1,          // source register 1
                    input [4:0] rs2,          // source register 2
                    input [4:0] rd,           // destination register
                    input [31:0] rd_din,      // input data for rd
                    input write_enable,          // RegWrite signal
                    output reg [31:0] rs1_dout,   // output of rs 1
                    output reg [31:0] rs2_dout);  // output of rs 2
  integer i;
  // Register file
  reg [31:0] rf[0:31];
  //initial begin
   // $monitor("x0: %d, x1: %d, x2: %d, x3: %d, x4: %d, x5: %d, x6: %d, x7: %d ,x8: %d, x9: %d, x10: %d, x11: %d, x12: %d, x13: %d, x14: %d, x15: %d, x16: %d, x17: %d",
   // rf[0], rf[1], rf[2], rf[3], rf[4], rf[5], rf[6], rf[7], rf[8], rf[9], rf[10], rf[11], rf[12], rf[13], rf[14], rf[15], rf[16], rf[17]);
 // end

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

  // Initialize register file (do not touch)
  always @(posedge clk) begin
    // Reset register file
    if (reset) begin
      for (i = 0; i < 32; i = i + 1)
        rf[i] = 32'b0;
      rf[2] = 32'h2ffc; // stack pointer
    end
  end
endmodule
