.syntax unified
.cpu cortex-m0plus
.thumb
.section .text
.align 2

@ --- Constants ---
.equ RCC_BASE,      (0x40021000)
.equ RCC_IOPENR,    (RCC_BASE + 0x2C)

.equ GPIOA_BASE,    (0x50000000)
.equ GPIOB_BASE,    (0x50000400)

.equ GPIOB_PUPDR,   (GPIOB_BASE + 0x0C)
.equ GPIOB_IDR,     (GPIOB_BASE + 0x10)
.equ GPIOA_ODR,     (GPIOA_BASE + 0x14)
.equ GPIOB_ODR,     (GPIOB_BASE + 0x14)

.equ GPIOA_MODER,   (GPIOA_BASE + 0x00)
.equ GPIOB_MODER,   (GPIOB_BASE + 0x00)

.equ LED_PIN,       12
.equ BUTTON_PIN,    0
.equ BUZZER_PIN,    7

.section .data
.align 4

.section .text
.global mainAssembly
.thumb_func
.type mainAssembly, %function

mainAssembly:
    @ --- Enable clock for GPIOA + GPIOB ---
    ldr r0, =RCC_IOPENR
    ldr r1, [r0]
    movs r2, #0x3               @ GPIOA (bit 0) + GPIOB (bit 1)
    orrs r1, r1, r2
    str r1, [r0]
    
    @ Clock synchronization delay
    nop
    nop

    @ --- Configure PA12 (LED) as OUTPUT ---
    ldr r0, =GPIOA_MODER
    ldr r1, [r0]
    ldr r2, =(3 << (LED_PIN * 2))
    bics r1, r1, r2             @ Clear bits
    ldr r2, =(1 << (LED_PIN * 2))
    orrs r1, r1, r2             @ Set to 01 (Output)
    str r1, [r0]

    @ --- Configure PB7 (BUZZER) as OUTPUT ---
    ldr r0, =GPIOB_MODER
    ldr r1, [r0]
    ldr r2, =(3 << (BUZZER_PIN * 2))
    bics r1, r1, r2
    ldr r2, =(1 << (BUZZER_PIN * 2))
    orrs r1, r1, r2
    str r1, [r0]

    @ --- Configure PB0 (BUTTON) as INPUT ---
    ldr r0, =GPIOB_MODER
    ldr r1, [r0]
    ldr r2, =(3 << (BUTTON_PIN * 2))
    bics r1, r1, r2             @ Set to 00 (Input)
    str r1, [r0]

    @ --- Enable pull-up resistor for PB0 ---
    ldr r0, =GPIOB_PUPDR
    ldr r1, [r0]
    ldr r2, =(3 << (BUTTON_PIN * 2))
    bics r1, r1, r2
    ldr r2, =(1 << (BUTTON_PIN * 2))
    orrs r1, r1, r2             @ Set to 01 (Pull-up)
    str r1, [r0]

loopAssembly:
    ldr r0, =GPIOB_IDR
    ldr r1, [r0]               

    ldr r2, =(1 << BUTTON_PIN)  
    ands r1, r1, r2             @ Result in r1, updates Z flag
    
    @ If result is NOT zero, the bit was 1 (Pull-up active, button not pressed)
    @ If result IS zero, the bit was 0 (Button pressed to GND)
    cmp r1, #0
    bne loopAssembly            @ Keep checking if not pressed

    bl morse_code               @ Go to morse routine if pressed
    b loopAssembly              @ Repeat

morse_code:
    @ Add your blinking logic here
    @ Remember to use LDR/STR on GPIOA_ODR
    bx lr

@ Very important for M0+ to keep constants reachable
.ltorg