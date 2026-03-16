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

@ --- Test String to Convert to Morse ---
test_string: .asciz "H"

@ --- Morse Code Pattern Lookup (1=dot, 2=dash, 0=end) ---
morse_A:      .byte 1, 2, 0          @ .-
morse_B:      .byte 2, 1, 1, 1, 0    @ -...
morse_C:      .byte 2, 1, 2, 1, 0    @ -.-.
morse_D:      .byte 2, 1, 1, 0       @ -..
morse_E:      .byte 1, 0             @ .
morse_F:      .byte 1, 1, 2, 1, 0    @ ...-.
morse_G:      .byte 2, 2, 1, 0       @ --.-
morse_H:      .byte 1, 1, 1, 1, 0    @ ....
morse_I:      .byte 1, 1, 0          @ ..
morse_J:      .byte 1, 2, 2, 2, 0    @ .---
morse_K:      .byte 2, 1, 2, 0       @ -.-
morse_L:      .byte 1, 2, 1, 1, 0    @ .-...
morse_M:      .byte 2, 2, 0          @ --
morse_N:      .byte 2, 1, 0          @ -.
morse_O:      .byte 2, 2, 2, 0       @ ---
morse_P:      .byte 1, 2, 2, 1, 0    @ .--.
morse_Q:      .byte 2, 2, 1, 2, 0    @ --.-
morse_R:      .byte 1, 2, 1, 0       @ .-.
morse_S:      .byte 1, 1, 1, 0       @ ...
morse_T:      .byte 2, 0             @ -
morse_U:      .byte 1, 1, 2, 0       @ ..-
morse_V:      .byte 1, 1, 1, 2, 0    @ ...-
morse_W:      .byte 1, 2, 2, 0       @ .--
morse_X:      .byte 2, 1, 1, 2, 0    @ -..-
morse_Y:      .byte 2, 1, 2, 2, 0    @ -.--
morse_Z:      .byte 2, 2, 1, 1, 0    @ --...

@ --- Pointer Table for Morse Lookup (contains addresses of morse patterns) ---
.align 2
morse_table:
    .word morse_A
    .word morse_B
    .word morse_C
    .word morse_D
    .word morse_E
    .word morse_F
    .word morse_G
    .word morse_H
    .word morse_I
    .word morse_J
    .word morse_K
    .word morse_L
    .word morse_M
    .word morse_N
    .word morse_O
    .word morse_P
    .word morse_Q
    .word morse_R
    .word morse_S
    .word morse_T
    .word morse_U
    .word morse_V
    .word morse_W
    .word morse_X
    .word morse_Y
    .word morse_Z

@ --- Timing Constants (in milliseconds) ---
@ Dot duration
.equ DOT_DURATION,   200
@ Dash duration  
.equ DASH_DURATION,  600
@ Gap between elements
.equ ELEMENT_GAP,    200
@ Extra gap between characters (total 600ms including element gap)
.equ CHAR_GAP,       400
@ Extra gap between words (total 1400ms including char gap and element gap)
.equ WORD_GAP,       800

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
    
    @ --- Initialize LED and BUZZER to OFF ---
    ldr r0, =GPIOA_ODR
    ldr r1, [r0]
    ldr r2, =(1 << LED_PIN)
    bics r1, r1, r2
    str r1, [r0]
    
    ldr r0, =GPIOB_ODR
    ldr r1, [r0]
    ldr r2, =(1 << BUZZER_PIN)
    bics r1, r1, r2
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

    @ Debounce delay (20ms)
    movs r0, #20
    bl delay_ms

    bl morse_code               @ Go to morse routine if pressed
    
    b loopAssembly              @ Repeat

morse_code:
    push {r4, r5, r6, lr}
    
    @ r4 = pointer to current character in string
    @ r5 = morse pattern pointer
    @ r6 = current pattern element (1=dot, 2=dash)
    
    ldr r4, =test_string
    
morse_code_loop:
    ldrb r0, [r4]               @ Load current character
    cmp r0, #0                  @ Check for null terminator
    beq morse_code_done
    
    @ Check if space (word separator)
    cmp r0, #0x20               @ Space character
    beq morse_word_gap
    
    @ Convert character to morse pattern
    @ Input r0 = character, Output r1 = pointer to morse pattern
    bl char_to_morse_pattern
    mov r5, r1                  @ r5 = morse pattern pointer
    
    @ Output morse pattern for this character
morse_char_loop:
    ldrb r6, [r5]               @ Load morse element (1=dot, 2=dash, 0=end)
    cmp r6, #0                  @ Check for end of pattern
    beq morse_char_end
    
    @ Output the element (dot or dash)
    mov r0, r6                  @ r0 = 1 (dot) or 2 (dash)
    bl blink_element
    
    adds r5, r5, #1             @ Move to next element
    b morse_char_loop
    
morse_char_end:
    @ Add inter-character gap (400ms, plus the 200ms already waited)
    @ TEMPORARILY DISABLED FOR DEBUGGING
    
    adds r4, r4, #1             @ Move to next character
    b morse_code_loop
    
