; Archivo: main_lab04.s
; Dispositivo: PIC16F887
; Autor: Luis Genaro Alvarez Sulecio
; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: CONTADOR USANDO INTERRUPCIONES
; Hardware: 7 SEGMENT DISPLAY Y PUSHBUTTONS
;
; Creado: 16 feb, 2022
; Última modificación: 16 feb, 2022

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
  Cont: DS 2
  Cont_Seg: DS 1
  Cont_Deci: DS 1
      
//----------------------------------MACRO---------------------------------------
RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; 
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; 
    BCF	    T0IF	    ; 
    ENDM  
  
//--------------------------VARIABLES EN MEMORIA--------------------------------
PSECT udata_shr			; VARIABLES COMPARTIDAS
    W_TEMP:		DS 1	; VARIABLE TEMPORAL PARA REGISTRO W
    STATUS_TEMP:	DS 1	; VARIABLE REMPORAL PARA STATUS
  
  
 //-----------------------------Vector reset------------------------------------
 PSECT resVect, class = CODE, abs, delta = 2;
 ORG 00h			; Posición 0000h RESET
 resetVec:			; Etiqueta para el vector de reset
    PAGESEL main
    goto main
  
 PSECT intVect, class = CODE, abs, delta = 2, abs
 ORG 04h			; Posición de la interrupción
 
//--------------------------VECTOR INTERRUPCIONES------------------------------- 
PUSH:
    MOVWF   W_TEMP	    ; COLOCAR FALOR DEL REGISTRO W EN VARIABLE TEMPORAL
    SWAPF   STATUS, W	    ; INTERCAMBIAR STATUS CON REGISTRO W
    MOVWF   STATUS_TEMP	    ; CARGAR VALOR REGISTRO W A VARAIBLE TEMPORAL
    
ISR: 
    BTFSC   RBIF	    ; INT PORTB, SI=1 NO=0
    CALL    INT_IOCRB	    ; SI -> CORRER SUBRUTINA DE INTERRUPCIÓN
    
    BTFSC   T0IF
    CALL    INT_TMR0
    
POP:
    SWAPF   STATUS_TEMP, W  ; INTERCAMBIAR VALOR DE VARIABLE TEMPORAL DE ESTATUS CON W
    MOVWF   STATUS	    ; CARGAR REGISTRO W A STATUS
    SWAPF   W_TEMP, F	    ; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO F
    SWAPF   W_TEMP, W	    ; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO W
    RETFIE		    ;

//----------------------------INT SUBRUTINAS------------------------------------    
INT_IOCRB:		    ; SUBRUTINA DE INTERRUPCIÓN EN PORTB
    BANKSEL PORTA	    ; SELECCIONAR BANCO 0
    BTFSS   PORTB, 0	    ; REVISAR SI EL BIT DEL PRIMER BOTON EN RB HA CAMBIADO A 0
    INCF    PORTA	    ; SI HA CAMBIADO A 0 (HA SIDO PRESIONADO) INCREMENTAR CUENTA EN PORTA
    BTFSS   PORTB, 1	    ; REVISAR SI EL BIT DEL SEGUNDO BOTON EN RB HA CAMBIADO A 0
    DECF    PORTA	    ; SI HA CAMBIADO A 0 (HA SIDO PRESIONADO) DISMINUIR LA CUENTA EN PORTA
    BCF	    RBIF    
    RETURN 

INT_TMR0:
    RESET_TMR0 178	    ; 
    INCF Cont
    MOVF Cont, W
    SUBLW 50
    BTFSC ZERO
    GOTO INC_SEG
    RETURN
    
INC_SEG:
    INCF Cont_Seg
    MOVF Cont_Seg, W
    CLRF Cont
    SUBLW 10
    BTFSC ZERO
    GOTO INC_DECI
    RETURN
    
INC_DECI:
    INCF Cont_Deci
    MOVF Cont_Deci, W
    CLRF Cont_Seg
    SUBLW 6
    BTFSC ZERO
    GOTO TMR0MC
    RETURN
    
TMR0MC:
    CLRF Cont_Deci
    CLRF Cont_Seg
    RETURN
    
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo    
    
//------------------------------MAIN CONFIG-------------------------------------
main:
    CALL IO_CONFIG	    ; INICIAR CONFIGURACIÓN DE PINES
    CALL CLK_CONFIG	    ; INICIAR CONFIGURACIÓN DE RELOJ
    CALL TMR0_CONFIG
    CALL IOCRB_CONFIG	    ; INICIAR CONFIGURACION DE IOC EN PORTB
    CALL INT_CONFIG	    ; INICIAR CONFIGURACION DE INTERRUPCIONES
    BANKSEL PORTA

