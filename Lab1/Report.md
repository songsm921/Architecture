# Computer System Lab 1 Report
## 컴퓨터공학과 20180085 송수민 / Team #3 
#### 개발환경: macOS (icarus / gtkwave) -> Windows 11 (Modelsim)
### 1. Introduction
 > 이번 Lab 1에서는 앞으로 Lab에서 다루게 될 Verilog와 이를 통해 작성 한 코드를 simulate 하는 방법을 알아보는 것에 큰 목적을 두고 있다. 또한, Combinational logic design & implementation과 Sequential logic design & implementation을 수행 할 수 있다. 상기 목적을 수행하기 위해 이번 과제에서는 ALU 구현과 간단한 자판기(Vending machine)을 구현하고자 한다. ALU는 별도의 report 없이 testbench 결과만 첨부하도록 한다. 
 ### 2. Design
 아래 그림은 Vending machine의 Design이다. 
 ![design](./Design.jpg)
 > Top-level Module은 i_input_coin, i_selection_item, i_trigger_return을 input으로 받는다. 후술하겠지만, i_trigger_return은 reset_n에 의해 active-low로 작동하는 input이므로 추가로 사용하지 않아도 구현이 가능하였다. Top-level module 내부에 submodules이 있는데, skeleton code를 그대로 활용하였다. 차례로 check_time_and_coin, calculate_current_state, change_state이며 각각의 input, output 중 중요한 것들을 뽑아 Design에 나타내었다. 나머지 input / output은 implementation에서 설명하고자 한다. 아래는 각 submodule들의 간략한 설명이다.
   - 1. check_time_and_coin
  > 이 submodule에서는 남아 있는 시간을 확인하고, 시간에 따라 잔돈을 계산하거나 시간을 update하는 module이다. 
  - 2. calculate_current_state
  > Module명대로 현재의 state에 대해 판별하는 module이다. 현재 상황을 기반으로 다음 state를 계산하고, 현재 상황을 기반으로 출고될 수 있는 item을 판별하는 module이다.
  - 3. change_state
  > 2)에서 계산한 값을 현재 state로 update하는 Module이다.
  <br>
  ### 3. Implementation
