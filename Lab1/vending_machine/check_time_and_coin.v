`include "vending_machine_def.v"

	

module check_time_and_coin(i_input_coin,o_output_item,i_select_item,clk,coin_value,current_total,reset_n,wait_time,o_return_coin,i_trigger_return);
	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] o_output_item;
	input [`kNumItems-1:0]	i_select_item;
	input [`kTotalBits-1:0] current_total;
	input [31:0] coin_value [`kNumCoins-1:0];
	input i_trigger_return;
	output reg  [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;

	// initiate values
	initial begin
		// TODO: initiate values
		o_return_coin = `kNumCoins'b000;
		wait_time = 0;
	end


	// update coin return time
	always @(i_input_coin, i_select_item) begin
		// TODO: update coin return time
		if (i_input_coin || o_output_item)
			wait_time <= 0;	
	end

	always @(*) begin
		// TODO: o_return_coin
		o_return_coin = `kNumCoins'b000;
		if((wait_time > `kWaitTime) || !reset_n || i_trigger_return) begin
			if(current_total >= coin_value[2])
				o_return_coin[2] = 1'b1;
			else if(current_total >= coin_value[1])
				o_return_coin[1] = 1'b1;
			else
				o_return_coin[0] = 1'b1;
		end
	end

	always @(posedge clk ) begin
		if (!reset_n) begin
		// TODO: reset all states.
		wait_time <= 0;
		end
		else begin
		// TODO: update all states.
		wait_time <= wait_time + 1;
		end
	end
endmodule 