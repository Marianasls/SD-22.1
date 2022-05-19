// Modulo principal do sistema
// Faz a integração entre todas as funcionalidades do sistema
// conecta a maquina de estados fpga_core com a parte da uart e a parte do sensor DHT11

module main (
  // inputs
  input        i_Clock,
  input [7:0]  i_Rx_Data, // dados recebidos pela uart
  input        i_Rx_Done, // recebimento de dados da uart concluido
  input [39:0] i_Dth_Data, // dados recebidos pela dth11
  input        i_Dth_Done, // recebimento de dados do dth11 concluido
  input        i_Dth_Error, // erro no sensor dth11
  input        i_Tx_Done, // transmissao de dados da uart concluida
  
  //outputs
  output [7:0] o_Tx_Data,
  output       o_Tx_Start,
  output       o_Dth_Start
);

//parameters

// importações
fpga_core controlInst (
  .i_Clock(i_Clock),
  .i_Rx_Data(i_Rx_Data),
  .i_Rx_Done(i_Rx_Done),
  .i_Dth_Data(i_Dth_Data),
  .i_Dth_Done(i_Dth_Done),
  .i_Dth_Error(i_Dth_Error),
  .i_Tx_Done(i_Tx_Done),
  .o_Tx_Data(o_Tx_Data),
  .o_Tx_Start(o_Tx_Start),
  .o_Dth_Start(o_Dth_Start),
);


endmodule
