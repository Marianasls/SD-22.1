module dht11_drive(
input sys_clk,
input rst_n,

inout dht11,//dht11 single bus
output reg [31:0] data_valid//valid data
); //parameter define
parameter POWER_ON_NUM = 1000_000;//Power-on delay waiting time, unit us
//State machine state
parameter st_power_on_wait = 3'd0;//Power-on delay waiting
parameter st_low_20ms = 3'd1;//Host sends 20ms low level
parameter st_high_13us = 3'd2;//Host releases the bus 13us
parameter st_rec_low_83us = 3'd3;//Receive 83us low level response
parameter st_rec_high_87us = 3'd4;//Wait for 87us high level ( Ready to receive data)
parameter st_rec_data = 3'd5;//Receive 40-bit data
parameter st_delay = 3'd6;//Delay and wait, re-operate DHT11 after the delay is complete

//reg define reg [2:0] cur_state;//current state
reg [2:0] next_state;//next state

reg [4:0] clk_cnt;//frequency division counter reg clk_1m;//1Mhz clock
reg [20:0] us_cnt;//1 microsecond counter
reg us_cnt_clr;//1 microsecond counter clear signal

reg [39:0] data_temp;//Buffer the received data reg step;//Data collection status
reg [5:0] data_cnt;//Counter for receiving data

reg dht11_buffer;//DHT11 output signal reg dht11_d0;//DHT11 input signal register 0
reg dht11_d1;//DHT11 input signal register 1

//wire define wire dht11_pos;//
//DHT11 rising edge wire dht11_neg;//DHT11 falling edge

//************************************************ ***** //** main code
//************************************* ****************

assign dht11 = dht11_buffer; assign dht11_pos = ~dht11_d1 & dht11_d0;//collect the rising edge
assign dht11_neg = dht11_d1 & ~dht11_d0;//collect the falling edge

//Get the 1Mhz frequency division clock //The system clock is 50M and the 1M clock is obtained through even frequency division, that is, 50 frequency division
//Use the counter from 0 technology to 50/2-1 even frequency division N/2-1
//This project uses The 1M frequency division is because the DHT11 timing is mainly in us.
always @(posedge sys_clk or negedge rst_n)
begin
if (!rst_n)
begin
clk_cnt <= 5'd0;
clk_1m <= 1'b0;
end
else if (clk_cnt <5'd24)
clk_cnt <= clk_cnt + 1'b1;
else begin
clk_cnt <= 5'd0;
clk_1m <= ~ clk_1m;
end
end

//Register the DHT11 input signal twice for edge detection always @ (posedge clk_1m or negedge rst_n) begin
if (!rst_n) begin
dht11_d0 <= 1'b1;
dht11_d1 <= 1'b1;
end
else begin
dht11_d0 < = dht11;
dht11_d1 <= dht11_d0;
end

//1 microsecond counter always @ (posedge clk_1m or negedge rst_n) begin
if (!rst_n)
us_cnt <= 21'd0;
else if (us_cnt_clr)
us_cnt <= 21'd0;
else
us_cnt <= us_cnt + 1'b1;

//State jump always @ (posedge clk_1m or negedge rst_n)
begin
if (!rst_n)
cur_state <= st_power_on_wait;//Power on delay wait for
else
cur_state <= next_state;
end

//The state machine reads DHT11 data always @ (posedge clk_1m or negedge rst_n)
begin
if(!rst_n)
begin
next_state <= st_power_on_wait;
data_temp <= 40'd0;
step <= 1'b0;
us_cnt_clr <= 1'b0;
data_cnt <= 6'd0;
dht11_buffer <= 1'bz;
end
else
begin
case (cur_state)
//Delay for 1 second after power-on and wait for
//DHT11 to stabilize st_power_on_wait/0
begin
if(us_cnt <POWER_ON_NUM)//Power-on is not reached Delay time 1s
begin
dht11_buffer <= 1'bz;//Idle state release bus
us_cnt_clr <= 1'b0;
end
else
begin//Enter the next state, clear the us counter
next_state <= st_low_20ms;
us_cnt_clr <= 1'b1;
end
end
//FPGA sends start signal (low level for 20ms)
//st_low_20ms://1
begin
if(us_cnt <20000) begin
dht11_buffer <= 1'b0;//start signal is low level
us_cnt_clr <= 1'b0;
end
else begin
dht11_buffer <= 1'bz;//Release the bus after the start signal ends
next_state <= st_high_13us;
us_cnt_clr <= 1'b1;
end
end
//Wait for the response signal of
DHT11 (wait 10~20us) st_high_13us://2
begin
if (us_cnt <20) begin
us_cnt_clr <= 1'b0;
if(dht11_neg)
begin//DHT11 response signal detected
next_state <= st_rec_low_83us;
us_cnt_clr <= 1'b1;
end
end
else//No response for more than 20us, Re-entry delay
next_state <= st_delay;
end
//Wait for the end of the 83us low level response signal of DHT11
//st_rec_low_83us://3
begin
if(dht11_pos)
next_state <= st_rec_high_87us;
end
//DHT11 pulls 87us to notify FPGA to prepare to receive data
//st_rec_high_87us: begin
if(dht11_neg) begin//The preparation time is over
next_state <= st_rec_data;
us_cnt_clr <= 1'b1;
end
else begin//High level ready to receive data
data_cnt <= 6'd0;
data_temp <= 40'd0;
step <= 1'b0;
end
end
//Continuously receive 40-bit data
//st_rec_data: begin
case(step)
0: begin//Receive data low level
if(dht11_pos) begin
step <= 1'b1;
us_cnt_clr <= 1'b1;
end
else//Wait for the end of data low level
us_cnt_clr <= 1'b0;
end
1: begin//Receive data high level
if(dht11_neg) begin
data_cnt <= data_cnt + 1'b1;
//Judging that the received data is 0/1
if(us_cnt <60)
data_temp <= {data_temp[38:0],1'b0};//Shift register Writing
else
data_temp <= {data_temp[38:0],1'b1};
step <= 1'b0;
us_cnt_clr <= 1'b1;
end
else//Wait for the end of the data high level
us_cnt_clr <= 1'b0;
end
endcase

            if(data_cnt == 40) begin//data transmission is over, verify check digit
                next_state <= st_delay;
                if(data_temp[7:0] == data_temp[39:32] + data_temp[31:24] 
                                     + data_temp[23:16] + data_temp[15:8])
                    data_valid <= data_temp[39:8];  
            end
        end 
           //Delay 2s after completing a data collection
        st_delay:begin
            if(us_cnt <2000_000)
                us_cnt_clr <= 1'b0;
            else begin//Resend the start signal after the delay is over
                next_state <= st_low_20ms;      
                us_cnt_clr <= 1'b1;
            end
        end
        default:;
    endcase
	end 
end
endmodule