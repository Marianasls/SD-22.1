// codigo usando no rasp para acender um led

main:
    lsl r1, #18 
    str r1, [r0,#4]
    mov r1, #1
    lsl r1, #6
    str r1, [r0,#40]