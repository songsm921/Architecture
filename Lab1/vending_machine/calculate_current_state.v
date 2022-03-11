
`include "vending_machine_def.v"
	

module calculate_current_state(i_input_coin,i_select_item,item_price,coin_value,current_total,
input_total, output_total, return_total,current_total_nxt,wait_time,o_return_coin,o_available_item,o_output_item);


	
	input [`kNumCoins-1:0] i_input_coin,o_return_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total;
	input [31:0] wait_time;
	output reg [`kNumItems-1:0] o_available_item,o_output_item;
	output reg  [`kTotalBits-1:0] input_total, output_total, return_total,current_total_nxt;
	integer i;	
	//register assign x
	initial begin
		o_available_item = `kNumItems'b0000;
		o_output_item = `kNumItems'b0000;
		input_total = `kTotalBits'd0;
		output_total = `kTotalBits'd0;
		return_total = `kTotalBits'd0;
		current_total_nxt = `kTotalBits'd0;
	end

	
	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		// Calculate the next current_total state.
		input_total = `kTotalBits'd0;
		for(i=0 ; i< `kNumCoins ; i = i + 1) begin
			if(i_input_coin[i]) begin
				input_total = coin_value[i];
				i = `kNumCoins;
			end
		end
		output_total = `kTotalBits'd0;
		for(i = 0; i<`kNumItems;i = i+1) begin
			if(o_output_item[i]) begin
				output_total = item_price[i];
				i = `kNumItems;
			end
		end
		return_total = `kTotalBits'd0;
		for(i = 0; i<`kNumCoins;i = i + 1) begin
			if(o_return_coin[i]) begin
				return_total = coin_value[i];
				i = `kNumCoins;
			end
		end
		current_total_nxt = current_total + input_total - output_total - return_total;

	end

	
	
	// Combinational logic for the outputs
	always @(*) begin
		// TODO: o_available_item
		// TODO: o_output_item
		o_available_item = `kNumItems'b0000;
		for(i = 0; i<`kNumItems ; i = i+1) begin
			if(item_price[i] <= current_total) 
				o_available_item[i] = 1'b1;
		end
		o_output_item = `kNumItems'b0000;
		for(i = 0 ; i<`kNumItems ; i = i+1) begin
			if(i_select_item[i] && o_available_item[i])
				o_output_item[i] = 1'b1;
		end

	end
 
	


endmodule 