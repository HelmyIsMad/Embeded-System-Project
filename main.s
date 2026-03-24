.syntax unified
.cpu cortex-m4
.thumb
.fpu fpv4-sp-d16
.section .text
.align 2

@ Register Addresses
.equ RCC_AHB1ENR,  0x40023830

.equ GPIOA_MODER,  0x40020000
.equ GPIOA_BSRR,   0x40020018

.equ GPIOB_MODER,  0x40020400
.equ GPIOB_PUPDR,  0x4002040C
.equ GPIOB_IDR,    0x40020410
.equ GPIOB_BSRR,   0x40020418

@ Constants
.equ PA12_LED_PIN_BIT, (1 << 12)          @ PA12
.equ PA12_LED_OFF_BIT, (1 << (12 + 16))   @ PA12 Reset bit

.equ PB7_LED_PIN_BIT, (1 << 7)            @ PB7
.equ PB7_LED_OFF_BIT, (1 << (7 + 16))     @ PB7 Reset bit

.equ ONE_MS_NO_SPEED, (2000)                      @ Clock speed = 2000000/s
.equ RUN_SPEED, (2)
.equ ONE_MS, (ONE_MS_NO_SPEED / RUN_SPEED)
.equ DELAY_DOT,   (ONE_MS / 10)           
.equ DELAY_DASH,   (ONE_MS / 2)           
.equ DELAY_SEP_LETTER, (200*ONE_MS)
.equ DELAY_SEP_SIGNAL, (500*ONE_MS)

.section .data
.align 2

message: .asciz "HELLOSTM32"   @ The 'z' stands for zero-terminated

morse_a: .asciz ".-"
morse_b: .asciz "-..."
morse_c: .asciz "-.-."
morse_d: .asciz "-.."
morse_e: .asciz "."
morse_f: .asciz "..-."
morse_g: .asciz "--."
morse_h: .asciz "...."
morse_i: .asciz ".."
morse_j: .asciz ".---"
morse_k: .asciz "-.-"
morse_l: .asciz ".-.."
morse_m: .asciz "--"
morse_n: .asciz "-."
morse_o: .asciz "---"
morse_p: .asciz ".--."
morse_q: .asciz "--.-"
morse_r: .asciz ".-."
morse_s: .asciz "..."
morse_t: .asciz "-"
morse_u: .asciz "..-"
morse_v: .asciz "...-"
morse_w: .asciz ".--"
morse_x: .asciz "-..-"
morse_y: .asciz "-.--"
morse_z: .asciz "--.."
morse_1: .asciz ".----"
morse_2: .asciz "..---"
morse_3: .asciz "...--"
morse_4: .asciz "....-"
morse_5: .asciz "....."
morse_6: .asciz "-...."
morse_7: .asciz "--..."
morse_8: .asciz "---.."
morse_9: .asciz "----."
morse_0: .asciz "-----"

.section .data
.align 4
morse_table:
    .word morse_a, morse_b, morse_c, morse_d  @ A-D
    .word morse_e, morse_f, morse_g, morse_h  @ E-H
    .word morse_i, morse_j, morse_k, morse_l  @ I-L
    .word morse_m, morse_n, morse_o, morse_p  @ M-P
    .word morse_q, morse_r, morse_s, morse_t  @ Q-T
    .word morse_u, morse_v, morse_w, morse_x  @ U-X
    .word morse_y, morse_z                    @ Y-Z
    .word morse_0, morse_1, morse_2, morse_3  @ 0-3
    .word morse_4, morse_5, morse_6, morse_7  @ 4-7
    .word morse_8, morse_9                    @ 8-9
    
@ mainAssembly function
.global mainAssembly
.thumb_func
.type mainAssembly, %function
mainAssembly:
    b setup

