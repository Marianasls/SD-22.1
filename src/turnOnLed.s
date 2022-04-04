@ IOmemory.s
@ Opens the /dev/gpiomem device and maps GPIO memory
@ into program virtual address space.
@ 2017-09-29: Bob Plantz 
@ 2022-04-04: Modificado por Anderson, Esther e Mariana.

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
        .equ    PERIPH,0x20000000   @ RPi zero & 1 peripherals
        .equ    GPIO_OFFSET,0x200000  @ start of GPIO device
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

@ Open /dev/gpiomem for read/write and syncing        
        ldr     r0, #deviceAddr  @ address of /dev/gpiomem
        ldr     r1, #openMode    @ flags for accessing device
        bl      open
        mov     r4, r0          @ use r4 for file descriptor

@ Display file descriptor
        ldr     r0, fdMsgAddr   @ format for printf
        mov     r1, r4          @ file descriptor
        bl      printf

@ Map the GPIO registers to a virtual memory location so we can access them        
        str     r4, [sp, #FILE_DESCRP_ARG] @ /dev/gpiomem file descriptor
        ldr     r0, gpio        @ address of GPIO
        str     r0, [sp, #DEVICE_ARG]      @ location of GPIO
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
                
@ codigo para ativar o LED 

        @ colocando o pino 6 no modo output
        mov       r0, gpio        @ address of GPIO =0x7E200000
        mov       r1, #1           @ set pin 6 to output, 001 = 1 = output
        lsl       r1, #18
        str       r1, [r5, #0]    
        
        mov       r1, #1
        lsl       r1, #6
        @ 28 = 0x1C registrador do set, desliga o led
        @ 40 = 0x28 registrador do clear, liga o led
        str       r1, [r5, #40]   
        @str       r1, [r5, #28]   


@ addresses of messages
fdMsgAddr:
        .word   fdMsg
deviceAddr:
        .word   device
openMode:
        .word   O_FLAGS
memMsgAddr:
        .word   memMsg
gpio:
        .word   PERIPH+GPIO_OFFSET
