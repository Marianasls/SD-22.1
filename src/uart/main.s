@ Problema 1 - Linguagem Assembly
@ Programa responsável por ativar a comunicação uart e enviar dados
@ Autores: Anderson, Esther, Mariana.

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constant program data
        .section .data
        .align  2

S_RDWR: 
        .word   0666
device:
        .asciz  "/dev/gpiomem"
uartFile:
        .asciz  "/dev/mem"
uartaddr:
        .word   0x20201
flags: 
        .word O_RDWR+O_SYNC+O_CLOEXEC

@ MACROS CONSTANTS
        .equ	O_RDONLY, 0
        .equ	O_WRONLY, 1
        .equ	O_CREAT,  0100
        .equ	O_RDWR,   2
        .equ	O_SYNC,   04010000
        .equ	O_CLOEXEC, 02000000
        .equ	pagelen, 4096
        .equ	setregoffset, 28
        .equ    clrregoffset, 40
        .equ	PROT_READ, 1
        .equ	PROT_WRITE, 2
        .equ	PROT_RDWR, 3
        .equ	MAP_SHARED, 1
        .equ    sys_open, 5	@ open and possibly create a file
        .equ    sys_mmap2, 192	@ map files or devices into memory
@ END MACROS CONSTANTS


@ MACROS --------------------------------------------------------------
.macro  openFile    fileName
        ldr         r0, =\fileName
        ldr         r1, =flags
	ldr 	    r1, [r1 , 0]
	ldr	    r2, =S_RDWR		@ RW access rights
        mov	    r7, #sys_open
        svc         0
.endm

.macro mapMem
	openFile	uartFile
	mov		r4, r0	@ fd for memmap

@ Setup can call the mmap2 Linux service
	ldr		r5, =#uartaddr	@ address we want / 4096
	ldr		r5, [r5 , 0]	@ load the address
	mov		r1, #pagelen	@ size of mem we want
	@mov		r2, #(PROT_READ + PROT_WRITE) @ mem protection options

	mov		r2, #PROT_RDWR  @ usar essa linha ou a linha de cima

	mov		r3, #MAP_SHARED	@ mem share options
	mov		r0, #0		@ let linux choose a virtual address
	mov		r7, #sys_mmap2	@ mmap2 service num
	svc		0		@ call service
	mov		r8, r0		@ keep the returned virtual address
.endm

@ END MACROS ----------------------------------------------------------

@ The program
        .text
        .align  2
        .global _start
_start:        
        mapMem          @ salva o endereço virtual em r8

@ codigo para ativar a UART
        @ desligando a UART
        mov       r0, #0
        str       r0, [r8, #48]    @ o registrador de controle da UART esta na posicao 48(0x30 em hexadecimal)

@ desativa FIFO
        ldr r0, [r8, #44]
        mov       r1, #1
        lsl       r1, #4          @ setando o bit que ativa a fifo
        bic       r0, r1         @ setando o bit que ativa a fifo
        @add       r0, r0, r1      @ configurando bit para desativar fifo
        str       r0, [r8, #44]

@----- UARTLCR_ LCRH Register is the line control register

        @ 1º bit é Parity enable
        @ 2º bit é Even parity select - 1 para par , 0 para impar
        @ 3º bit é Two stop bits select - usar 2 stop bits
        @ 5º e 6º bits são Word length. 11 para 8 bits, 10 para 7 bits, 01 para 6 bits, 00 para 5 bits

        mov       r0, #0
         
        mov       r1, #1        @ parametro
        lsl       r1, #1          @ setando o bit que ativa a paridade
        add       r0, r0, r1      @ configurando a ativação da paridade

        mov       r1, #1        @ parametro
        lsl       r1, #2          @ setando o bit da paridade no modo par
        add       r0, r0, r1      @ configurando a paridade no modo par

        mov       r1, #0        @ parametro
        lsl       r1, #3          @ setando o bit que ativa o 2 stop bits
        add       r0, r0, r1      @ configurando a ativação do 2 stop bits

                                @ parametro
        mov       r1, #3          @ 3 -> b11, setando o bit de word length para 8 bits
        lsl       r1, #5          @ setando o bit que ativa o 8 bits
        add       r0, r0, r1      @ configurando a ativação do 8 bits

        str       r0, [r8, #44]   @ o registrador de controle da UART esta na posicao 44(0x2C em hexadecimal)
        
@ ativa FIFO
        mov       r1, #1
        lsl       r1, #4          @ setando o bit que ativa a fifo
        add       r0, r0, r1      @ configurando bit para ativar fifo
        str       r0, [r8, #44]

@------- Register is the integer part of the baud rate divisor

        mov r0, #32           @ fiz a conta com o clock de refençia sendo 50Mhz para obter um clock de 9600 hz
        str       r0, [r8, #36]    @ o registrador de controle da UART esta na posicao 36(0x24 em hexadecimal)

@------ Register is the fractional part of the baud rate divisor
        mov r0, #5521          @ fiz a conta com o clock de refençia sendo 50Mhz para obter um clock de 9600 hz
        str       r0, [r8, #40]    @ o registrador de controle da UART esta na posicao 40(0x28 em hexadecimal)

@------- Registrador de controle da UART

        @ o 0º bit é UARTEN que ativa a UART
        @ o 7º bit é LBE (loopback enable)
        @ o 8º bit é TXE (transmit enable)
        @ o 9º bit é RXE (receive enable)

        mov       r0, #1           @ primeiro bit é o UARTEN  que ativa a UART quando tiver valor 1
        mov       r1, #1
        lsl       r1, #8           @ setando o bit de transmissão
        add       r0, r0, r1       @ configurando a ativação da transmissão

        mov       r1, #0
        lsl       r1, #9           @ setando o bit de recepção
        add       r0, r0, r1       @ configurando a ativação da recepção

        mov       r1, #1           @ parametro
        lsl       r1, #7           @ setando o bit de loopback
        add       r0, r0, r1       @ configurando a ativação do loopback

        str       r1, [r8, #48]    @ o registrador de controle da UART esta na posicao 48(0x30 em hexadecimal)
        
        @enviando um dado para teste
loop:   mov       r0, #28          @ parametro
        str       r0, [r8, #0]     @ o registrador de dados da UART esta na posicao 0(0x00 em hexadecimal)
	b	  loop

        mov R0, #0      @ Use 0 return code
        mov R7, #1      @ Command code 1 terminates
        svc 0           @ Linux command to terminate
