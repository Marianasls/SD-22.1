#include <stdio.h>
#include <string.h>
#include <errno.h>

#include <wiringPi.h>
#include <wiringSerial.h>

int main()
{
  int serial_port;
  int req, code_req;
  char dat;
  printf("-------------------------------------\n");
  printf("-----------------MENU----------------\n");
  printf("-------------------------------------\n");
  printf("1 - Status do Sensor.\n");
  printf("2 - Temperatura.\n");
  printf("3 - Umidade.\n");
  scanf("%d", &req);

  switch (req)
  {
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
    printf("Inválido");
    break;
  }
  if ((serial_port = serialOpen("/dev/ttyAMA0", 9600)) < 0) /* open serial port */
  {
    fprintf(stderr, "Unable to open serial device: %s\n", strerror(errno));
    return 1;
  }

  if (wiringPiSetup() == -1) /* initializes wiringPi setup */
  {
    fprintf(stdout, "Unable to start wiringPi: %s\n", strerror(errno));
    return 1;
  }

  while (1)
  {

    if (serialDataAvail(serial_port))
    {
      // dat = serialGetchar (serial_port);        /* receive character serially*/
      // printf ("%c", dat) ;
      fflush(stdout);
      serialPutchar(serial_port, code_req); // tem que ver como vai enviar o hexa/* transmit character serially on port */
    }
  }
}
