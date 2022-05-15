// primeira coluna da matriz de led - saida do registrador Rx
// 


module uart
  (
   input        i_Clock,
   input        i_Rx_Serial,
	output		 o_Rx_Serial,	
   output       o_Tx_Active,
   output       o_Tx_Serial,
   output       o_Tx_Done,
	output [7:0] o_Rx_Byte,
	output 		 o_gnd,
	output 		 o_Rx_DV, o_LG, o_LR,
	output [2:0] o_Rx_Main
   );
	
  parameter c_CLKS_PER_BIT    = 5208;
   
  reg r_Tx_DV = 0;
  wire w_Tx_Done;
  wire w_Tx_Serial;
  wire w_Rx_Done;
  reg [7:0] r_Tx_Byte = 0;
  wire [7:0] w_Rx_Byte;
  wire [2:0] w_Rx_Main;
   
  uart_receiver #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST
    (.i_Clock(i_Clock),
     .i_Rx_Serial(i_Rx_Serial),
     .o_Rx_DV(w_Rx_Done),
     .o_Rx_Byte(w_Rx_Byte),
	  .o_SM_Main(w_Rx_Main)
     );
  
  uart_transmitter #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_INST
    (.i_Clock(i_Clock),
     .i_Tx_DV(w_Rx_Done),
     .i_Tx_Byte(w_Rx_Byte),
     .o_Tx_Active(o_Tx_Active),
     .o_Tx_Serial(w_Tx_Serial),
     .o_Tx_Done(w_Tx_Done)
     );
 
   
  // Main Testing:
  initial
    begin
       
      //@(posedge i_Clock);
      //@(posedge w_Rx_Done);
      //@(posedge i_Clock);
      //r_Tx_DV <= 1'b1;
		//@(posedge i_Clock);
      //r_Tx_DV <= 1'b0;
      //@(posedge w_Tx_Done);
       
      //$display(r_Tx_Byte);
       
    end
   assign o_Tx_Serial = w_Tx_Serial;
	assign o_Tx_Done = w_Tx_Done;
	assign o_Rx_Byte = w_Rx_Byte;
	assign o_gnd = 1'b0;
	assign o_Rx_DV = w_Rx_Done;
	assign o_LG = 1'b1;
	assign o_LR = 1'b0;
	assign o_Rx_Main = w_Rx_Main;
	assign o_Rx_Serial = i_Rx_Serial;
endmodule