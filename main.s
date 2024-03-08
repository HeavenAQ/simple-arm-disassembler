@print macro
@ r1 = string buffer (address)
@ r2 = string length (immediate value or register)
.macro print str, len
    mov r7, #4
    mov r0, #1
    ldr r1, =\str
    mov r2, \len
    swi 0
.endm

@printeq macro
@ r1 = string buffer (address)
@ r2 = string length (immediate value or register)
.macro printeq str, len
    bne 1f
    mov r7, #4
    mov r0, #1
    ldr r1, =\str
    mov r2, \len
    swi 0
1:
.endm

@power macro
@ r0 = base
@ r1 = exp
@ r2 = result
.macro pow base, exp
    mov r0, \base
    mov r1, \exp

    @ if exp == 0, return 1
    cmp r1, #0 @ if exp == 0
    moveq r2, #1
    ble 2f
    
    @otherwise
    mov r2, r0
    sub r1, #1 @ decrement exp

1:
    @ if exp == 0, return 1
    cmp r1, #0
    ble 2f
    
    mul r2, r0, r2
    sub r1, #1 @ decrement exp
    b 1b 
    
2:
    mov r0, r2
.endm

@ itoa program
@ registers
@ r4 = outer address
@ r5 = target number 
@ r6 = current power of 10
@ r7 = init power of 10
@ r8 = counter for the actual value of the digit
@ r9 = outer address

itoa:
    push {r4-r9}
    mov r4, r1
    mov r9, r1
    mov r5, r0

    cmp r5, #0 @ if r5 == 0, print 0
    beq itoa_handle_zero

    mov r7, #9 @ init the largest power of 10
    mov r8, #0 @ init loop counter

@ get the position of the least significant digit
@ e.g. 209867295 -> 9 digits, r6 = 100000000
next_digit_pos:
    pow #10, r7 @ the result is in r0
    mov r6, r0
    cmp r6, r5
    ble get_digit @ if r6 <= r5, get the value of the digit
    sub r7, #1
    b next_digit_pos 

@ get the value of the digit
@ e.g. 
@ r6 = 100000000, r5 - r6 = 109867295, r8 = 1
@ r6 = 10000000, r5 - r6 =  9867295, r8 = 2
@ r5 < r6, print r8
get_digit:
    cmp r5, r6
    blt print_digit
    add r8, r8, #1
    sub r5, r5, r6
    b get_digit

print_digit:
    add r8, r8, #48 @ convert number to ascii
    strb r8, [r4], #1 @ store the digit

    @ for next loop
    sub r7, #1
    cmp r7, #0 @ if r7 == 0, end
    blt end_itoa

    pow #10, r7
    mov r6, r0
    mov r8, #0 @ reset counter
    b get_digit 

itoa_handle_zero:
    mov r8, #48
    strb r8, [r4], #1

end_itoa: 
    mov r8, #'\t'
    strb r8, [r4]

    mov r1, r9
    pop {r4-r9}
    bx lr

@ main program
@ registers
@ r3 = PC counter
@ r10 = start of the included file
@ r11 = end of the included file
@ r12 = current instruction
.global _start

_start:
    @ print the header
    mov r7, #4
    mov r0, #1
    ldr r1, =header
    ldr r2, =header_len
    swi 0

    @ jump to the main branch
    b main

start_include:
    .include "test.s"
end_include:

main:
    ldr r10, =start_include
    ldr r11, =end_include
    @ PC counter
    mov r3, #-4

read_loop:
    add r3, r3, #4
    @ check if it is the end of the test.s file
    cmp r10, r11
    beq end_read_loop

    @ read the next instruction
    ldr r12, [r10], #4

print_pc:
    @ convert the PC count to string
    mov r0, r3
    ldr r1, =pc_count
    bl itoa

    @ print the PC count, and then increment it
    print pc_count, #11

print_condition:
    @ print the condition
    lsr r5, r12, #28
    cmp r5, #0
    printeq eq, #5
    cmp r5, #1
    printeq ne, #5
    cmp r5, #2
    printeq cs, #5
    cmp r5, #3
    printeq cc, #5
    cmp r5, #4
    printeq mi, #5
    cmp r5, #5
    printeq pl, #5
    cmp r5, #6
    printeq vs, #5
    cmp r5, #7
    printeq vc, #5
    cmp r5, #8
    printeq hi, #5
    cmp r5, #9
    printeq ls, #5
    cmp r5, #0xa
    printeq ge, #5
    cmp r5, #0xb
    printeq lt, #5
    cmp r5, #0xc
    printeq gt, #5
    cmp r5, #0xd
    printeq le, #5
    cmp r5, #0xe
    printeq al, #5

