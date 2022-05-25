#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <unistd.h>
#include <wiringPi.h>
#include <wiringSerial.h>
#include <termios.h>

#define ADDR "/dev/ttyAMA0"
#define BAUD_RATE 9600

int read_int(int serial_port){
  char c = '';
  read(serial_port, c, sizeof(c));
  return c;
}
struct termios options ;
int init_wiringSerial() {
  int serial_port;
  if ((serial_port = serialOpen(ADDR, BAUD_RATE)) < 0) /* open serial port */
  {
    fprintf(stderr, "Unable to open serial device: %s\n", strerror(errno));
    return 1;
  }
  tcgetattr(serial_port, &options);   // Read current options
  // enable receiver, set 8 bit data, ignore control lines   
  options.c_cflag |= (CLOCAL | CREAD | CS8);    
  // disable parity generation and 2 stop bits   
  options.c_cflag &= ~(PARENB | CSTOPB);  
  // set the new port options   
  tcsetattr(serial_port, TCSANOW, &options);      
  return serial_port; 
}

int main() {
  int serial_port;
  int req=0;
  int code_req, sensor_addr;
  int integral_part, decimal_part, comando_r;
  printf("-------------------------------------\n");
  printf("-----------------MENU----------------\n");
  printf("-------------------------------------\n");
  printf("1 - Status do Sensor.\n");
  printf("2 - Temperatura.\n");
  printf("3 - Umidade.\n");
  
  while(!req) {
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
      printf("Opção invalida, tente novamente.\n");
      break;
    }
  }

  printf("Endereço do sensor (De 0 a 31): ");
  scanf("%d", &sensor_addr);

  // controle de porta serial
  serial_port = init_wiringSerial();

  if (wiringPiSetup() == -1) /* inicializa wiringPi setup */
  {
    fprintf(stdout, "Unable to start wiringPi: %s\n", strerror(errno));
    return 1;
  }

  // comando de requisição 
  fflush(stdout);
  //char addr[] = { sensor_addr };
  //write(serial_port, addr, sizeof(addr));
  //char code[] = { code_req };
  //write(serial_port, code, sizeof(code));
  serialPutchar(serial_port, sensor_addr);
  serialPutchar(serial_port, code_req);
  printf("requisição enviada\n");   

  if (code_req != 3) { // solicita dados do sensor    
    while(1) { 
      if (serialDataAvail(serial_port)) { // comando  
        printf("pronto para recebimento do comando.\n");       
        //comando_r = read_int(serial_port);       
        comando_r = serialGetchar(serial_port);       
        printf("%d\n", comando_r);   
        if(comando_r != 1 && comando_r != 2 && comando_r != 47 )
          return 0;     
        break;
      }
    }
    while(1) {
      if (serialDataAvail(serial_port)) { // integral 
        printf("pronto para recebimento do dado.\n"); 
        //integral_part = read_int(serial_port); 
        integral_part = serialGetchar(serial_port);   
        if (comando_r == 2)       
          printf("Temperatura: ");        
        else if(comando_r == 1)         
          printf("Umidade: ");        
        else
          printf("comando invalido\n");
        
        printf("%d,", integral_part);
        break;
      }
    }
    while(1) {      
      if (serialDataAvail(serial_port)) { // decimal          
        //decimal_part = read_int(serial_port);            
        decimal_part = serialGetchar(serial_port);            
        printf("%d\n", decimal_part);
        break;
      }
    }*/
  } // END IF
  else{
    while(1) {
      if(serialDataAvail(serial_port)) {
        //int status = read_int(serial_port);
        int status = serialGetchar(serial_port);
        if(status == 0)
          printf("Sensor funcionando normalmente.\n", status);
        else if(status == 31)
          printf("Sensor com problema.\n");
        else 
          printf("status recebeu: %d\n", status);
        break;
      }
    }
  }
  return 0;
}