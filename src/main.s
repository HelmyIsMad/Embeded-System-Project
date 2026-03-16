.syntax unified
.cpu cortex-m0plus
.thumb
.section .text
.align 2

@ --- Constants: Hardware Registers ---
.equ RCC_BASE,      0x40021000
.equ RCC_IOPENR,    (RCC_BASE + 0x2C)

.equ GPIOA_BASE,    0x50000000
.equ GPIOB_BASE,    0x50000400

.equ GPIOA_MODER,   (GPIOA_BASE + 0x00)
.equ GPIOA_BSRR,    (GPIOA_BASE + 0x18)
.equ GPIOB_MODER,   (GPIOB_BASE + 0x00)
.equ GPIOB_BSRR,    (GPIOB_BASE + 0x18)
.equ GPIOB_ODR,     (GPIOB_BASE + 0x14)

@ --- Pin Definitions ---
.equ LED_PIN,       12
.equ BUZZER_PIN,    7
.equ PA12_ON,       (1 << LED_PIN)
.equ PA12_OFF,      (1 << (LED_PIN + 16))
.equ PB7_BUZ,       (1 << BUZZER_PIN)
.equ PB7_OFF,       (1 << (BUZZER_PIN + 16))

@ --- Timing Constants (ms) ---
.equ DOT_DURATION,  200
.equ DASH_DURATION, 600
.equ ELEMENT_GAP,   200
.equ CHAR_GAP,      400
.equ WORD_GAP,      800

.section .data
.align 4

@ --- Morse Code Pattern Lookup (1=dot, 2=dash, 0=end) ---
morse_A: .byte 1, 2, 0
morse_B: .byte 2, 1, 1, 1, 0
morse_C: .byte 2, 1, 2, 1, 0
morse_D: .byte 2, 1, 1, 0
morse_E: .byte 1, 0
morse_F: .byte 1, 1, 2, 1, 0
morse_G: .byte 2, 2, 1, 0
morse_H: .byte 1, 1, 1, 1, 0
morse_I: .byte 1, 1, 0
morse_J: .byte 1, 2, 2, 2, 0
morse_K: .byte 2, 1, 2, 0
morse_L: .byte 1, 2, 1, 1, 0
morse_M: .byte 2, 2, 0
morse_N: .byte 2, 1, 0
morse_O: .byte 2, 2, 2, 0
morse_P: .byte 1, 2, 2, 1, 0
morse_Q: .byte 2, 2, 1, 2, 0
morse_R: .byte 1, 2, 1, 0
morse_S: .byte 1, 1, 1, 0
morse_T: .byte 2, 0
morse_U: .byte 1, 1, 2, 0
morse_V: .byte 1, 1, 1, 2, 0
morse_W: .byte 1, 2, 2, 0
morse_X: .byte 2, 1, 1, 2, 0
morse_Y: .byte 2, 1, 2, 2, 0
morse_Z: .byte 2, 2, 1, 1, 0

.align 2
morse_table:
    .word morse_A, morse_B, morse_C, morse_D, morse_E, morse_F, morse_G, morse_H
    .word morse_I, morse_J, morse_K, morse_L, morse_M, morse_N, morse_O, morse_P
    .word morse_Q, morse_R, morse_S, morse_T, morse_U, morse_V, morse_W, morse_X
    .word morse_Y, morse_Z

.section .text
.global mainAssembly
.thumb_func

mainAssembly:
    @ --- Enable clock for GPIOA + GPIOB ---
    ldr r0, =RCC_IOPENR
    ldr r1, [r0]
    movs r2, #0x3
    orrs r1, r1, r2
    str r1, [r0]

    @ --- Configure PA12 (LED) as OUTPUT ---
    ldr r0, =GPIOA_MODER
    ldr r1, [r0]
    ldr r2, =0xFCFFFFFF
    ands r1, r1, r2
    ldr r2, =0x01000000
    orrs r1, r1, r2
    str r1, [r0]

    @ --- Configure PB7 (BUZZER) as OUTPUT ---
    ldr r0, =GPIOB_MODER
    ldr r1, [r0]
    ldr r2, =0xFFFF3FFF
    ands r1, r1, r2
    ldr r2, =0x00004000
    orrs r1, r1, r2
    str r1, [r0]