@ setup function
setup:
    @ 1. Enable Clock for GPIOA
    LDR r0, =RCC_AHB1ENR
    LDR r1, [r0]
    MOVS r2, #1
    ORRS r1, r1, r2
    STR r1, [r0]
    
    @ 2. Enable Clock for GPIOB
    LDR r0, =RCC_AHB1ENR
    LDR r1, [r0]
    MOVS r2, #2
    ORRS r1, r1, r2
    STR r1, [r0]

    @ 3. Set PA12 to Output Mode
    LDR r0, =GPIOA_MODER
    LDR r1, [r0]
    LDR r2, =0xFCFFFFFF
    ANDS r1, r1, r2
    LDR r2, =0x01000000
    ORRS r1, r1, r2
    STR r1, [r0]

    @ 4. Set PB7 to Output Mode
    LDR r0, =GPIOB_MODER
    LDR r1, [r0]
    LDR r2, =0xFFFF3FFF
    ANDS r1, r1, r2
    LDR r2, =0x4000
    ORRS r1, r1, r2
    STR r1, [r0]

    @ 5. Set PB0 to Input Mode
    LDR r0, =GPIOB_MODER
    LDR r1, [r0]
    LDR r2, =0xFFFFFFFC
    ANDS r1, r1, r2
    STR r1, [r0]

    @ 6. Set Pull Up register for PB0
    LDR r0, =GPIOB_PUPDR
    LDR r1, [r0]
    LDR r2, =0xFFFFFFFC
    ANDS r1, r1, r2
    MOVS r2, #1
    ORRS r1, r1, r2
    STR r1, [r0]

    @ 7. load registers to be ready for loop
    ldr r0, =GPIOB_IDR
    MOVS r2, #1

    @ 8. return to main
    b loop

loop:
check_button:
    ldr r1, [r0]
    ANDS r1, r1, r2
    bne check_button

start_morse:
    ldr r1, =message @ supposed to be a pointer to the first letter in message

next_char:
    ldrb r3, [r1]
    cmp r3, #0
    beq check_button

    cmp r3, #65
    bge is_letter
    blt is_number

next_char_increment_call:
    ADDS r1, r1, #1
    B next_char

is_letter:
    SUBS r3, r3, #65
    b start_send

is_number:
    SUBS r3, r3, #48
    ADDS r3, r3, #26
    b start_send

start_send:
    LSLS r3, r3, #2       @ Multiply index by 4 (Shift left twice: 1->4, 2->8)
    LDR  r4, =morse_table @ Load the base address of the table
    LDR  r3, [r4, r3]     @ r0 = Value at (Table + Offset).

next_signal:
    LDRB r4, [r3]     @ letter '.' or '-'
    LDR r6, =DELAY_SEP_LETTER
    bl delay
    cmp r4, #0
    beq next_char_increment_call
    cmp r4, #46
    beq send_dot
    b send_dash

next_signal_increment_call:
    ADDS r3, r3, #1
    b next_signal

send_dot:
    LDR r4, =GPIOA_BSRR
    LDR r5, =(1 << 12)
    STR r5, [r4]
    LDR r4, =GPIOB_BSRR
    LDR r5, =(1 << 7)
    STR r5, [r4]
    LDR r6, =DELAY_DOT
    bl delay_buzzer
    LDR r4, =GPIOA_BSRR
    LDR r5, =(1 << (12 + 16))
    STR r5, [r4]
    LDR r4, =GPIOB_BSRR
    LDR r5, =(1 << (7 + 16))
    STR r5, [r4]
    LDR r6, =DELAY_SEP_SIGNAL
    bl delay
    b next_signal_increment_call

send_dash:
    LDR r4, =GPIOA_BSRR
    LDR r5, =(1 << 12)
    STR r5, [r4]
    LDR r4, =GPIOB_BSRR
    LDR r5, =(1 << 7)
    STR r5, [r4]
    LDR r6, =DELAY_DASH
    bl delay_buzzer
    LDR r4, =GPIOA_BSRR
    LDR r5, =(1 << (12 + 16))
    STR r5, [r4]
    LDR r4, =GPIOB_BSRR
    LDR r5, =(1 << (7 + 16))
    STR r5, [r4]
    LDR r6, =DELAY_SEP_SIGNAL
    bl delay
    b next_signal_increment_call


delay:
    SUBS r6, r6, #1
    cmp r6, #0
    bne delay
    bx lr

delay_buzzer:
    LDR r4, =GPIOB_BSRR
    LDR r5, =(1 << 7)
    STR r5, [r4]
    LDR r7, =#1000
delay_short_loop1:
    SUBS r7, r7, #1
    cmp r7, #0
    bne delay_short_loop1

    LDR r4, =GPIOB_BSRR
    LDR r5, =(1 << (7 + 16))
    STR r5, [r4]

    LDR r7, =#1000
    
delay_short_loop2:
    SUBS r7, r7, #1
    cmp r7, #0
    bne delay_short_loop2

    SUBS r6, r6, #1
    cmp r6, #0
    bne delay_buzzer
    bx lr