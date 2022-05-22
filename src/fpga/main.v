// Modulo principal do sistema
// Faz a integração entre todas as funcionalidades do sistema
// conecta a maquina de estados fpga_core com a parte da uart e a parte do sensor DHT11


module main (
  // inputs
  input     i_Clock,
  input  		i_Rx_Serial,
  input			i_single_req,//para realizar apenas uma requisição, ou seja não voltar ao estado inicial
  inout			dht11,
  
  output  		 o_Tx_Serial,
  output [3:0] debug_state,
  output			 debug_resetSensor,
  output			 debug_uart_signal, //para debug pode ser o rx ou tx conforme for conveniente para os testes
  output [7:0] debug_uart_data,//para debug pode ser o dado recebido ou transimitido conforme for conveniente para os testes
  output 	     rxBusy, // recebendo dados
  output 	   	 txBusy, // transmitindo dados
  output			 rxError
);

//parameters
wire txEn = 1;
wire rxEn = 1;
wire [7:0] uartOut;
wire [7:0] uartIn; 
wire [31:0] sensorData; 
wire rxDone;
wire txDone;
wire txStart;
wire sensorDone, sensorError, resetSensor;

//registradores para debug
reg [7:0] d_rx_data;
reg [7:0] d_tx_data;

assign debug_resetSensor = resetSensor;

assign debug_uart_signal = i_Rx_Serial;

//assign debug_uart_signal = o_Tx_Serial;
//assign debug_uart_data = d_tx_data;

//always @(posedge rxDone) begin
	//d_tx_data <= uartIn;
//end
	
// importações
Uart8 uartInst (
	 .clk(i_Clock),
    // rx interface
    .rx(i_Rx_Serial),
    .rxEn(rxEn),
    .out(uartOut),
    .rxDone(rxDone),
    .rxBusy(rxBusy),
    .rxErr(rxError),
    // tx interface
    .tx(o_Tx_Serial),
    .txEn(txEn),
    .txStart(txStart),
    .in(uartIn),
    .txDone(txDone),
    .txBusy(txBusy)
);

dht11  sensorInst (
    .clk(i_Clock),   
    .rst_n(resetSensor),                                   
    .dht11(dht11),   
    .data_valid(sensorData),
	 .done(sensorDone),
	 .erro(sensorError)
);

fpga_core controlInst (
  .i_Clock(i_Clock),
  .i_Rx_Data(uartOut),
  .i_Rx_Done(rxDone),
	.i_Tx_Busy(txBusy),
  .i_Dth_Data(sensorData),
  .i_Dth_Done(sensorDone),
  .i_Dth_Error(sensorError),
  .i_Tx_Done(txDone),
  .i_single_req(i_single_req),
  .o_Tx_Data(uartIn),
  .o_Tx_Start(txStart),
  .o_Dth_Start(resetSensor),
  .debug_state(debug_state),
	.debug_rx_Data(debug_uart_data)
);


endmodule