.syntax unified
.cpu cortex-m0plus
.thumb
.section .text
.align 2

@ Register Addresses
.equ RCC_IOPENR,  0x4002102C

.equ GPIOA_MODER,  0x50000000
.equ GPIOA_BSRR,   0x50000018

.equ GPIOB_MODER,  0x50000400
.equ GPIOB_PUPDR,  0x5000040C
.equ GPIOB_IDR,    0x50000410
.equ GPIOB_BSRR,   0x50000418

@ Constants
.equ PA12_LED_PIN_BIT, (1 << 12)          @ PA12
.equ PA12_LED_OFF_BIT, (1 << (12 + 16))   @ PA12 Reset bit

.equ PB7_LED_PIN_BIT, (1 << 7)            @ PB7
.equ PB7_LED_OFF_BIT, (1 << (7 + 16))     @ PB7 Reset bit

.equ ONE_MS, (2000)                      @ Clock speed = 2000000/s
.equ DELAY_DOT,   (100*ONE_MS)           
.equ DELAY_DASH,   (300*ONE_MS)           
.equ DELAY_SEP_LETTER, (100*ONE_MS)
.equ DELAY_SEP_WORD, (300*ONE_MS)

.section .data
.align 2

message: .asciz "Hello STM32"   @ The 'z' stands for zero-terminated

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

@ mainAssembly function
.global mainAssembly
.thumb_func
mainAssembly:
    bl setup
    b loop

@ setup function
setup:
    @ 1. Enable Clock for GPIOA
    LDR r0, =RCC_IOPENR
    LDR r1, [r0]
    MOVS r2, #1
    ORRS r1, r1, r2
    STR r1, [r0]
    
    @ 2. Enable Clock for GPIOB
    LDR r0, =RCC_IOPENR
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

    @ 7. return to main
    bx lr

loop:
check_button:
    ldr r0, =GPIOB_IDR
    ldr r1, [r0]
    ldr r2, 
    

