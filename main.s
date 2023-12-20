;
;	Autor:		Messan, Ekoué Andy Scott
;	Date :		20-12-2023
;	
;	Description: Assembly code that initialize the UART device and ensure 
;		that it accepts characters as input and returns them as output.
;
;	Used Device: TM4C123GH6PM


; System config UART et GPIO
SYSCTRL_BASE		EQU		0x400FE000
RCGCUART_OFFSET		EQU		0X618
SYSCTRL_RCGCUART_R	EQU		SYSCTRL_BASE + RCGCUART_OFFSET	
RCGCGPIO_OFFSET		EQU		0x608
SYSCTRL_RCGCGPIO_R	EQU		SYSCTRL_BASE + RCGCGPIO_OFFSET

; UART0 Config address
UART0_BASE			EQU		0x4000C000	
UART0_IBRD_OFFSET	EQU		0x024
UART0_IBRD_R		EQU		UART0_BASE + UART0_IBRD_OFFSET
UART0_FBRD_OFFSET	EQU		0x028
UART0_FBRD_R		EQU		UART0_BASE + UART0_FBRD_OFFSET
UART0_LCRH_OFFSET	EQU		0x02C
UART0_LCRH_R		EQU		UART0_BASE + UART0_LCRH_OFFSET
UART0_CTL_OFFSET	EQU		0x030
UART0_CTL_R			EQU		UART0_BASE + UART0_CTL_OFFSET
UART0_DR_OFFSET		EQU		0x000
UART0_DR_R			EQU		UART0_BASE + UART0_DR_OFFSET
UART0_FR_OFFSET		EQU		0x018
UART0_FR_R			EQU		UART0_BASE + UART0_FR_OFFSET
UART0_CC_OFFSET		EQU		0xFC8
UART0_CC_R			EQU		UART0_BASE + UART0_CC_OFFSET
	
; GPIOA Config address
GPIOA_BASE			EQU		0x40004000
GPIOA_DEN_OFFSET	EQU		0x51C
GPIOA_DEN_R			EQU		GPIOA_BASE + GPIOA_DEN_OFFSET
GPIOA_AFSEL_OFFET	EQU		0x420	
GPIOA_AFSEL_R		EQU		GPIOA_BASE + GPIOA_AFSEL_OFFET
GPIOA_PCTL_OFFSET	EQU		0x52C
GPIOA_PCTL_R		EQU		GPIOA_BASE + GPIOA_PCTL_OFFSET
	
; UART0 and GPIOA Values
UART0_INIT			EQU		0x1
GPIOA_INIT			EQU		0x1
PIN_A_EN			EQU		0x3
PIN_A_ALT_EN		EQU		0x3
UART_SIGN_TO_PIN_A	EQU		0x11
UART0_DIS			EQU		0x0
UART0_EN			EQU		0x301
IBRD_VAL			EQU		8			
FBRD_VAL			EQU		36
LCRH_VAL			EQU		0x60		
ZERO_VAL			EQU		0x0
UART_CC				EQU		0x0
	

					AREA |.text|,CODE,READONLY,ALIGN=2
					THUMB
					ENTRY
					EXPORT	__main
__main
			BL		UART_GPIO_Init
loop
			BL		UART_Receive
			MOV	  	R3,R2		; Store the character from R2 in R3
			BL		UART_Transmit
			B		loop
			
UART_GPIO_Init
			; Enable GPIOA CLK
			LDR		R1,=SYSCTRL_RCGCGPIO_R
			LDR		R0,[R1]
			ORR		R0,#GPIOA_INIT
			STR		R0,[R1]
			NOP
			
			; Enable UART0 Module
			LDR		R1,=SYSCTRL_RCGCUART_R
			LDR		R0,[R1]
			ORR		R0,#UART0_INIT
			STR		R0,[R1]
			NOP

			; Enable digital functions for PA0 and PA1
			LDR		R1,=GPIOA_DEN_R
			LDR		R0,[R1]
			ORR		R0,#PIN_A_EN
			STR		R0,[R1]
			
			; Enable alternate function for PA0 and PA1
			LDR		R1,=GPIOA_AFSEL_R
			LDR		R0,[R1]
			ORR		R0,#PIN_A_ALT_EN
			STR		R0,[R1]
			
			; Assign UART signals to PA0 and PA1
			LDR		R1,=GPIOA_PCTL_R
			LDR		R0,[R1]
			ORR		R0,#UART_SIGN_TO_PIN_A
			STR		R0,[R1]

			; Disable the UART
			LDR		R1,=UART0_CTL_R
			LDR		R0,[R1]
			ORR		R0,#UART0_DIS
			STR		R0,[R1]
			
			; UART0 Clock 
			LDR		R1,=UART0_CC_R
			LDR		R0,[R1]
			ORR		R0,#UART_CC
			STR		R0,[R1]

			; Write the integer portion for 115200 baud rate
			LDR		R1,=UART0_IBRD_R
			LDR		R0,[R1]
			ORR		R0,#IBRD_VAL
			STR		R0,[R1]
			
			; Write the fractional portion for 115200 baud rate
			LDR		R1,=UART0_FBRD_R
			LDR		R0,[R1]
			ORR		R0,#FBRD_VAL
			STR		R0,[R1]
			
			; Configure UART for data length of 8 bits, no parity bit, one stop bit, FIFOs disabled, no interrupts
			LDR		R1,=UART0_LCRH_R
			LDR		R0,[R1]
			ORR		R0,#LCRH_VAL
			STR		R0,[R1]

			; Enable the UART, RX and TX sections
			LDR		R1,=UART0_CTL_R
			MOV		R0,#UART0_EN
			STR		R0,[R1]
			
			BX		LR

; Used, to transmit the received data
UART_Transmit
			LDR   	R0, =UART0_BASE       ; Load the base address of UART0
UART_TX_WAIT
			
			LDR		R1, [R0, #0x18]   ; Load the value of UART0->FR into R1
			ANDS  	R1, R1, #(1 << 5)  ; Perform bitwise AND with (1 << 5)
			BNE   	UART_TX_WAIT ; Branch if the TX FIFO is not empty
			STRB  	R3, [R0, #0x0]     ; Store the character in UART0->DR
			
			BX		LR

; Used, to receive the data from UART0->DR
UART_Receive
			LDR   	R0, =UART0_BASE        ; Load the base address of UART0
UART_RX_WAIT
			
			LDR   	R1, [R0, #0x18]   ; Load the value of UART0->FR into R1
			ANDS  	R1, R1, #(1 << 4)  ; Perform bitwise AND with (1 << 4)
			BNE   	UART_RX_WAIT  ; Branch if the RX FIFO is empty
			LDRB  	R2, [R0, #0x0]     ; Load the received character from UART0->DR into R2

			BX		LR


			ALIGN
			END