LOOP:			    ; 
    MOVF Cont_Seg, W	    ; MOVER EL VALOR EN PORTD (LA CUENTA) AL REGISTRO W
    CALL HEX_INDEX	    ; LLAMAR TABLA DE INDEXADO PARA DISPLAY DE 7 SEGMENTOS
    MOVWF PORTD		    ; 
    MOVF Cont_Deci, W
    CALL HEX_INDEX
    MOVWF PORTC
    GOTO    LOOP	    ; 
    
//------------------------------SUBRUTINAS--------------------------------------
IOCRB_CONFIG:
    BANKSEL IOCB	    ; SELECCIONAR BANCO DONDE SE ENCUENTRA IOCB
    BSF IOCB, 0		    ; ACTIVAR IOCB PARA PUSHBOTTON 1
    BSF IOCB, 1		    ; ACTIVAR IOCB PARA PUSHBOTTON 2
    
    BANKSEL PORTA	    ; SELECCIONAR EL BANCO 0
    MOVF PORTB, W	    ; CARGAR EL VALOR DEL PORTB A W PARA CORREGIR MISMATCH
    BCF RBIF		    ; LIMPIAR BANDERA DE INTERRUPCIÓN EN PORTB
    RETURN

IO_CONFIG:
    BANKSEL ANSEL	    ; SELECCIONAR EL BANCO 3
    CLRF ANSEL		    ; PORTA COMO DIGITAL
    CLRF ANSELH		    ; PORTB COMO DIGITAL
    
    BANKSEL TRISA	    ; SELECCIONAR BANCO 1
    MOVLW 0XF0		    ; VALOR DE ACTIVACION DE LOS PINES 3:1 COMO SALIDA EN PORTA
    MOVWF TRISA		    ; ACTIVAR DICHOS PINES COMO SALIDA EN PORTA
    BSF TRISB, 0	    ; ACTIVAR EL PIN 0 DEL PORTB COMO ENTRADA
    BSF TRISB, 1	    ; ACTIVAR EL PIN 1 DEL PORTB COMO EMTRADA
    CLRF TRISC
    CLRF TRISD
    
    BCF OPTION_REG, 7	    ; LIMPIAR RBPU PARA DESBLOQUEAR EL MODO PULL-UP EN PORTB
    BSF WPUB, 0		    ; SETEAR WPUB PARA ATVICAR EL PIN 0 DEL PORTB COMO WEAK PULL-UP
    BSF WPUB, 1		    ; SETEAR WPUB PARA ACTIVAR EL PIN 1 DEL PORTB COMO WEAK PULL-UP
    
    BANKSEL PORTA	    ; SELECCIONAR EL BANCO 0
    CLRF PORTA		    ; LIMPIAR EL REGISTRO EN PORTA
    CLRF PORTD
    CLRF PORTC
    RETURN		    
    
CLK_CONFIG:
    BANKSEL OSCCON		; SELECCIONAR CONFIGURADOR DEL OSCILADOR
    BSF SCS			; USAR OSCILADOR INTERNO PARA RELOJ DE SISTEMA
    BCF IRCF0			; BIT 4 DE OSCCON EN 0
    BSF IRCF1			; BIT 5 DE OSCCON EN 1
    BSF IRCF2			; BIT 6 DE OSCCON EN 1
    //OSCCON 110 -> 4MHz RELOJ INTERNO
    RETURN

TMR0_CONFIG:
    BANKSEL OPTION_REG	    ; 
    BCF	    T0CS	    ; 
    BCF	    PSA		    ; 
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; 
    
    BANKSEL TMR0	    ; 
    MOVLW   178
    MOVWF   TMR0	    ; 
    BCF	    T0IF	    ; 
    RETURN    
    
INT_CONFIG:
    BANKSEL INTCON
    BSF GIE		    ; ACTIVAR INTERRUPCIONES GLOBALES
    BSF RBIE		    ; ACTIVAR CAMBIO DE INTERRUPCIONES EN PORTB
    BCF RBIF		    ; LIMPIAR BANDERA DE CAMBIO EN PORTB POR SEGURIDAD
    BSF	T0IE		    ; 
    BCF	T0IF		    ; 
    RETURN
    
//---------------------------INDICE DISPLAY 7SEG--------------------------------
PSECT HEX_INDEX, class = CODE, abs, delta = 2
ORG 200h			; POSICIÓN DE LA TABLA

HEX_INDEX:
    CLRF PCLATH
    BSF PCLATH, 1		; PCLATH en 01
    ANDLW 0x0F
    ADDWF PCL			; PC = PCLATH + PCL | SUMAR W CON PCL PARA INDICAR POSICIÓN EN PC
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
    
