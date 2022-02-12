; Archivo:	mainL3.s
; Dispositivo:	PIC16F887
; Autor:	Jeferson Noj
; Compilador:	pic-as (v2.30), MPLABX V5.40
;
; Programa:	Contador en puerto A habilitado por TMR0
; Hardware:	LEDs en PORTA, botones en PORTB y 7 seg en PORTC
;
; Creado: 09 feb, 2022
; Última modificación:  feb, 2022

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

PSECT udata_bank0		; common memory
  CONT:		DS 1		; Contador

PSECT resVect, class=CODE, abs, delta=2
;-------- VECTOR RESET ----------
ORG 00h			; Posición 0000h para el reset
resetVec:
    PAGESEL main
    GOTO main

PSECT code, delta=2, abs
ORG 100h		;posición para el código

;-------- CONFIGURACION --------
main:
    CALL    config_clk	    ; configuración del reloj
    CALL    config_io	    ; configuración de las entradas
    CALL    config_tmr0	    ; configuración del TMR0
    CLRF    CONT	    ; Reinicio de contador
    BANKSEL PORTA

loop:
    BTFSC   T0IF	    ; evaluar bandera de overflow para TMR0
    CALL    inc_portA
    BTFSC   PORTB, 0
    CALL    inc_portC
    BTFSC   PORTB, 1
    CALL    dec_portC
    GOTO    loop
    
;------- SUBRUTINAS -------

inc_portA:
    CALL    reset_tmr0	  
    INCF    PORTA 
    MOVF    PORTA, 0
    XORLW   10
    BTFSC   STATUS, 2
    CALL    inc_portD
    RETURN

inc_portC:
    BTFSC   PORTB, 0
    GOTO    $-1 
    INCF    CONT
    MOVF    CONT, W		; Valor de contador a W para buscarlo en la tabla
    CALL    tabla		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTC		; Guardamos caracter de CONT en ASCII
    BTFSC   CONT, 7		; Verificamos que el contador no sea mayor a 15
    CLRF    CONT		; Si es mayor a 15, reiniciamos contador
    RETURN

dec_portC:
    BTFSC   PORTB, 1
    GOTO    $-1
    DECF    CONT		; Incremento de contador
    MOVF    CONT, W		; Valor de contador a W para buscarlo en la tabla
    CALL    tabla		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTC		; Guardamos caracter de CONT en ASCII
    BTFSC   CONT, 7		; Verificamos que el contador no sea mayor a 15
    CLRF    CONT		; Si es mayor a 15, reiniciamos contador
    RETURN

inc_portD:
    CLRF    PORTA
    INCF    PORTD
    BTFSC   PORTD, 4
    CLRF    PORTD
    MOVF    PORTD, 0
    XORWF   CONT, 0
    BTFSC   STATUS, 2
    CALL    alarma_part1
    RETURN

alarma_part1: 
    CLRF    PORTD
    BTFSC   PORTE, 0
    CALL    alarma_part2
    BSF	    PORTE, 0
    RETURN

alarma_part2:
    BCF	    PORTE, 0
    GOTO    loop

config_tmr0:
    BANKSEL OPTION_REG
    BCF	    T0CS	    ; Selección de reloj interno
    BCF	    PSA		    ; Asignación del Prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; Prescaler/111/1:256
    BANKSEL PORTA
    CALL    reset_tmr0
    RETURN

reset_tmr0:
    MOVLW   231
    MOVWF   TMR0
    BCF	    T0IF	    ; Apagar bandera de overflow para TMR0
    RETURN

config_clk:
    BANKSEL OSCCON
    BCF	    IRCF2	    ; IRCF/010/250kHz (frecuencia de oscilación)
    BSF	    IRCF1
    BCF	    IRCF0
    BSF	    SCS		    ; Reloj interno
    RETURN
   
config_io:
    BANKSEL ANSEL	
    CLRF    ANSEL	    ; I/O digitales
    CLRF    ANSELH
    BANKSEL TRISA
    CLRF    TRISA
    CLRF    TRISC
    CLRF    TRISD   
    BCF	    TRISE, 0
    BSF	    TRISB, 0	    ; RB0 como entrada
    BSF	    TRISB, 1	    ; RB1 como entrada

    BANKSEL PORTA
    CLRF    PORTA	    ; Limpiar puerto A
    CLRF    PORTC	    ; Limpiar puerto C
    CLRF    PORTD
    CLRF    PORTE
    RETURN

ORG 200h  
tabla:
    CLRF    PCLATH		; Limpiar registro PCLATH
    BSF	    PCLATH, 1		; Posicionamos el PC 
    ANDLW   0x0F
    ADDWF   PCL			; 
    RETLW   00111111B 
    RETLW   00000110B
    RETLW   01011011B
    RETLW   01001111B
    RETLW   01100110B
    RETLW   01101101B
    RETLW   01111101B
    RETLW   00000111B
    RETLW   01111111B
    RETLW   01101111B
    RETLW   01110111B
    RETLW   01111100B
    RETLW   00111001B
    RETLW   01011110B
    RETLW   01111001B
    RETLW   01110001B

END
