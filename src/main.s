.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb

.equ RCC_BASE,        (0x40023800)
.equ RCC_AHB1ENR,     (RCC_BASE + 0x30)

.equ GPIOA_BASE,      (0x40020000)
.equ GPIOB_BASE,      (0x40020400)

.equ GPIOB_PUPDR,     (GPIOB_BASE + 0x0C)
.equ GPIOB_IDR, (GPIOB_BASE + 0x10)
.equ GPIOA_ODR, (GPIOA_BASE + 0x14)
.equ GPIOB_ODR, (GPIOB_BASE + 0x14)

.equ GPIOA_MODER,     (GPIOA_BASE + 0x00)
.equ GPIOB_MODER,     (GPIOB_BASE + 0x00)

.equ LED_PIN,         12
.equ BUTTON_PIN,      0
.equ BUZZER_PIN,      7

.global mainAssembly

.thumb_func
.type mainAssembly, %function

mainAssembly:
    @ -----------------------------
    @ Enable clock for GPIOA + GPIOB
    @ -----------------------------

    ldr r0, =RCC_AHB1ENR
    ldr r1, [r0]

    orr r1, r1, #(1 << 0)     @ GPIOA enable
    orr r1, r1, #(1 << 1)     @ GPIOB enable

    str r1, [r0]

    @ -----------------------------
    @ Configure PA12 (LED) as OUTPUT
    @ -----------------------------

    ldr r0, =GPIOA_MODER
    ldr r1, [r0]

    bic r1, r1, #(3 << (LED_PIN * 2))
    orr r1, r1, #(1 << (LED_PIN * 2))

    str r1, [r0]

    @ -----------------------------
    @ Configure PB7 (BUZZER) as OUTPUT
    @ -----------------------------

    ldr r0, =GPIOB_MODER
    ldr r1, [r0]

    bic r1, r1, #(3 << (BUZZER_PIN * 2))
    orr r1, r1, #(1 << (BUZZER_PIN * 2))

    str r1, [r0]

    @ -----------------------------
    @ Configure PB0 (BUTTON) as INPUT
    @ -----------------------------

    ldr r0, =GPIOB_MODER
    ldr r1, [r0]

    bic r1, r1, #(3 << (BUTTON_PIN * 2))   @ input mode

    str r1, [r0]

    @ -----------------------------
    @ Enable pull-up resistor for PB0
    @ -----------------------------

    ldr r0, =GPIOB_PUPDR
    ldr r1, [r0]

    bic r1, r1, #(3 << (BUTTON_PIN * 2))
    orr r1, r1, #(1 << (BUTTON_PIN * 2))   @ pull-up

    str r1, [r0]

loopAssembly:
    ldr r0, =GPIOB_IDR
    ldr r1, [r0]               

    movs r2, #(1 << BUTTON_PIN)  
    ands r2, r1, r2          
    cmp r2, #0
    bne loopAssembly             


    bl morse_code               

    b loopAssembly

morse_code:
    