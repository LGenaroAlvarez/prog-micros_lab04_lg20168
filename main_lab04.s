; Archivo: main_lab04.s
; Dispositivo: PIC16F887
; Autor: Luis Genaro Alvarez Sulecio
; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: CONTADOR USANDO INTERRUPCIONES
; Hardware: 7 SEGMENT DISPLAY Y PUSHBUTTONS
;
; Creado: 16 feb, 2022
; �ltima modificaci�n: 19 feb, 2022

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

PROCESSOR 16F887  

//---------------------------CONFIGURACION WORD1--------------------------------
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

//---------------------------CONFIGURACION WORD2--------------------------------
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

PSECT udata_bank0
  Cont:	    DS 2
  Cont_Seg: DS 1
  Cont_Deci: DS 1
      
//----------------------------------MACRO---------------------------------------
RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0		; SELECCIONAR EL BANK 2 DEL TMR0
    MOVLW   TMR_VAR		; CARGAR EL VALOR RECIBIDO POR LA FUNCI�N AL REGISTRO W
    MOVWF   TMR0		; CARGAR EL VALOR DEL REGISTRO W AL TMR0
    BCF	    T0IF		; LIMPIAR BANDERA DEL TIMER0
    ENDM  
  
//--------------------------VARIABLES EN MEMORIA--------------------------------
PSECT udata_shr			; VARIABLES COMPARTIDAS
    W_TEMP:		DS 1	; VARIABLE TEMPORAL PARA REGISTRO W
    STATUS_TEMP:	DS 1	; VARIABLE REMPORAL PARA STATUS
  
  
 //-----------------------------Vector reset------------------------------------
 PSECT resVect, class = CODE, abs, delta = 2;
 ORG 00h			; Posici�n 0000h RESET
 resetVec:			; Etiqueta para el vector de reset
    PAGESEL main
    goto main
  
 PSECT intVect, class = CODE, abs, delta = 2, abs
 ORG 04h			; Posici�n de la interrupci�n
 
//--------------------------VECTOR INTERRUPCIONES------------------------------- 
PUSH:
    MOVWF   W_TEMP		; COLOCAR FALOR DEL REGISTRO W EN VARIABLE TEMPORAL
    SWAPF   STATUS, W		; INTERCAMBIAR STATUS CON REGISTRO W
    MOVWF   STATUS_TEMP		; CARGAR VALOR REGISTRO W A VARAIBLE TEMPORAL
    
ISR: 
    BTFSC   RBIF		; INT PORTB, SI=1 NO=0
    CALL    INT_IOCRB		; SI -> CORRER SUBRUTINA DE INTERRUPCI�N
    
    BTFSC   T0IF		; INT TMR0, SI=1 NO=0
    CALL    INT_TMR0		; SI -> CORRER SUBRUTINA DE INTERRUPCI�N
    
POP:
    SWAPF   STATUS_TEMP, W	; INTERCAMBIAR VALOR DE VARIABLE TEMPORAL DE ESTATUS CON W
    MOVWF   STATUS		; CARGAR REGISTRO W A STATUS
    SWAPF   W_TEMP, F		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO F
    SWAPF   W_TEMP, W		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO W
    RETFIE			

//----------------------------INT SUBRUTINAS------------------------------------    
INT_IOCRB:			; SUBRUTINA DE INTERRUPCI�N EN PORTB
    BANKSEL PORTA		; SELECCIONAR BANCO 0
    BTFSS   PORTB, 0		; REVISAR SI EL BIT DEL PRIMER BOTON EN RB HA CAMBIADO A 0
    INCF    PORTA		; SI HA CAMBIADO A 0 (HA SIDO PRESIONADO) INCREMENTAR CUENTA EN PORTA
    BTFSS   PORTB, 1		; REVISAR SI EL BIT DEL SEGUNDO BOTON EN RB HA CAMBIADO A 0
    DECF    PORTA		; SI HA CAMBIADO A 0 (HA SIDO PRESIONADO) DISMINUIR LA CUENTA EN PORTA
    BCF	    RBIF		; LIMPIAR LA BANDERA DE PORTB
    RETURN 

INT_TMR0:
    RESET_TMR0 178		; LLAMAR LA FUNCI�N DEL MACRO DE RESETEO DEL TMR0 CON EL VALOR CALCULADO
    INCF    Cont		; INCREMENTAR VARIABLE DE CONTADOR DE MILISEGUNDOS
    MOVF    Cont, W		; CARGAR CUENTA A REGISTRO W
    SUBLW   50			; RESTAR 50 DEL REGISTRO W PARA CONOCER SI SE HA LLEGADO A LOS 1000mS
    BTFSC   ZERO		; REVISAR SI LA BANDERA DE 0 NO ESTA ACTIVADA
    GOTO    INC_SEG		; SI SE HA ACTIVADO CAMBIAR DE SUBRUTINA
    RETURN
    
