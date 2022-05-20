// dht11
// made by 00
//time 2020.4.28
module dht11(
    input               clk,   
    input               rst_n,                                   
    inout               dht11,   
    output  reg  [31:0] data_valid,
	 output	reg			done,
	 output 	reg			erro
); 
/**************parameter********************/              
parameter  POWER_ON_NUM     = 1000_000;              
parameter  S_POWER_ON      = 3'd0;       
parameter  S_LOW_20MS      = 3'd1;     
parameter  S_HIGH_13US     = 3'd2;    
parameter  S_LOW_83US      = 3'd3;      
parameter  S_HIGH_87US     = 3'd4;      
parameter  S_SEND_DATA     = 3'd5;      
parameter  S_DEALY         = 3'd6; 
//reg define
reg[2:0]   cur_state;        
reg[2:0]   next_state;        
reg[20:0]  count_1us;       
reg[5:0]   data_count;                                       
reg[39:0]  data_temp;        
reg[4:0]   clk_cnt;

reg        clk_1M;       
reg        us_clear;        
reg        state;        
reg        dht_buffer;        
reg        dht_d0;        
reg        dht_d1;
        
initial begin
	  erro <= 1'b0;
	  done <= 1'b0;
 end
 
wire       dht_podge;        //data posedge
wire       dht_nedge;        //data negedge
/*********************main codes*********************/
assign dht11     = dht_buffer;
assign dht_podge   = ~dht_d1 & dht_d0; // catch posedge
assign dht_nedge   = dht_d1  & (~dht_d0); // catch negedge

/*********************counters*****************************/
//clock with 1MHz
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt <= 5'd0;
        clk_1M  <= 1'b0;
    end 
    else if (clk_cnt < 5'd24) 
        clk_cnt <= clk_cnt + 1'b1;       
    else begin
        clk_cnt <= 5'd0;
        clk_1M  <= ~ clk_1M;
    end 
end
//counter 1 us
always @ (posedge clk_1M or negedge rst_n) begin
    if (!rst_n)
        count_1us <= 21'd0;
    else if (us_clear)
        count_1us <= 21'd0;
    else 
        count_1us <= count_1us + 1'b1;
end 
//change state
always @ (posedge clk_1M or negedge rst_n) begin
    if (!rst_n)
        cur_state <= S_POWER_ON;
    else 
        cur_state <= next_state;
end 
// state machine
always @ (posedge clk_1M or negedge rst_n) begin
    if(!rst_n) 
	 begin
        next_state <= S_POWER_ON;
        dht_buffer <= 1'bz;   
        state      <= 1'b0; 
        us_clear   <= 1'b0;
		  data_temp  <= 40'd0;
        data_count <= 6'd0;

    end 
    else 
	 begin
        case (cur_state)     
            S_POWER_ON :    //wait
				begin                
             if(count_1us < POWER_ON_NUM)
				 begin
					dht_buffer <= 1'bz; 
               us_clear   <= 1'b0;
				 end
             else 
				 begin            
               next_state <= S_LOW_20MS;
					us_clear   <= 1'b1;
				 end
            end
                
            S_LOW_20MS:  // send 20 ms
				begin
             if(count_1us < 20000)
				 begin
              dht_buffer <= 1'b0; 
              us_clear   <= 1'b0;
             end
				 else
				 begin
				  next_state   <= S_HIGH_13US;
              dht_buffer <= 1'bz; 
              us_clear   <= 1'b1;
                end    
            end 
               
            S_HIGH_13US:  // Hign 13 us
				begin                      
             if (count_1us < 20)
				 begin
              us_clear    <= 1'b0;
              if(dht_nedge)
				  begin   
					next_state <= S_LOW_83US;
               us_clear   <= 1'b1; 
              end
            end
              else                      
                next_state <= S_DEALY;
            end 
                
            S_LOW_83US:   
				begin                  
             if(dht_podge)                   
               next_state <= S_HIGH_87US;  
            end 
                
            S_HIGH_87US:               // ready to receive data signal
				begin
             if(dht_nedge)
				 begin          
              next_state <= S_SEND_DATA; 
              us_clear    <= 1'b1;
             end
             else
				 begin                
               data_count <= 6'd0;
               data_temp  <= 40'd0;
               state      <= 1'b0;
             end
            end 
                  
            S_SEND_DATA:    // have 40 bit
				begin                                
              case(state)
                0: begin               
                   if(dht_podge)
						 begin 
                     state    <= 1'b1;
                     us_clear <= 1'b1;
                   end            
                   else               
                    us_clear  <= 1'b0;
                   end
						 
                1: begin               
                   if(dht_nedge)
						 begin 
                     data_count <= data_count + 1'b1;
                     state    <= 1'b0;
							us_clear <= 1'b1;              
                     if(count_1us < 60)
                       data_temp <= {data_temp[38:0],1'b0}; //0
                     else                
							  data_temp <= {data_temp[38:0],1'b1}; //1
                    end 
                      else                                            //wait for high end
                       us_clear <= 1'b0;
                    end
                endcase
                
                if(data_count == 40)                                      //check data bit
					 begin  
                 next_state <= S_DEALY;
                 if(data_temp[7:0] == data_temp[39:32] + data_temp[31:24] + data_temp[23:16] + data_temp[15:8])
							begin
								data_valid <= data_temp[39:8];
								done <= 1'b1;
								erro <= 1'b0;
							end
						else
							begin
								done <= 1'b0;
								erro <= 1'b1;
							end
                end
            end 
                
            S_DEALY:                                      // after data received delay 2s
				begin
             if(count_1us < 2000_000)
              us_clear <= 1'b0;
             else
				 begin                 
              next_state <= S_LOW_20MS;              // send signal again
              us_clear <= 1'b1;
				  done <= 1'b0;
				  erro <= 1'b0;
             end
           end
            default :
					cur_state <= cur_state;
        endcase
    end 
end

//edge
always @ (posedge clk_1M or negedge rst_n) begin
    if (!rst_n) begin
        dht_d0 <= 1'b1;
        dht_d1 <= 1'b1;
    end 
    else begin
        dht_d0 <= dht11;
        dht_d1 <= dht_d0;
    end 
end 
endmodule                                     
