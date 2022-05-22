#include <stdio.h>
#include <string.h>
#include <errno.h>

#include <wiringPi.h>
#include <wiringSerial.h>
#include <termios.h>

#define ADDR "/dev/ttyAMA0"
#define BAUD_RATE 9600

struct termios options ;
int init_wiringSerial() {
  if ((serial_port = serialOpen(ADDR, BAUD_RATE)) < 0) /* open serial port */
  {
    fprintf(stderr, "Unable to open serial device: %s\n", strerror(errno));
    return 1;
  }
  tcgetattr (fd, &options) ;   // Read current options
  // enable receiver, set 8 bit data, ignore control lines   
  options.c_cflag |= (CLOCAL | CREAD | CS8);    
  // disable parity generation and 2 stop bits   
  options.c_cflag &= ~(PARENB | CSTOPB);  
  // set the new port options   
  tcsetattr(fd, TCSANOW, &options);      
  return fd; 
}
/**
 * Leitura serial de inteiro
 * @param fd 
 * @return int 
 */
int read_serial_int (int fd) {     
  char ascii_int[8] = {0};     
  char c = NULL;     
  int i = 0;     

  read(fd, &c, 1);         
  //while (c != '\n')     
  while (c != ' ')  {         
    ascii_int[i++] = c;         
    read(fd, &c, 1);     
  }     
  return atoi(ascii_int); 
} 

int main() {
  int serial_port;
  int req=0;
  int code_req, sensor_addr;
  int integral_part, decimal_part;

  while(!req) {
    printf("-------------------------------------\n");
    printf("-----------------MENU----------------\n");
    printf("-------------------------------------\n");
    printf("1 - Status do Sensor.\n");
    printf("2 - Temperatura.\n");
    printf("3 - Umidade.\n");
    scanf("%d", &req);
     switch (req) {
      case 1:
        code_req = 3;
        break;
      case 2:
        code_req = 4;
        break;
      case 3:
        code_req = 5;
        break;
      default:
        printf("Inválido\n");
        system("clear");
        break;
    }
  }
  printf("Endereço do sensor (De 0 a 31): ");
  scanf("%d", &sensor_addr);

  // controle de porta serial
  int serial_port = init_wiringSerial();

  if (wiringPiSetup() == -1) /* inicializa wiringPi setup */
  {
    fprintf(stdout, "Unable to start wiringPi: %s\n", strerror(errno));
    return 1;
  }

  // comando de requisição 
  fflush(stdout);
  serialPutchar(serial_port, sensor_addr);
  fflush(stdout);
  serialPutchar(serial_port, code_req);
  printf("requisição enviada\n");   

  // comando de resposta
  while(1) {
    if (serialDataAvail(serial_port)) {
      printf("pronto para recebimento de dados.\n");
      if (code_req != 3)   // solicita dados do sensor
      {
        //integral_part = read_serial_int(serial_port);
        //decimal_part = read_serial_int(serial_port);
        char comando_r = serialGetchar(serial_port);
        integral_part = serialGetchar(serial_port);
        decimal_part = serialGetchar(serial_port);
        printf("%c \n", comando_r);
        if (code_req == 4) 
      if (code_req == 4) 
        if (code_req == 4) 
          printf("Temperatura: ");
        else
      else 
        else
          printf("Umidade: ");
        printf ("%d,%d\n", integral_part, decimal_part);
        
        if(integral_part) break;
      }
      else { //solicita status do sensor
        //int status = read_serial_int(serial_port);
        int status = serialGetchar(serial_port);
        if(status == 97)
          printf("Sensor funcionando normalmente.\n", status);
        else if(status == 98)
          printf("Sensor com problema.\n");
        else printf("recebeu: %c\n", status);
        
        if(status) break;       
      }
      
    }
  }
  return 0;