INC_SEG:
    INCF    Cont_Seg		; INCREMENTAR LA CUENTA DE SEGUNDOS
    MOVF    Cont_Seg, W		; CARGAR LA CUENTA DE SEGUNDOS AL REGISTRO W
    CLRF    Cont		; LIMPIAR LA CUENTA DE MILISEGUNDOS
    SUBLW   10			; RESTAR 10 DEL REGISTRO W PARA CONOCER SI SE HA LLEGADO A LOS 10S
    BTFSC   ZERO		; REVISAR SI LA BANDERA DE 0 NO ESTA ACTIVADA
    GOTO    INC_DECI		; SI SE HA ACTIVADO CAMBIAR DE SUBRUTINA
    RETURN
    
INC_DECI:
    INCF    Cont_Deci		; INCREMENTAR LA CUENTA DE DECENAS DE SEGUNDOS
    MOVF    Cont_Deci, W	; CARGAR DICHA CUENTA AL REGISTRO W
    CLRF    Cont_Seg		; LIMPIAR LA CUENTA DE SEGUNDOS
    SUBLW   6			; REVISAR SI SE HA LLEGADO A 60 SEGUNDOS
    BTFSC   ZERO		; SI LA BANDERA DE 0 INDICA QUE NO CONTINUAR SUBRUTINA
    GOTO    TMR0MC		; SI LA BANDERA INDICA QUE S�, INICIAR SUBRUTINA DE LIMPIEZA
    RETURN
    
TMR0MC:
    CLRF    Cont_Deci		; LIMPIAR CUENTA DE DECENAS
    CLRF    Cont_Seg		; LIMPIAR CUENTA DE SEGUNDOS
    RETURN			
    
PSECT code, delta=2, abs
ORG 100h			; posici�n 100h para el codigo    
    
//------------------------------MAIN CONFIG-------------------------------------
main:
    CALL    IO_CONFIG		; INICIAR CONFIGURACI�N DE PINES
    CALL    CLK_CONFIG		; INICIAR CONFIGURACI�N DE RELOJ
    CALL    TMR0_CONFIG
    CALL    IOCRB_CONFIG	; INICIAR CONFIGURACION DE IOC EN PORTB
    CALL    INT_CONFIG		; INICIAR CONFIGURACION DE INTERRUPCIONES
    BANKSEL PORTA

LOOP:				 
    MOVF    Cont_Seg, W		; MOVER EL VALOR DE LA CUENTA DE SEGUNDOS AL REGISTRO W
    CALL    HEX_INDEX		; LLAMAR TABLA DE INDEXADO PARA DISPLAY DE 7 SEGMENTOS
    MOVWF   PORTD	        ; CARGAR EL VALOR INDEXADO AL PORTD
    MOVF    Cont_Deci, W	; MOVER EL VALOR DE LA CUENTA DE SEGUNDOS AL REGISTRO W
    CALL    HEX_INDEX		; LLAMAR TABLA DE INDEZADO PARA DISPLAY DE 7 SEGMENTOS
    MOVWF   PORTC		; CARGAR EL VALOR INDEXADO AL PORTC
    GOTO    LOOP		
    
//------------------------------SUBRUTINAS--------------------------------------
IOCRB_CONFIG:
    BANKSEL IOCB		; SELECCIONAR BANCO DONDE SE ENCUENTRA IOCB
    BSF	    IOCB, 0		; ACTIVAR IOCB PARA PUSHBOTTON 1
    BSF	    IOCB, 1		; ACTIVAR IOCB PARA PUSHBOTTON 2
    
    BANKSEL PORTA		; SELECCIONAR EL BANCO 0
    MOVF    PORTB, W		; CARGAR EL VALOR DEL PORTB A W PARA CORREGIR MISMATCH
    BCF	    RBIF		; LIMPIAR BANDERA DE INTERRUPCI�N EN PORTB
    RETURN

