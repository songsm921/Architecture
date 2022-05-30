`include "CLOG2.v"
module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 16, /* Your choice */
               parameter NUM_WAYS = 1/* Your choice */) (
    input reset,
    input clk,

    input is_input_valid,
    input [31:0] addr,
    input mem_read,
    input mem_write,
    input [31:0] din,

    output is_ready,
    output reg is_output_valid,
    output reg [31:0] dout,
    output reg is_hit);
  // Wire declarations
  integer i;
  wire is_data_mem_ready;
  wire tag_match;
  wire isdirty;
  wire isvalid;
  // Reg declarations
  // You might need registers to keep the status.
  reg DataMemvalid;
  reg [31:0]DataMemaddr;
  reg [127:0]DataMemdata;
  reg DataMemread;
  reg DataMemwrite;
  wire [127:0]FromDataMem;
  wire dmem_output_valid;
  ///////////////////
  reg [153:0]DCache[0:15];
  reg read_miss;
  reg write_miss;
  reg [2:0]read_miss_state;
  reg [2:0]write_miss_state;
  reg [127:0]temp_read_miss_data;
  reg [31:0]temp_read_miss_addr;
  reg [127:0]temp_write_miss_data;
  reg [31:0]temp_write_miss_addr;
  reg waitforWB_write;
  reg waitforWB;
  reg readhit;
  reg writemisscomplete;
  reg[127:0] hit_count;
  initial begin
    $monitor("Hit : %d",hit_count);
  end


  
  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),
    .is_input_valid(DataMemvalid),
    .addr({DataMemaddr>>4}),
    .mem_read(DataMemread),
    .mem_write(DataMemwrite),
    .din(DataMemdata),
    // is output from the data memory valid?
    .is_output_valid(dmem_output_valid),
    .dout(FromDataMem),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );
  
  assign is_ready = is_data_mem_ready;
  assign tag_match = DCache[addr[7:4]][151:128] == addr[31:8];
  assign isdirty = DCache[addr[7:4]][152] == 1;
  assign isvalid = DCache[addr[7:4]][153] == 1;
  always @(posedge clk) begin
    if(reset) begin
      for(i = 0 ; i<16 ; i= i+1) 
        DCache[i] <= 0;
        read_miss <=0;
        write_miss <=0;
        read_miss_state <= 0;
        write_miss_state <= 0;
        waitforWB <= 0;
        waitforWB_write <= 0;
        readhit <=0;
        writemisscomplete <=0;
        hit_count <= 0;
    end
    else if(is_input_valid) begin // Warning here
      ///read miss process
      if(read_miss && mem_read) begin
        if(read_miss_state == 0 && dmem_output_valid) begin //dataMemory?��?�� data�??��?��?�� �? ?���?
            DCache[addr[7:4]][151:128] <= addr[31:8];
            DCache[addr[7:4]][153] <= 1;
            DCache[addr[7:4]][152] <= 0;
            DCache[addr[7:4]][127:0] <= FromDataMem;
            if(isdirty) begin
              read_miss_state <= 3'b001;
              waitforWB <= 1;
            end
            else begin
              read_miss_state <= 0;
              waitforWB <= 0;
            end
        end
        else if(read_miss_state == 3'b001 && is_data_mem_ready) begin // dataMemory?��?�� write_back?���?
          waitforWB <= 0;
          read_miss_state <=0;
        end
      end
      /////////////////////////////////
      else if(!write_miss && mem_write) begin // write - hit
          DCache[addr[7:4]][152] = 1;
          case(addr[3:2])
          2'b00: begin
            DCache[addr[7:4]][31:0] <= din;
          end
          2'b01: begin
            DCache[addr[7:4]][63:32]<= din;
          end
          2'b10: begin
            DCache[addr[7:4]][95:64]<= din;
          end
          2'b11: begin
            DCache[addr[7:4]][127:96]<= din;
          end
          endcase
      end
      ///////////////////////////////////////
      else if(write_miss && mem_write) begin // write - miss
        if(write_miss_state == 0 && dmem_output_valid) begin
          DCache[addr[7:4]][151:128] <= addr[31:8];
          DCache[addr[7:4]][153] <= 1;
          DCache[addr[7:4]][152] <= 1;
          //DCache[addr[7:4]][127:0] <= FromDataMem;
          case(addr[3:2])
          2'b00: begin
            DCache[addr[7:4]][127:0] <= {FromDataMem[127:32],din};
          end
          2'b01: begin
            DCache[addr[7:4]][127:0]<= {FromDataMem[127:64],din,FromDataMem[31:0]};
          end
          2'b10: begin
            DCache[addr[7:4]][127:0]<= {FromDataMem[127:96],din,FromDataMem[63:0]};
          end
          2'b11: begin
            DCache[addr[7:4]][127:0]<= {din,FromDataMem[95:0]};
          end
          endcase
          if(isdirty) begin
            write_miss_state <= 3'b001;
            waitforWB_write <= 1;
          end
          else begin
            write_miss_state <= 3'b010;
            waitforWB_write <=0;
          end
        end
        else if(write_miss_state == 3'b001 && is_data_mem_ready) begin
          waitforWB_write <= 0;
          write_miss_state <= 3'b010;
        end
      end
    end
  end
  ///////////////////////////////////////////
  always @(*)begin
    if(tag_match && isvalid && mem_read && is_input_valid && !waitforWB)begin // read - hit + after read miss
      readhit = 1;
      DataMemread = 0;
      DataMemwrite = 0;
      DataMemvalid = 0;
      if(!read_miss)
        hit_count = hit_count + 1;
      read_miss = 0;
      case(addr[3:2]) 
        2'b00: begin
          dout = DCache[addr[7:4]][31:0];
        end
        2'b01: begin
          dout = DCache[addr[7:4]][63:32];
        end
        2'b10: begin
          dout = DCache[addr[7:4]][95:64];
        end
        2'b11: begin
          dout = DCache[addr[7:4]][127:96];
        end
      endcase
      is_hit = 1;
      is_output_valid = 1;
    end
    else if((!tag_match || !isvalid) && mem_read && is_input_valid || waitforWB) begin // read-miss
      read_miss = 1;
      DataMemvalid = is_data_mem_ready;
      if(is_data_mem_ready) begin
        if(isdirty && read_miss_state == 0) begin
          temp_read_miss_addr = {DCache[addr[7:4]][151:128],addr[7:4],4'b0000};
          temp_read_miss_data = DCache[addr[7:4]][127:0]; // for write_back
          DataMemaddr = addr;
          DataMemread = 1;
          DataMemwrite = 0;
          //DataMemvalid = 1;
        end
        else if(!isdirty && read_miss_state == 0) begin
          DataMemaddr = addr;
          DataMemread = 1;
          DataMemwrite = 0;
          //DataMemvalid = 1;
        end
        else if(read_miss_state == 3'b001) begin //write-back stage
          DataMemaddr = temp_read_miss_addr;
          DataMemdata = temp_read_miss_data;
          //DataMemvalid = 1;
          DataMemwrite = 1;
          DataMemread = 0;
        end
      end 
    is_hit = 0;
    is_output_valid = 0;
    end
    ////////////////////////////////////////////////////////////////////
    else if(write_miss_state == 3'b010) begin
      is_hit = 1;
      is_output_valid = 1;
      DataMemvalid = 0;
      write_miss = 0;
      write_miss_state = 0;
    end
    else if(tag_match && isvalid && mem_write && is_input_valid && !waitforWB_write) begin
      hit_count = hit_count + 1;
      write_miss = 0;
      DataMemvalid = 0;
      DataMemwrite = 0;
      DataMemread = 0;
      is_hit = 1;
      is_output_valid = 1;
    end
    else if((!tag_match || !isvalid) && mem_write && is_input_valid || waitforWB_write) begin
      write_miss = 1;
      DataMemvalid = is_data_mem_ready;
      if(is_data_mem_ready) begin
        if(isdirty && write_miss_state == 0) begin // datamemory?��?�� ?��?��?��?�� line �??��?���?
          temp_write_miss_addr = {DCache[addr[7:4]][151:128],addr[7:4],4'b0000};
          temp_write_miss_data = DCache[addr[7:4]][127:0];
          DataMemaddr = addr;
          DataMemread = 1;
          DataMemwrite = 0;
        end
        else if(!isdirty && write_miss_state == 0) begin
          DataMemaddr = addr;
          DataMemread = 1;
          DataMemwrite = 0;
        end
        else if(write_miss_state == 3'b001) begin
          DataMemaddr = temp_write_miss_addr;
          DataMemdata = temp_write_miss_data;
          DataMemread = 0;
          DataMemwrite = 1;
        end
      end
      is_hit = 0;
      is_output_valid = 0;
    end
  end

endmodule
