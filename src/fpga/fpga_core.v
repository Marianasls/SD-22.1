// Este modulo contém a maquina de estados que implementar toda a logica do sistema na fpga
// e segue o protocolo de comunicação definido.
  
module fpga_core (
   input        i_Clock,
   input [7:0]  i_Rx_Data,// dados recebidos pela uart
   input        i_Rx_Done, // recebimento de dados da uart concluido
   input [39:0] i_Dth_Data,// dados recebidos pela dth11
   input        i_Dth_Done,// recebimento de dados do dth11 concluido
   input        i_Dth_Error,// erro no sensor dth11
   input        i_Tx_Done,// transmissao de dados da uart concluida

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
  parameter cs_COMMAND_ERROR = 8'h2f;
  parameter cs_DTH_ERROR = 8'h1f;
  parameter cs_DTH_OKAY = 8'h00;
  parameter cs_HUMIDITY = 8'h01;
  parameter cs_TEMPERATURE = 8'h02;

  reg [3:0]  r_state = s_IDLE;
  reg [7:0]  r_CR = 0;// comando recebido
  reg [7:0]  r_dth_integral = 0;
  reg [7:0]  r_dth_decimal = 0;
  reg [7:0]  r_dth_status = 0;
  reg [7:0]  r_tx_data = 0;
  reg        r_tx_start = 0;
  reg        r_dth_start = 0;
  reg        r_Rx_Done = 0;
  reg 		   r_tx_done = 0;

  always @(posedge i_Clock)
    begin
       
      case (r_state)
        s_IDLE :
          begin
            r_tx_data     = 0;
            r_tx_start    = 0;
            r_dth_start   = 0;
            r_Rx_Done     = i_Rx_Done;

            if (i_Rx_Done == 1'b1)
              begin
                if(i_Rx_Data == ADDRESS)
                  r_state   <= s_RX_ADDRESS;
                else
                  r_state   <= s_RX_ADDRESS_E;
              end
          end // case: s_IDLE

        s_RX_ADDRESS :
          begin
            r_tx_data     = 0;
            r_tx_start    = 0;
            r_dth_start   = 0;
             
            if (r_Rx_Done == 1'b0 && i_Rx_Done == 1'b1)
              begin
                  r_state   <= s_RX_COMMAND;
              end

            r_Rx_Done     = i_Rx_Done;
          end // case: s_RX_ADDRESS

        s_RX_ADDRESS_E :// endereco invalido, aguarda receber a informacao do comando que deve ser ignorada
          begin
            r_tx_data     = 0;
            r_tx_start    = 0;
            r_dth_start   = 0;
             
				    if (r_Rx_Done == 1'b0 && i_Rx_Done == 1'b1)
              begin
                  r_state   <= s_IDLE;
              end

            r_Rx_Done     = i_Rx_Done;
          end // case: s_RX_ADDRESS_E
        
        s_RX_COMMAND :
          begin
            if (i_Rx_Data == cr_DTH_STATUS || i_Rx_Data == cr_TEMPERATURE || i_Rx_Data == cr_HUMIDITY)
              begin
                r_CR      = i_Rx_Data; // armazena o comando recebido, para ser usado posteriormente
                r_state   = s_DTH_START;
              end
            else
              begin
                r_state   <= s_RX_COMMAND_E;
              end
          end // case: s_RX_COMMAND

        s_RX_COMMAND_E :// comando invalido, envia resposta de erro e retorna ao estado inicial
          begin
            r_tx_data     <= cs_COMMAND_ERROR;
            r_tx_start    <= 1;
            r_state       <= s_IDLE;
          end // case: s_RX_COMMAND_E
		
        s_DTH_START: 
          begin
            r_dth_start <= 1;
            r_state <= s_DTH_DONE;
          end 
        // case: s_DTH_START
        
        s_DTH_DONE:
        // 0 - 7: temperatura integral
        // 8 - 15: temperatura decimal
        // 16 - 23: umidade integral
        // 24 - 31: umidade decimal
          begin
            if(i_Dth_Done == 1'b1) begin
              r_dth_start <= 0;
              r_state <= s_TX_COMMAND;
              r_dth_status <= cs_DTH_OKAY;
              if (r_CR == cr_TEMPERATURE) begin
                r_dth_integral <= i_Dth_Data[7:0];
                r_dth_decimal <= i_Dth_Data[15:8];
              end
              else if (r_CR == cr_HUMIDITY) begin
                r_dth_integral <= i_Dth_Data[23:16];
                r_dth_decimal <= i_Dth_Data[31:24];
              end
            end
            else if (i_Dth_ERROR == 1'b1) begin
              r_dth_start <= 0;
              r_state <= s_TX_COMMAND;7
              r_dth_status <= cs_DTH_ERROR;
            end 
          end
        // case: s_DTH_DONE
        
        s_TX_COMMAND:
          begin
            if (r_CR == cr_TEMPERATURE) begin 
              r_tx_data <= cs_TEMPERATURE;
              r_state <= s_TX_INTEGRAL;
            end
            else if (r_CR == cr_HUMIDITY) begin
              r_tx_data <= cs_HUMIDITY;
              r_state <= s_TX_INTEGRAL;
            end
            else 
              begin
                r_tx_data <= r_dth_status;
                r_state <= s_IDLE;
              end 
              
            r_TX_start	<= 1;
          end
        // case: s_TX_COMMAND
        
        s_TX_INTEGRAL:
          begin
            r_Tx_start <= 0;
            if(i_Tx_Done == 1'b1) begin
              r_tx_data <= r_dth_integral;
              r_Tx_start <= 1;
              r_state <= s_TX_DECIMAL;
            end	
            r_tx_done <= i_Tx_Done;
          end
        // case: s_TX_INTEGRAL
        
        
        s_TX_DECIMAL:
          begin
            r_TX_start	<= 0;
            if(r_tx_done == 1'b0 && i_Tx_Done == 1'b1) begin
              r_tx_data <= r_dth_decimal;
              r_Tx_start <= 1;
              r_state <= s_IDLE;
            end
            r_tx_done <= i_Tx_Done;
          end
        // case: s_TX_DECIMAL
			
		    default :
          r_state <= s_IDLE;
         
      endcase
    end
 
  assign o_Tx_Data   = r_tx_data;
  assign o_Tx_Start  = r_tx_start;
  assign o_Dth_Start = r_dth_start;
   
endmodule