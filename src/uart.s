@ IOmemory.s
@ Opens the /dev/gpiomem device and maps GPIO memory
@ into program virtual address space.
@ 2017-09-29: Bob Plantz 

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constants for assembler
@ The following are defined in /usr/include/asm-generic/fcntl.h:
@ Note that the values are specified in octal.
        .equ    O_RDWR,00000002   @ open for read/write
        .equ    O_DSYNC,00010000  @ synchronize virtual memory
        .equ    __O_SYNC,04000000 @      programming changes with
        .equ    O_SYNC,__O_SYNC|O_DSYNC @ I/O memory
@ The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   @ page can be read
        .equ    PROT_WRITE,0x2  @ page can be written
        .equ    MAP_SHARED,0x01 @ share changes
@ The following are defined by me:
        @ .equ    PERIPH,0x3f000000   @ RPi 2 & 3 peripherals
        .equ    PERIPH,0x20000000   @ RPi zero & 1 peripherals
        .equ    UART_OFFSET,0x201000    @ start of UART device
        .equ    O_FLAGS,O_RDWR|O_SYNC @ open file flags
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  @ Raspbian memory page
        .equ    FILE_DESCRP_ARG,0   @ file descriptor
        .equ    DEVICE_ARG,4        @ device address
        .equ    STACK_ARGS,8    @ sp already 8-byte aligned

@ Constant program data
        .section .rodata
        .align  2
device:
        .asciz  "/dev/gpiomem"
uartFile:
        .asciz  "/dev/ttyAMA0" @ ver https://www.raspberrypi.com/documentation/computers/configuration.html#primary-and-secondary-uart
fdMsg:
        .asciz  "File descriptor = %i\n"
memMsg:
        .asciz  "Using memory at %p\n"

@ The program
        .text
        .align  2
        .global main
        .type   main, %function
main:
        sub     sp, sp, 16      @ space for saving regs
        str     r4, [sp, #0]     @ save r4
        str     r5, [sp, #4]     @      r5
        str     fp, [sp, #8]     @      fp
        str     lr, [sp, #12]    @      lr
        add     fp, sp, #12      @ set our frame pointer
        sub     sp, sp, #STACK_ARGS @ sp on 8-byte boundary

@ UART        
@ Open /dev/ttyAMA0 for read/write and syncing        
        ldr     r0, #uartAddr  @ address of /dev/ttyAMA0
        ldr     r1, #openMode    @ flags for accessing device
        bl      open
        mov     r4, r0          @ use r4 for uart file descriptor

@ Display file descriptor
        ldr     r0, fdMsgAddr   @ format for printf
        mov     r1, r4          @ file descriptor
        bl      printf

@ Map the UART registers to a virtual memory location so we can access them
        mov     r0, #NO_PREF     @ let kernel pick memory
        mov     r1, #PAGE_SIZE   @ get 1 page of memory
        mov     r2, #PROT_RDWR   @ read/write this memory
        mov     r3, #MAP_SHARED  @ share with other processes
        bl      mmap
        mov     r5, r0          @ save virtual memory address
        
@ Display virtual address
        mov     r1, r5
        ldr     r0, memMsgAddr
        bl      printf

@ codigo para ativar a UART

        @ o 0º bit é UARTEN que ativa a UART
        @ o 7º bit é LBE (loopback enable)
        @ o 8º bit é TXE (transmit enable)
        @ o 9º bit é RXE (receive enable)

        mov       r0, #1           @ primeiro bit é o UARTEN  que ativa a UART quando tiver valor 1

        mov       r1, #1
        lsl       r1, #8           @ setando o bit de transmissão
        add       r0, r0, r1       @ configurando a ativação da transmissão

        mov       r1, #1
        lsl       r1, #9           @ setando o bit de recepção
        add       r0, r0, r1       @ configurando a ativação da recepção

        mov       r1, #1
        lsl       r1, #7           @ setando o bit de loopback
        add       r0, r0, r1       @ configurando a ativação do loopback

        str       r1, [r5, #48]    @ o registrador de controle da UART esta na posicao 48(0x30 em hexadecimal)
        
        mov     r0, r5          @ memory to unmap
        mov     r1, PAGE_SIZE   @ amount we mapped
        bl      munmap          @ unmap it

        mov     r0, r4          @ /dev/ttyAMA0 file descriptor
        bl      close           @ close the file

        mov     r0, 0           @ return 0;
        add     sp, sp, STACK_ARGS  @ fix sp
        ldr     r4, [sp, 0]     @ restore r4
        ldr     r5, [sp, 4]     @      r5
        ldr     fp, [sp, 8]     @         fp
        ldr     lr, [sp, 12]    @         lr
        add     sp, sp, 16      @ restore sp
        bx      lr              @ return
        
        .align  2

@ addresses of messages
fdMsgAddr:
        .word   fdMsg
deviceAddr:
        .word   device
uartAddr:
        .word   uartFile
openMode:
        .word   O_FLAGS
memMsgAddr:
        .word   memMsg
gpio:
        .word   PERIPH+GPIO_OFFSET
uart:
        .word   PERIPH+UART_OFFSET
