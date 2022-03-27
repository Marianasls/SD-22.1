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
        str     r4, [sp, 0]     @ save r4
        str     r5, [sp, 4]     @      r5
        str     fp, [sp, 8]     @      fp
        str     lr, [sp, 12]    @      lr
        add     fp, sp, 12      @ set our frame pointer
        sub     sp, sp, STACK_ARGS @ sp on 8-byte boundary

@ Open /dev/gpiomem for read/write and syncing        
        ldr     r0, deviceAddr  @ address of /dev/gpiomem
        ldr     r1, openMode    @ flags for accessing device
        bl      open
        mov     r4, r0          @ use r4 for file descriptor

@ Display file descriptor
        ldr     r0, fdMsgAddr   @ format for printf
        mov     r1, r4          @ file descriptor
        bl      printf

@ Map the GPIO registers to a virtual memory location so we can access them        
        str     r4, [sp, FILE_DESCRP_ARG] @ /dev/gpiomem file descriptor
        ldr     r0, gpio        @ address of GPIO
        str     r0, [sp, DEVICE_ARG]      @ location of GPIO
        mov     r0, NO_PREF     @ let kernel pick memory
        mov     r1, PAGE_SIZE   @ get 1 page of memory
        mov     r2, PROT_RDWR   @ read/write this memory
        mov     r3, MAP_SHARED  @ share with other processes
        @ em R4 já contem o flie decriptor
        @ não sei o que tem em r5 seria 0 ??
        bl      mmap
        mov     r5, r0          @ save virtual memory address
        
@ Display virtual address
        mov     r1, r5
        ldr     r0, memMsgAddr
        bl      printf
                
@ acho que podemos colocar o nosso codigo aqui no meio antes de desmapear a memoria virtual e fechar o arquivo

        @ colocando o pino 6 no modo output
        mov       r0, gpio        @ address of GPIO
        mov       r1, 6           @ pin 6
        mov       r2, 1           @ set pin 6 to output, 001 = 1 = output
        bl gpioPinFSelect

        @ setando o pino 6 com o valor 1
        mov       r0, gpio        @ address of GPIO
        mov       r1, 6           @ pin 6
        bl gpioPinSet

@-----------------------------------------------------------------------------
@ talvez o correto seja usar o munmap entre cada chamada de função, eu não sei mas vou supor que não vai ser necessario
@-----------------------------------------------------------------------------
        mov     r0, r5          @ memory to unmap
        mov     r1, PAGE_SIZE   @ amount we mapped
        bl      munmap          @ unmap it

        mov     r0, r4          @ /dev/gpiomem file descriptor
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
openMode:
        .word   O_FLAGS
memMsgAddr:
        .word   memMsg
gpio:
        .word   PERIPH+GPIO_OFFSET


@ gpioPinFSelect.s
@ Selects a function for a GPIO pin. Assumes that GPIO registers
@ have been mapped to programming memory.
@ Calling sequence:
@       r0 <- address of GPIO in mapped memory
@       r1 <- pin number
@       r2 <- pin function
@       bl gpioPinFSelect
@ 2017-09-30: Bob Plantz

@ Define my Raspberry Pi
        @ .cpu    cortex-a53
        @ .fpu    neon-fp-armv8
        @ .syntax unified         @ modern syntax

@ Constants for assembler
        .equ    PIN_FIELD,0b111 @ 3 bits

@ The program
        @ .text
        @ .align  2
        @ .global gpioPinFSelect
        @ .type   gpioPinFSelect, %function
gpioPinFSelect:
        sub     sp, sp, 24      @ space for saving regs
                                @ (keeping 8-byte sp align)
        str     r4, [sp, 4]     @ save r4
        str     r5, [sp, 8]     @      r5
        str     r6, [sp,12]     @      r6
        str     fp, [sp, 16]    @      fp
        str     lr, [sp, 20]    @      lr
        add     fp, sp, 20      @ set our frame pointer
        
        mov     r4, r0          @ save pointer to GPIO
        mov     r5, r1          @ save pin number
        mov     r6, r2          @ save function code
        
@ Compute address of GPFSEL register and pin field        
        mov     r3, 10          @ divisor
        udiv    r0, r5, r3      @ GPFSEL number
        
        mul     r1, r0, r3      @ compute remainder
        sub     r1, r5, r1      @     for GPFSEL pin
        
@ Set up the GPIO pin funtion register in programming memory
        lsl     r0, r0, 2       @ 4 bytes in a register
        add     r0, r4, r0      @ GPFSELn address
        ldr     r2, [r0]        @ get entire register
        
        mov     r3, r1          @ need to multiply pin
        add     r1, r1, r3, lsl 1   @    position by 3
        mov     r3, PIN_FIELD   @ gpio pin field
        lsl     r3, r3, r1      @ shift to pin position
        bic     r2, r2, r3      @ clear pin field

        lsl     r6, r6, r1      @ shift function code to pin position
        orr     r2, r2, r6      @ enter function code
        str     r2, [r0]        @ update register
        
        mov     r0, 0           @ return 0;
        ldr     r4, [sp, 4]     @ restore r4
        ldr     r5, [sp, 8]     @      r5
        ldr     r6, [sp,12]     @      r6
        ldr     fp, [sp, 16]    @      fp
        ldr     lr, [sp, 20]    @      lr
        add     sp, sp, 24      @      sp
        bx      lr              @ return


        @ gpioPinSet.s
@ Sets a GPIO pin. Assumes that GPIO registers
@ have been mapped to programming memory.
@ Calling sequence:
@       r0 <- address of GPIO in mapped memory
@       r1 <- pin number
@       bl gpioPinSet
@ 2017-09-30: Bob Plantz

@ @ Define my Raspberry Pi
@         .cpu    cortex-a53
@         .fpu    neon-fp-armv8
@         .syntax unified         @ modern syntax

@ Constants for assembler
        .equ    PIN,1           @ 1 bit for pin
        .equ    PINS_IN_REG,32
        .equ    GPSET0,0x1c     @ set register offset

@ The program
        @ .text
        @ .align  2
        @ .global gpioPinSet
        @ .type   gpioPinSet, %function
gpioPinSet:
        sub     sp, sp, 16      @ space for saving regs
        str     r4, [sp, 0]     @ save r4
        str     r5, [sp, 4]     @      r5
        str     fp, [sp, 8]     @      fp
        str     lr, [sp, 12]    @      lr
        add     fp, sp, 12      @ set our frame pointer
        
        add     r4, r0, GPSET0  @ pointer to GPSET regs.
        mov     r5, r1          @ save pin number
        
@ Compute address of GPSET register and pin field        
        mov     r3, PINS_IN_REG @ divisor
        udiv    r0, r5, r3      @ GPSET number
        mul     r1, r0, r3      @ compute remainder
        sub     r1, r5, r1      @     for relative pin position
        lsl     r0, r0, 2       @ 4 bytes in a register
        add     r0, r0, r4      @ address of GPSETn
        
@ Set up the GPIO pin funtion register in programming memory
        ldr     r2, [r0]        @ get entire register
        mov     r3, PIN         @ one pin
        lsl     r3, r3, r1      @ shift to pin position
        orr     r2, r2, r3      @ set bit
        str     r2, [r0]        @ update register
        
        mov     r0, 0           @ return 0;
        ldr     r4, [sp, 0]     @ restore r4
        ldr     r5, [sp, 4]     @      r5
        ldr     fp, [sp, 8]     @         fp
        ldr     lr, [sp, 12]    @         lr
        add     sp, sp, 16      @ restore sp
        bx      lr              @ return
