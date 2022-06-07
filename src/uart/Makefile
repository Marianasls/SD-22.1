# Arquivo makefile para criar o programa sbc, responsável pelo controle dos sensores

# link do arquivo objeto para criar o executavel 
sbc: sbc.o
	ld -o sbc sbc.o

# arquivo assembly para criar arquivo objeto
sbc.o: sbc.s
	as -g -o sbc.o sbc.s

# remove arquivos objetos
clean:
	rm -i *.o