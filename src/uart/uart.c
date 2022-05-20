#include <stdio.h>
#include <string.h>
#include <errno.h>

#include <wiringPi.h>
#include <wiringSerial.h>
#include <termios.h>

#define ADDR "/dev/ttyAMA0"
#define BAUD_RATE 9600

struct termios options ;
void init_wiringSerial(int fd) {
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
  int req, code_req=0, sensor_addr;
  char dat;
  int integral_part, decimal_part;

  while(!code_req) {
    system("cls");
    printf("-------------------------------------\n");
    printf("-----------------MENU----------------\n");
    printf("-------------------------------------\n");
    printf("1 - Status do Sensor.\n");
    printf("2 - Temperatura.\n");
    printf("3 - Umidade.\n");
    scanf("%d", &req);
    printf("Endereço do sensor: (De 0 a 31)");
    scanf("%d", &sensor_addr);
    
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
        break;
    }
  }

  if ((serial_port = serialOpen(ADDR, BAUD_RATE)) < 0) /* open serial port */
  {
    fprintf(stderr, "Unable to open serial device: %s\n", strerror(errno));
    return 1;
  }
  // controle de porta serial
  init_wiringSerial(serial_port);

  if (wiringPiSetup() == -1) /* initializes wiringPi setup */
  {
    fprintf(stdout, "Unable to start wiringPi: %s\n", strerror(errno));
    return 1;
  }
  // comando de requisição 
  fflush(stdout);
  serialPutchar(serial_port, sensor_addr);
  serialPutchar(serial_port, code_req);

  // comando de resposta

  if (serialDataAvail(serial_port)) {
    //dat = serialGetchar (serial_port);        /* receive character serially*/
    if (code_req != 3)   // solicita dados do sensor
    {
      integral_part = read_serial_int(serial_port);
      decimal_part = read_serial_int(serial_port);
      if (code_req == 4) 
        printf("Temperatura: ");
      else 
        printf("Umidade: ");
      printf ("%d,%d\n", integral_part, decimal_part);
    }
    else { //solicita status do sensor
      int status = read_serial_int(serial_port);
      if(status == 31)
      printf ("Status do sensor: %d\n", status);
    }
  }
  
  return 0;
}
