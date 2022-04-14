# Arquivo makefile para criar o programa uartgpio

# link do arquivo objeto para criar o executavel 
uartgpio: uartgpio.o
	ld -o uartgpio uartgpio.o
# gcc -o uartgpio uartgpio.o

# arquivo assembly para criar arquivo objeto
uartgpio.o: uartgpio.s
	as -o uartgpio.o uartgpio.s
# as --gstabs uartgpio.s -o uartgpio.o

# remove arquivos objetos e de backup
clean:
	rm -i *.o *~