IO_CONFIG:
    BANKSEL ANSEL		; SELECCIONAR EL BANCO 3
    CLRF    ANSEL		; PORTA COMO DIGITAL
    CLRF    ANSELH		; PORTB COMO DIGITAL
    
    BANKSEL TRISA		; SELECCIONAR BANCO 1
    MOVLW   0XF0		; VALOR DE ACTIVACION DE LOS PINES 3:1 COMO SALIDA EN PORTA
    MOVWF   TRISA		; ACTIVAR DICHOS PINES COMO SALIDA EN PORTA
    BSF	    TRISB, 0		; ACTIVAR EL PIN 0 DEL PORTB COMO ENTRADA
    BSF	    TRISB, 1		; ACTIVAR EL PIN 1 DEL PORTB COMO EMTRADA
    CLRF    TRISC		; ACTIVAR EL PORTC COMO SALIDA
    CLRF    TRISD		; ACTIVAR EL PORTD COMO SALIDA
    
    BCF	    OPTION_REG, 7	; LIMPIAR RBPU PARA DESBLOQUEAR EL MODO PULL-UP EN PORTB
    BSF	    WPUB, 0		; SETEAR WPUB PARA ATVICAR EL PIN 0 DEL PORTB COMO WEAK PULL-UP
    BSF	    WPUB, 1		; SETEAR WPUB PARA ACTIVAR EL PIN 1 DEL PORTB COMO WEAK PULL-UP
    
    BANKSEL PORTA		; SELECCIONAR EL BANCO 0
    CLRF    PORTA		; LIMPIAR EL REGISTRO EN PORTA
    CLRF    PORTD		; LIMPIAR EL REGISTRO EN PORTD
    CLRF    PORTC		; LIMPIAR EL REGISTRO EN PORTC
    RETURN		    
    
CLK_CONFIG:
    BANKSEL OSCCON		; SELECCIONAR CONFIGURADOR DEL OSCILADOR
    BSF	    SCS			; USAR OSCILADOR INTERNO PARA RELOJ DE SISTEMA
    BCF	    IRCF0		; BIT 4 DE OSCCON EN 0
    BSF	    IRCF1		; BIT 5 DE OSCCON EN 1
    BSF	    IRCF2		; BIT 6 DE OSCCON EN 1
    //OSCCON 110 -> 4MHz RELOJ INTERNO
    RETURN

TMR0_CONFIG:
    BANKSEL OPTION_REG		; SELECCIONAR EL BANCO DEL REGISTRO DE OPCIONES
    BCF	    T0CS		; UTILIZAR CICLO INTERNO
    BCF	    PSA			; DEDICAR EL PRESCALER AL TMR0
    BSF	    PS2			; 
    BSF	    PS1			; 
    BSF	    PS0			; COLOCAR PRESCALER EN 1:256
    
    BANKSEL TMR0		; SELECCIONAR EL BANCO DEL TIMER0
    MOVLW   178			; CARGAR VALOR AL REGISTRO W DE N = 256-[(20mS*4MHz)/(4*256)]
    MOVWF   TMR0		; CARGAR N AL TMR0
    BCF	    T0IF		; LIMPIAR BANDERA DEL TIMER0
    RETURN    
    
INT_CONFIG:
    BANKSEL INTCON
    BSF GIE			; ACTIVAR INTERRUPCIONES GLOBALES
    BSF RBIE			; ACTIVAR CAMBIO DE INTERRUPCIONES EN PORTB
    BCF RBIF			; LIMPIAR BANDERA DE CAMBIO EN PORTB POR SEGURIDAD
    BSF	T0IE			; ACTIVAR INTERRUPCIONES EN TMR0
    BCF	T0IF			; LIMPIAR BANDERA DE TMR0
    RETURN
    
//---------------------------INDICE DISPLAY 7SEG--------------------------------
PSECT HEX_INDEX, class = CODE, abs, delta = 2
ORG 200h			; POSICI�N DE LA TABLA

HEX_INDEX:
    CLRF PCLATH
    BSF PCLATH, 1		; PCLATH en 01
    ANDLW 0x0F
    ADDWF PCL			; PC = PCLATH + PCL | SUMAR W CON PCL PARA INDICAR POSICI�N EN PC
    RETLW 00111111B		; 0
    RETLW 00000110B		; 1
    RETLW 01011011B		; 2
    RETLW 01001111B		; 3
    RETLW 01100110B		; 4
    RETLW 01101101B		; 5
    RETLW 01111101B		; 6
    RETLW 00000111B		; 7
    RETLW 01111111B		; 8 
    RETLW 01101111B		; 9
    RETLW 01110111B		; A
    RETLW 01111100B		; b
    RETLW 00111001B		; C
    RETLW 01011110B		; D
    RETLW 01111001B		; C
    RETLW 01110001B		; F
END
    