print_instruction:
    and r5, r12, #0x0fffffff
    and r6, r12, #0x000000f0
    lsr r4, r5, #25 @ 3 bits
    lsr r5, r5, #26 @ 2 bits

    @ data transfer
    cmp r5, #1
    beq handle_data_transfer

    @ out-of-scope instruction
    cmp r4, #4
    beq handle_other
    
    @ branch instruction
    cmp r4, #5
    beq handle_branch

    @ bx instruction
    and r9, r12, #0x0ffffff0
    lsr r8, r9, #20
    cmp r8, #0x00000012
    andeq r9, r12, #0x00000ff0
    lsreq r8, r9, #8
    cmpeq r8, #0x0000000f
    andeq r9, r12, #0x000000f0
    lsreq r8, r9, #4
    cmpeq r8, #1
    beq handle_bx

    @ multiply instruction
    cmp r4, #0
    cmpeq r6, #0x00000090
    beq handle_multiply


    @ out-of-scope instruction
    cmp r4, #0
    cmpeq r6, #0x00000090
    beq handle_other 

    cmp r4, #0
    cmpeq r6, #0x00000010
    beq handle_other

    cmp r4, #0
    cmpeq r6, #0x000000d0
    beq handle_other

    cmp r4, #0
    cmpeq r6, #0x000000b0
    beq handle_other

    @ data processing instruction
    cmp r5, #0
    cmpeq r6, #0x000000f0
    beq handle_other
    bne handle_data_processing

    b handle_other

handle_data_processing:
    lsl r5, r12, #7
    lsr r5, r5, #28
    cmp r5, #0
    printeq and_txt, #5
    cmp r5, #1
    printeq eor_txt, #5
    cmp r5, #2
    printeq sub_txt, #5
    cmp r5, #3
    printeq rsb_txt, #5
    cmp r5, #4
    printeq add_txt, #5
    cmp r5, #5
    printeq adc_txt, #5
    cmp r5, #6
    printeq sbc_txt, #5
    cmp r5, #7
    printeq rsc_txt, #5
    cmp r5, #8
    printeq tst_txt, #5
    cmp r5, #9
    printeq teq_txt, #5
    cmp r5, #0xa
    printeq cmp_txt, #5
    cmp r5, #0xb
    printeq cmn_txt, #5
    cmp r5, #0xc
    printeq orr_txt, #5
    cmp r5, #0xd
    printeq mov_txt, #5
    cmp r5, #0xe
    printeq bic_txt, #5
    cmp r5, #0xf
    printeq mvn_txt, #5
    b read_loop 

handle_multiply:
    and r5, r12, #0x00200000
    lsr r5, r5, #21
    cmp r5, #0
    printeq mul_txt, #5
    cmp r5, #1
    printeq mla_txt, #5
    b read_loop

handle_data_transfer:
    and r5, r12, #0x00100000
    lsr r5, r5, #20
    cmp r5, #0
    printeq str_txt, #5
    cmp r5, #1
    printeq ldr_txt, #5
    b read_loop 

handle_branch:
    @ print instruction
    and r5, r12, #0x01000000
    lsr r5, r5, #24
    cmp r5, #0
    printeq b_txt, #3
    cmp r5, #1
    printeq bl_txt, #4

    @ get the offset
    and r5, r12, #0x00ffffff
    lsl r5, r5, #2

    @ if the branch is negative, add 0xff000000
    tst r5, #0x00800000
    bne handle_neg_offset 
    b print_offset

handle_neg_offset:
    orr r5, r5, #0xff000000
    b print_offset

print_offset:
    @ add the offset to the PC
    add r0, r5, #8
    add r0, r0, r3
    ldr r1, =pc_count
    bl itoa
    print pc_count, #11
    print linefeed, #1
    b read_loop

handle_other:
    print und_txt, #4
    b read_loop

handle_bx:
    print bx_txt, #3
    b read_loop

end_read_loop:
    mov r7, #1
    mov r0, #0
    swi 0


.data
header: .asciz "PC\tcondition\tinstruction\n"
header_len = .- header
linefeed: .asciz "\n"
pc_count: .fill 11

@ condition codes
eq: .asciz "EQ\t\t"
ne: .asciz "NE\t\t"
cs: .asciz "CS\t\t"
cc: .asciz "CC\t\t"
mi: .asciz "MI\t\t"
pl: .asciz "PL\t\t"
vs: .asciz "VS\t\t"
vc: .asciz "VC\t\t"
hi: .asciz "HI\t\t"
ls: .asciz "LS\t\t"
ge: .asciz "GE\t\t"
lt: .asciz "LT\t\t"
gt: .asciz "GT\t\t"
le: .asciz "LE\t\t"
al: .asciz "AL\t\t"

@ data processing instructions
and_txt: .asciz "AND\n"
eor_txt: .asciz "EOR\n"
sub_txt: .asciz "SUB\n"
rsb_txt: .asciz "RSB\n"
add_txt: .asciz "ADD\n"
adc_txt: .asciz "ADC\n"
sbc_txt: .asciz "SBC\n"
rsc_txt: .asciz "RSC\n"
tst_txt: .asciz "TST\n"
teq_txt: .asciz "TEQ\n"
cmp_txt: .asciz "CMP\n"
cmn_txt: .asciz "CMN\n"
orr_txt: .asciz "ORR\n"
mov_txt: .asciz "MOV\n"
bic_txt: .asciz "BIC\n"
mvn_txt: .asciz "MVN\n"
mul_txt: .asciz "MUL\n"
mla_txt: .asciz "MLA\n"

@ data transfer instructions
ldr_txt: .asciz "LDR\n"
str_txt: .asciz "STR\n"

@ branch
b_txt: .asciz "B\t"
bl_txt: .asciz "BL\t"
bx_txt: .asciz "BX\n"

@ other
und_txt: .asciz "UND\n"
