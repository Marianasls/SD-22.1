# Arquivo makefile para criar o programa main, responsável por ativar comunicação uart

# link do arquivo objeto para criar o executavel 
main: main.o
	ld -o main main.o

# arquivo assembly para criar arquivo objeto
main.o: main.s
	as -g -o main.o main.s

# remove arquivos objetos
clean:
	rm -i *.o