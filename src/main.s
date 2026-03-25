.syntax unified
.thumb
.section .text
.cpu cortex-m4

.equ RCC_BASE,      0x40023800
.equ RCC_AHB1ENR,   (RCC_BASE + 0x30)

.equ GPIOB_BASE,    0x40020400
.equ GPIOB_MODER,   (GPIOB_BASE + 0x00)
.equ GPIOB_BSRR,    (GPIOB_BASE + 0x18)
.equ GPIOB_IDR,     (GPIOB_BASE + 0x10)
.equ GPIOB_PUPDR,   (GPIOB_BASE + 0x0C)

.equ LED_PIN,       1
.equ BUZZER_PIN,    1
.equ BUTTON_PIN,    0

.equ PB1_ON,        (1 << LED_PIN)
.equ PB1_OFF,       (1 << (LED_PIN + 16))
.equ PB1_BUZ,       (1 << BUZZER_PIN)
.equ PB1_BUZ_OFF,   (1 << (BUZZER_PIN + 16))
.equ PB0_MASK,      (1 << BUTTON_PIN)

.equ RCC_AHB1ENR_GPIOBEN, (1 << 1)

.equ DOT_DURATION,  200
.equ DASH_DURATION, 600
.equ ELEMENT_GAP,   200
.equ CHAR_GAP,      400

.section .text
.align 4

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

message: .asciz "SOS"

.global main
.thumb_func
.type main, %function

main:
    @ Enable GPIOC clock
    ldr r0, =0x40023830
    ldr r1, [r0]
    orr r1, r1, #4
    str r1, [r0]

    @ Configure PC13 as output
    ldr r0, =0x40020800
    ldr r1, [r0]
    bic r1, r1, #(0b11 << 26)
    orr r1, r1, #(0b01 << 26)
    str r1, [r0]

    ldr r0, =RCC_AHB1ENR
    ldr r1, [r0]
    orr r1, r1, #RCC_AHB1ENR_GPIOBEN
    str r1, [r0]

    @ Configure PB1 as output
    ldr r0, =GPIOB_MODER
    ldr r1, [r0]
    bic r1, r1, #(0b11 << 2)
    orr r1, r1, #(0b01 << 2)
    str r1, [r0]

    @ Configure PB0 as input with pull-up
    ldr r0, =GPIOB_MODER
    ldr r1, [r0]
    bic r1, r1, #(0b11 << 0)
    str r1, [r0]

    ldr r0, =GPIOB_PUPDR
    ldr r1, [r0]
    bic r1, r1, #(0b11 << 0)
    orr r1, r1, #(0b01 << 0)
    str r1, [r0]

    @ LED off initially
    ldr r0, =GPIOB_BSRR
    ldr r1, =PB1_OFF
    str r1, [r0]

button_loop:
    @ Wait for button press
    ldr r0, =GPIOB_IDR
    ldr r1, [r0]
    tst r1, #PB0_MASK
    bne button_loop

    @ Debounce
    ldr r0, =100
    bl delay_ms

    @ Wait for release
wait_release:
    ldr r0, =GPIOB_IDR
    ldr r1, [r0]
    tst r1, #PB0_MASK
    beq wait_release

    @ Play message "SOS"
    ldr r4, =message

play_loop:
    ldrb r0, [r4]
    cmp r0, #0
    beq button_loop

    bl play_char

    ldr r0, =CHAR_GAP
    bl delay_ms

    adds r4, #1
    b play_loop

play_char:
    push {r4, r5, lr}
    bl char_to_morse
    mov r5, r1

elements_loop:
    ldrb r4, [r5]
    cmp r4, #0
    beq char_done

    mov r0, r4
    bl play_element

    adds r5, #1
    b elements_loop

char_done:
    pop {r4, r5, pc}

play_element:
    push {r4, lr}
    mov r4, r0

    @ LED + buzzer ON
    ldr r0, =GPIOB_BSRR
    ldr r1, =PB1_ON
    str r1, [r0]

    ldr r1, =DOT_DURATION
    cmp r4, #2
    bne dot_time
    ldr r1, =DASH_DURATION

dot_time:
    mov r0, r1
    bl delay_ms

    @ LED + buzzer OFF
    ldr r0, =GPIOB_BSRR
    ldr r1, =PB1_OFF
    str r1, [r0]

    ldr r0, =ELEMENT_GAP
    bl delay_ms

    pop {r4, pc}

char_to_morse:
    push {lr}
    cmp r0, #97
    blt skip_uc
    subs r0, r0, #32
skip_uc:
    cmp r0, #65
    blt bad_char
    cmp r0, #90
    bgt bad_char
    subs r0, r0, #65
    lsls r0, r0, #2
    ldr r1, =morse_table
    ldr r1, [r1, r0]
    pop {pc}
bad_char:
    ldr r1, =morse_E
    pop {pc}

delay_ms:
    push {r1}
d_loop:
    cmp r0, #0
    beq d_done
    ldr r1, =2500
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
