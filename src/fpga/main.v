// Modulo principal do sistema
// Faz a integração entre todas as funcionalidades do sistema
// conecta a maquina de estados fpga_core com a parte da uart e a parte do sensor DHT11


module main (
  // inputs
  input        i_Clock,
  input  		rx,
  input  		tx,
  inout			dht11,
  //input			resetSensor,
  output 	   rxBusy, // recebendo dados
  output 	   txBusy, // transmitindo dados
  output			rxError
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
wire sensorDone, sensorError;

// importações
Uart8 uartInst (
	 .clk(i_Clock),
    // rx interface
    .rx(rx),
    .rxEn(rxEn),
    .out(uartOut),
    .rxDone(rxDone),
    .rxBusy(rxBusy),
    .rxErr(rxError),
    // tx interface
    .tx(tx),
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
  .i_Dth_Data(sensorData),
  .i_Dth_Done(sensorDone),
  .i_Dth_Error(sensorError),
  .i_Tx_Done(txDone),
  .o_Tx_Data(uartIn),
  .o_Tx_Start(txStart),
  .o_Dth_Start(resetSensor),
);


endmodule