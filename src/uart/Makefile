# Arquivo makefile para criar o programa uart

# link do arquivo objeto para criar o executavel 
uart: uart.o
	ld -o uart uart.o
# gcc -o uart uart.o

# arquivo assembly para criar arquivo objeto
uart.o: uart.s
	as -g -o uart.o uart.s
# as --gstabs uart.s -o uart.o

# remove arquivos objetos e de backup
clean:
	rm -i *.o *~