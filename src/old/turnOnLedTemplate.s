// Codigo para acender um led no raspberry pi 
// faz com que o codigo na seção init seja colocado no inicio da saida
.section .init
.globl _start    

_start:
    // endereço do controlador GPIO
    ldr r0, =0x7E200000
    mov r1,#1
    // olhar no manual o pino que será utilizado e o bit que representa
    lsl r1,#18 
    str r1,[r0,#4]

    // comandos para ligar o led, desligando o pino gpio
    mov r1,#1
    lsl r1,#16
    str r1,[r0,0x28] 

    // comandos para desligar o led
    mov r2, #0x 7E20 001C
    wait1$:
        sub r2,#1
        cmp r2,#0
        bne wait1$

loop$:  
    b loop$