start_prompt:
    @ Print prompt "MSG:"
    movs r0, #77; bl serial_write @ M
    movs r0, #83; bl serial_write @ S
    movs r0, #71; bl serial_write @ G
    movs r0, #58; bl serial_write @ :

get_char:
    bl serial_read
    
    @ Echo character back
    push {r0}
    bl serial_write
    pop {r0}

    @ --- KEY CHANGE HERE ---
    @ If the user hits Enter (CR or LF), go back to start_prompt to start a new line
    cmp r0, #13
    beq start_prompt
    cmp r0, #10
    beq start_prompt

    @ Check for Space (Word Gap)
    cmp r0, #32
    beq do_word_gap

    @ Play the character
    bl play_char_logic

    @ Small gap between characters
    ldr r0, =CHAR_GAP
    bl delay_ms

    @ Stay in get_char loop! (Don't jump to start_prompt yet)
    b get_char

do_word_gap:
    ldr r0, =WORD_GAP
    bl delay_ms
    b get_char

@ --- Logic to Play a Single ASCII Character ---
play_char_logic:
    push {r4, r5, lr}
    bl char_to_morse_pattern
    mov r5, r1

play_elements_loop:
    ldrb r4, [r5]
    cmp r4, #0
    beq play_char_done

    mov r0, r4
    bl blink_element

    adds r5, #1
    b play_elements_loop

play_char_done:
    pop {r4, r5, pc}

@ --- Buzzer PWM (Pitch Lowered) ---
buzzer_pwm_ms:
    push {r4, r5, lr}
    movs r4, r0                 @ Total duration in ms
    ldr r5, =GPIOB_BSRR
buzz_loop:
    cmp r4, #0
    ble buzz_done
    
    @ Pin High
    movs r0, #PB7_BUZ
    str r0, [r5]
    movs r1, #255               @ INCREASED delay for LOWER pitch
d1: subs r1, #1; bne d1
    
    @ Pin Low
    ldr r0, =PB7_OFF
    str r0, [r5]
    movs r1, #255               @ INCREASED delay for LOWER pitch
d2: subs r1, #1; bne d2
    
    subs r4, r4, #2             @ Spent ~2ms (rough estimate)
    b buzz_loop
buzz_done:
    pop {r4, r5, pc}

@ --- Output single element ---
blink_element:
    push {r4, lr}
    mov r4, r0
    
    @ LED ON
    ldr r1, =GPIOA_BSRR
    ldr r2, =PA12_ON
    str r2, [r1]

    @ Duration Selection
    ldr r0, =DOT_DURATION
    cmp r4, #2
    bne start_buzz
    ldr r0, =DASH_DURATION

start_buzz:
    bl buzzer_pwm_ms

    @ Everything OFF
    ldr r1, =GPIOA_BSRR
    ldr r2, =PA12_OFF
    str r2, [r1]
    ldr r1, =GPIOB_BSRR
    ldr r2, =PB7_OFF
    str r2, [r1]

    @ Gap between dots/dashes
    ldr r0, =ELEMENT_GAP
    bl delay_ms
    pop {r4, pc}

@ --- Helper: ASCII to Morse Pattern ---
char_to_morse_pattern:
    push {lr}
    @ To uppercase
    cmp r0, #97
    blt skip_upper
    subs r0, r0, #32
skip_upper:
    cmp r0, #65
    blt invalid
    cmp r0, #90
    bgt invalid
    subs r0, r0, #65
    lsls r0, r0, #2
    ldr r1, =morse_table
    ldr r1, [r1, r0]
    pop {pc}
invalid:
    ldr r1, =morse_E
    pop {pc}

delay_ms:
    push {r1}
d_loop:
    cmp r0, #0
    beq d_done
    ldr r1, =2000
d_inner:
    subs r1, #1
    bne d_inner
    subs r0, #1
    b d_loop
d_done:
    pop {r1}
    bx lr

.ltorg
.end