#### 1. check_time_and_coin
```verilog
module check_time_and_coin(i_input_coin,o_output_item,i_select_item,clk,coin_value,current_total,reset_n,wait_time,o_return_coin,i_return_trigger);
	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1 : 0] o_output_item;
	input [`kNumItems-1:0]	i_select_item;
	input [`kTotalBits-1:0] current_total;
	input i_return_trigger;
	input [31:0] coin_value [`kNumCoins-1:0];
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
		if((wait_time > `kWaitTime) || !reset_n || i_return_trigger) begin
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
```
> 먼저 module이 처음에 실행되면 return_coin value와 대기시간을 0으로 초기화 시켜주었다. 차례로 3개의 always문이 나오는데 각 문의 기능은 아래와 같다.
> 1. Lab 설명을 보면 새로운 coin이 들어왔을 때, item을 성공적으로 출고하였을 때 대기시간을 다시 100으로 초기화한다. 대기시간을 0으로 설정하고 100을 넘으면 대기시간이 초과되는 것으로 전체적인 구현을 했기에 0으로 설정한다. 또한, sensitive list는 i_select_item을 넣어주지만 사용자가 누른 item이 출고되어야지만 대기시간이 초기화되는 것이므로 if문의 condition은 o_output_item을 이용하여 판별한다. 출고된 item이 있다면 저 값이 0이 아닐 것이기 때문에 if condition을 만족한다.
> <br><br>
 > 2. 두 번째 always는 잔돈을 계산하는 것이다. 만약 잔돈이 2300원이라면 자판기는 2300을 한번에 내보내는 것이 아니라, 한 차례에 하나씩 돈을 주어 전체 잔돈을 충족시킨다. 따라서, 본 과제에서 가장 큰 단위인 1000을 기준으로 1000원 이상이면 1000원을 먼저 주고, 이 과정을 반복하다가 500원 이상 1000원 미만이면 500원을 주고 남은 금액은 100원으로 충당하여 준다. 이 코드를 두번째 always문에 작성하였다.
 > <br><br>
 > 3. clk값이 변할 때 마다 wait_time을 update한다. 이때, reset_n은 active_low이기 때문에 !reset_n이 참이면 대기시간을 0으로 초기화 하고, 거짓이라면 대기시간을 1 증가 시켜준다.

#### 2. calculate_current_state
```verilog
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
	//register  -> assign x
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
```
> 1)과 마찬가지로 initial을 이용하여 시작 시 초기화를 해준다. 두 개의 always은 아래 설명과 같은 기능을 한다.
> <br>
 > 1. 현재의 state에서 들어온 input, output을 기반으로 새 state의 정보를 계산한다. 자판기에 돈 여러개를 한꺼번에 넣는 것이 아니므로, 하나의 값이 발견되면 바로 for문을 멈출 수 있도록 index의 값을 조정하였다. 각 total value는 이전 상황과 무관하게 계산되어야 하므로, 매번 0으로 초기화 시켜준다. input_total은 1로 변한 i_input_coin의 index를 이용하여 coin_value를 알아낸다. output_toal도 같은 맥락이며, return_total은 1번 submodule에서 나온 결과값을 배경으로 판별한다. 최종적으로, next state information인 current_total_nxt를 계산하여준다.
> <br><br>
 > 2. 현재 current_total을 이용하여 item_price보다 current_total이 같거나 크면 그 item을 살 수 있다는 뜻으로 1을 넣어준다. 그 다음으로 사용자가 선택한 item이 구매 가능한 item이면 해당 index를 이용하여 output_item을 표현해준다.
 #### 3. change_state
```verilog
module change_state(clk,reset_n,current_total_nxt,current_total);
	input clk;
	input reset_n;
	input [`kTotalBits-1:0] current_total_nxt;
	output reg [`kTotalBits-1:0] current_total;
	// Sequential circuit to reset or update the states
	always @(posedge clk ) begin
		if (!reset_n) begin
			// TODO: reset all states.
			current_total <= `kTotalBits'd0;
		end
		else begin
			// TODO: update all states.
			current_total <= current_total_nxt;
		end
	end
endmodule 
```
> reset_n에 따라 현재 state를 완전 초기화 할 것 인지, 2번 submodule에서 계산한 state로 update 시킬 것인지를 구현한다.
### 4. Discussion
> Verilog를 처음 생각했을 때는 기계어와 같이 low level language와 같은 느낌이 들어 과제 수행에 어려움을 예상하였으나, 생각보다 C language와 같은 concept을 가지고 있음을 알아냈다. 물론, 모든 C concept이 있는 것은 아니기 때문에 추가적으로 생각이 필요한 부분도 존재하였다. 예를들어, for문에서 특정 조건을 만족하면 그 이후 index는 탐색하고 싶지 않아 break 혹은 continue와 같은 문법을 사용하고 싶었지만, 이는 찾을 수가 없어 index를 조정하는 방향으로 구현에 성공하였다. 또한, always구문이 while과 비슷한 것 같으면서도 같다고 생각하며 코드를 구현하면 잘못된 방향으로 구현될 수 있음을 인지하면서 수행하니 synchronize와 같은 issue에서 어려움을 겪었다. 본 과제에서는 clock과 wait_time에서 이와 같은 문제를 겪을 수 있었는데, 어떠한 조건을 만족시키는 순간에 집중하기 보다는, 부등호를 사용하여 전체적인 조건을 만족하는 수준에서 해결하였다. <br>
> 마지막으로, sensitive list를 사용하면서 list에 있는 변수에 시선이 사로잡혀 실수를 범할 수도 있었다. 1번 submodule에서 i_select_item이 그 예이다. 본 vending machine에서는 item을 선택하였다고 무조건 time을 초기화하지 않는다. Item을 선택하고 이 item이 구매 가능하여 구매를 하게되면 대기시간이 초기화 되는 것인데, 이를 간과하였었다. 게다가, 이 문제는 testbench에서도 통과하는 부분이라 쉽게 잡을 수 없었는데, 보고서를 작성 중 원래 작성자가 생각한 논리와 맞지 않아 다시 보게되어 알게 되었다.
> <br>
> 개발환경에서도 어려움을 겪었었다. 처음에는 Apple silicon 기반 macOS에서 icarus verilog와 gtkwave를 이용하여 구현하였는데, ALU는 구현 및 시뮬레이션 모두 문제가 없었으나, Vending machine에서는 port를 연결하는 과정에서 array를 top-level module과 submodule간에 연결이 안되는 상황이 발생하였다. 웹문서에 따르면, icarus-verilog의 한계라고 말하는것을 보아 macOS에서는 제한사항이 있을것 같다. 결국, Windows intel 기반의 환경으로 넘어와서 compile을 해본 결과 문제 없이 잘 구동되었다.
### 5. Conclusion
> 이번 과제를 통해 Verilog 코드 작성법 / Modelsim simulation 방법을 숙달하게 되었다. 또한, combinational logic, sequential logic을 구현하고 modulization을 통해 submodule - top-level module을 알게 되었다. 
### Result
- ALU testbench result (42/42) <br>
![alu](./alu.png)
- Vending machine testbench result (23/23) <br>
![vending](./vending.png)
