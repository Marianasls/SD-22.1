// Este modulo contém a maquina de estados que implementar toda a logica do sistema na fpga
// e segue o protocolo de comunicação definido.
  
module fpga_core
  (
   input        i_Clock,
   input [7:0]  i_Rx_Data,// dados recebidos pela uart
   input        i_Rx_Done, // recebimento de dados da uart concluido
   input [39:0] i_Dth_Data,// dados recebidos pela dth11
   input        i_Dth_Done,// recebimento de dados do dth11 concluido
   input        i_Dth_Error,// erro no sensor dth11
   input        o_Tx_Done,// transmissao de dados da uart concluida

   output [7:0] o_Tx_Data,
   output       o_Tx_Start,
   output       o_Dth_Start
   );
  
  parameter ADDRESS = 0;  // endereço que identifica esta fpga

  // estados da maquina de estados
  parameter s_IDLE          = 4'b0000;
  parameter s_RX_ADDRESS    = 4'b0001;
  parameter s_RX_ADDRESS_E  = 4'b1001;
  parameter s_RX_COMMAND    = 4'b0010;
  parameter s_RX_COMMAND_E  = 4'b1010; // comando invalido
  parameter s_DTH_START     = 4'b0011;
  parameter s_DTH_DONE      = 4'b0100;
  parameter s_TX_COMMAND    = 4'b0101;
  parameter s_TX_INTEGRAL   = 4'b0110;
  parameter s_TX_DECIMAL    = 4'b0111;
  
  // comandos de requisição validos
  parameter cr_DTH_STATUS = 8'h03;
  parameter cr_TEMPERATURE = 8'h04;
  parameter cr_HUMIDITY = 8'h05;

  // comandos de resposta
  parameter cs_DTH_ERROR = 8'h1f;
  parameter cs_DTH_OKAY = 8'h00;
  parameter cs_HUMIDITY = 8'h01;
  parameter cs_TEMPERATURE = 8'h02;

  reg [2:0]  r_state = s_IDLE;
  reg [2:0]  r_CR = 0;// comando recebido
  reg [7:0]  r_dth_integral = 0;
  reg [7:0]  r_dth_decimal = 0;
  reg [7:0]  r_tx_data = 0;
  reg        r_tx_start = 0;
  reg        r_dth_start = 0;

  always @(posedge i_Clock)
    begin
       
      case (r_state)
        s_IDLE :
          begin
            r_tx_data     <= 0;
            r_tx_start    <= 0;
            r_dth_start   <= 0;
             
            if (i_Rx_Done == 1'b1)
              begin
                if(i_Rx_Data == ADDRESS)
                  r_state   <= s_RX_ADDRESS;
                else
                  r_state   <= s_RX_ADDRESS_E;
              end
            else
              r_state <= s_IDLE;
          end // case: s_IDLE
         
        default :
          r_state <= s_IDLE;
         
      endcase
    end
 
  assign o_Tx_Data   = r_tx_data;
  assign o_Tx_Start  = r_tx_start;
  assign o_Dth_Start = r_dth_start;
   
endmodule