morse_word_gap:
    @ Add word gap (800ms extra, plus previous delays)
    @ TEMPORARILY DISABLED FOR DEBUGGING
    
    adds r4, r4, #1             @ Move past space character
    b morse_code_loop
    
morse_code_done:
    pop {r4, r5, r6, pc}

@ --- Delay for r0 milliseconds using busy loop ---
delay_ms:
    push {r1, r2}
    
delay_ms_loop:
    cmp r0, #0
    beq delay_ms_done
    
    @ Inner loop: ~1ms worth of cycles
    @ Approximate for STM32L031 at ~32MHz default clock
    ldr r1, =2000              @ TODO!!  Adjust this value if timing is off  
    
delay_ms_inner:
    subs r1, r1, #1
    bne delay_ms_inner
    
    subs r0, r0, #1
    b delay_ms_loop
    
delay_ms_done:
    pop {r1, r2}
    bx lr

@ --- 1ms busy-wait (for use in PWM toggling) ---
delay_1ms_busy:
    push {r1}
    ldr r1, =2000
delay_1ms_busy_loop:
    subs r1, r1, #1
    bne delay_1ms_busy_loop
    pop {r1}
    bx lr

@ --- Buzzer PWM 500Hz (1ms on, 1ms off) for r0 milliseconds ---
@ Input: r0 = duration in milliseconds
buzzer_pwm_ms:
    push {r0, r1, r2, r3, r4}
    
    @ r4 holds the buzzer pin mask for efficiency
    ldr r4, =(1 << BUZZER_PIN)
    
buzzer_pwm_loop:
    cmp r0, #0
    beq buzzer_pwm_done
    
    @ Toggle buzzer ON
    ldr r1, =GPIOB_ODR
    ldr r2, [r1]
    orrs r2, r2, r4
    str r2, [r1]
    
    @ Wait 1ms
    bl delay_1ms_busy
    
    @ Toggle buzzer OFF
    ldr r1, =GPIOB_ODR
    ldr r2, [r1]
    bics r2, r2, r4
    str r2, [r1]
    
    @ Wait 1ms
    bl delay_1ms_busy
    
    @ Decrement duration counter (each 1ms on + 1ms off = 2ms)
    subs r0, r0, #2
    bne buzzer_pwm_loop
    
buzzer_pwm_done:
    pop {r0, r1, r2, r3, r4}
    bx lr

@ --- Output single morse element (dot or dash) ---
@ Input: r0 = 1 (dot) or 2 (dash)
blink_element:
    push {r0, r1, r2, r3, r4, lr}
    
    @ Determine duration based on element type
    ldr r4, =DOT_DURATION
    cmp r0, #2                  @ Is it a dash?
    bne blink_dot_duration
    
    ldr r4, =DASH_DURATION      @ Dash = 600ms
    
blink_dot_duration:
    @ r4 now contains duration (200 or 600)
    
    @ Turn ON LED only (buzzer will be PWM controlled)
    ldr r1, =GPIOA_ODR
    ldr r2, [r1]
    ldr r3, =(1 << LED_PIN)
    orrs r2, r2, r3
    str r2, [r1]
    
    @ Start buzzer PWM for duration (buzzer_pwm_ms handles all toggling)
    mov r0, r4
    bl buzzer_pwm_ms
    
    @ Turn OFF LED
    ldr r1, =GPIOA_ODR
    ldr r2, [r1]
    ldr r3, =(1 << LED_PIN)
    bics r2, r2, r3
    str r2, [r1]
    
    @ Ensure buzzer is OFF at end
    ldr r1, =GPIOB_ODR
    ldr r2, [r1]
    ldr r3, =(1 << BUZZER_PIN)
    bics r2, r2, r3
    str r2, [r1]
    
    @ Inter-element gap (200ms)
    ldr r0, =ELEMENT_GAP
    bl delay_ms
    
    pop {r0, r1, r2, r3, r4, pc}

@ --- Convert ASCII character to morse pattern ---
@ Input: r0 = ASCII character
@ Output: r1 = pointer to morse pattern
char_to_morse_pattern:
    push {r0, r2, r3, lr}
    
    @ Convert to uppercase if lowercase
    cmp r0, #97                 @ 'a' = 97
    bcc char_is_upper
    
    subs r0, r0, #32            @ Convert lowercase to uppercase
    
char_is_upper:
    @ Check if A-Z (65-90)
    cmp r0, #65                 @ 'A' = 65
    bcc char_invalid
    
    cmp r0, #90                 @ 'Z' = 90
    bhi char_invalid
    
    @ r0 is A-Z, calculate index into pointer table
    subs r0, r0, #65            @ r0 = 0-25 for A-Z
    
    @ morse_table contains 26 word entries (4 bytes each)
    movs r2, #4                 @ Each table entry is 4 bytes
    muls r0, r0, r2             @ r0 = offset in bytes
    
    ldr r1, =morse_table
    adds r1, r1, r0             @ r1 = address of table entry
    ldr r1, [r1]                @ r1 = morse pattern address from table
    
    pop {r0, r2, r3, pc}
    
char_invalid:
    @ Default to morse_A on error
    ldr r1, =morse_A
    pop {r0, r2, r3, pc}

@ Very important for M0+ to keep constants reachable
.ltorg
.end