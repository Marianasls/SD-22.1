# Arquivo makefile para criar o programa turnOnLed

# link do arquivo objeto para criar o executavel 
turnLed: turnOnLed.o
	ld -o turnOnLed turnOnLed.o
# gcc -o turnOnLed turnOnLed.o

# arquivo assembly para criar arquivo objeto
turnOnLed.o: turnOnLed.s
	as -o turnOnLed.o turnOnLed.s
# as --gstabs turnOnLed.s -o turnOnLed.o

# remove arquivos objetos e de backup
clean:
	rm -i *.o *~