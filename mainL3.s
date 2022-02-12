; Archivo:	mainL3.s
; Dispositivo:	PIC16F887
; Autor:	Jeferson Noj
; Compilador:	pic-as (v2.30), MPLABX V5.40
;
; Programa:	Contador en PORTA con TMR0, contador hexadecimal en PORTC
; Hardware:	LEDs en PORTA, botones en PORTB y 7 seg en PORTC
;
; Creado: 09 feb, 2022
; Última modificación: 12 feb, 2022

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
ORG 100h		; Posición para el código

;-------- CONFIGURACION --------
main:
    CALL    config_clk	    ; Configuración del reloj
    CALL    config_io	    ; Configuración de las entradas
    CALL    config_tmr0	    ; Configuración del TMR0
    CLRF    CONT	    ; Reinicio de contador 7 seg
    BANKSEL PORTA

loop:
    BTFSC   T0IF	    ; Evaluar bandera de overflow para TMR0
    CALL    inc_portA	    
    BTFSC   PORTB, 0	    ; Evaluar botón en bit 0 del PORTB
    CALL    inc_portC
    BTFSC   PORTB, 1	    ; Evaluar botón en bit 1 del PORTB
    CALL    dec_portC
    GOTO    loop	    ; Continuar en loop 
    
;------- SUBRUTINAS -------

inc_portA:
    CALL    reset_tmr0	    
    INCF    PORTA	    ; Aumentar contador en PORTA
    MOVF    PORTA, 0	    ; Mover valor de PORTA a W 
    XORLW   10		    ; XOR entre W y el literal 10
    BTFSC   STATUS, 2	    ; Evaluar bandera de ZERO
    CALL    inc_portD	    ; Si la bandera es 1, llamar a subrutina indicada
    RETURN

inc_portC:
    BTFSC   PORTB, 0	    ; Antirebote 
    GOTO    $-1 
    INCF    CONT	    ; Aumentar CONT
    MOVF    CONT, W	    ; Mover valor de CONT a W para buscarlo en la tabla
    CALL    tabla	    ; Buscar valor de CONT en la tabla
    MOVWF   PORTC	    ; Mover valor equivalente de CONT a PORTC
    BTFSC   CONT, 7	    ; Verificar que CONT no sea mayor a 15
    CLRF    CONT	    ; Si CONT > 15, reiniciar CONT
    RETURN

dec_portC:
    BTFSC   PORTB, 1	    ; Antirebote
    GOTO    $-1
    DECF    CONT	    ; Diminuir CONT
    MOVF    CONT, W	    ; Mover valor de CONT a W para buscarlo en la tabla
    CALL    tabla	    ; Buscar valor de CONT en la tabla
    MOVWF   PORTC	    ; Mover valor equivalente de CONT a PORTC
    BTFSC   CONT, 7	    ; Verificar que CONT no sea mayor a 15
    CLRF    CONT	    ; Si CONT > 15, reiniciar CONT
    RETURN

inc_portD:
    CLRF    PORTA	    ; Reiniciar contador en PORTA
    INCF    PORTD	    ; Aumentar contador en PORTD
    BTFSC   PORTD, 4	    ; Verificar que PORTD no sea mayor a 15
    CLRF    PORTD	    ; Si PORTD > 15, reiniciar contador en PORTD 
    MOVF    PORTD, 0	    ; Mover valor de PORTD a W
    XORWF   CONT, 0	    ; XOR entre W y valor de CONT
    BTFSC   STATUS, 2	    ; Evaluar bandera de ZERO
    CALL    alarma_part1    ; Si la bandera es 1, llamar a subrutina indicada
    RETURN

alarma_part1: 
    CLRF    PORTD	    ; Reiniciar contador en PORTD
    BTFSC   PORTE, 0	    ; Evaluar estado del bit 0 del PORTE
    CALL    alarma_part2    ; Llamar a subrutina indicada si el estado es 1
    BSF	    PORTE, 0	    ; Encender LED en PORTE
    RETURN

alarma_part2:
    BCF	    PORTE, 0	    ; Apagar LED en PORTE
    GOTO    loop	    ; Ir a loop principal

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
    CLRF    TRISA	    ; PORTA como salidas
    CLRF    TRISC	    ; PORTC como salidas
    CLRF    TRISD	    ; PORTD como salidas
    BCF	    TRISE, 0	    ; RE0 como salida
    BSF	    TRISB, 0	    ; RB0 como entrada
    BSF	    TRISB, 1	    ; RB1 como entrada

    BANKSEL PORTA
    CLRF    PORTA	    ; Limpiar PORTA
    CLRF    PORTC	    ; Limpiar PORTC
    CLRF    PORTD	    ; Limpiar PORTD
    CLRF    PORTE	    ; Limpiar PORTE
    RETURN

ORG 200h		    ; Establecer posición para la tabla
tabla:
    CLRF    PCLATH	    ; Limpiar registro PCLATH
    BSF	    PCLATH, 1	    ; Posicionar PC 
    ANDLW   0x0F	    ; AND entre W y literal 0x0F
    ADDWF   PCL		    ; ADD entre W y PCL 
    RETLW   00111111B	    ; 0	en 7 seg
    RETLW   00000110B	    ; 1 en 7 seg
    RETLW   01011011B	    ; 2 en 7 seg
    RETLW   01001111B	    ; 3 en 7 seg
    RETLW   01100110B	    ; 4 en 7 seg
    RETLW   01101101B	    ; 5 en 7 seg
    RETLW   01111101B	    ; 6 en 7 seg
    RETLW   00000111B	    ; 7 en 7 seg
    RETLW   01111111B	    ; 8 en 7 seg
    RETLW   01101111B	    ; 9 en 7 seg
    RETLW   01110111B	    ; 10 en 7 seg
    RETLW   01111100B	    ; 11 en 7 seg
    RETLW   00111001B	    ; 12 en 7 seg
    RETLW   01011110B	    ; 13 en 7 seg
    RETLW   01111001B	    ; 14 en 7 seg
    RETLW   01110001B	    ; 15 en 7 seg

END
