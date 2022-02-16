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

//--------------------------VARIABLES EN MEMORIA--------------------------------
PSECT udata_shr		    ; 
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
  
  
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
    MOVWF   W_TEMP	    ; 
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; 
    
ISR: 
    BTFSC   RBIF	    ; Fue interrupción del PORTB? No=0 Si=1
    CALL    INT_IOCRB	    ; Si -> Subrutina o macro con codigo a ejecutar
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; 
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; 
    RETFIE		    ;

//----------------------------INT SUBRUTINAS------------------------------------    
INT_IOCRB:
    BANKSEL PORTA
    BTFSS PORTB, 0
    INCF PORTA
    BTFSS PORTB, 1
    DECF PORTA
    BCF RBIF    
    RETURN 
 
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo    
    
//------------------------------MAIN CONFIG-------------------------------------
main:
    CALL IO_CONFIG
    CALL CLK_CONFIG
    CALL IOCRB_CONFIG
    CALL INT_CONFIG
    BANKSEL PORTA

LOOP:
   
    GOTO    LOOP
    
//------------------------------SUBRUTINAS--------------------------------------
IOCRB_CONFIG:
    BANKSEL IOCB
    BSF IOCB, 0
    BSF IOCB, 1
    
    BANKSEL PORTA
    MOVF PORTB, W
    BCF RBIF
    RETURN

IO_CONFIG:
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH
    
    BANKSEL TRISA
    MOVLW 0XF0
    MOVWF TRISA
    BSF TRISB, 0
    BSF TRISB, 1
    
    BCF OPTION_REG, 7
    BSF WPUB, 0
    BSF WPUB, 1
    
    BANKSEL PORTA
    CLRF PORTA
    RETURN
    
CLK_CONFIG:
    BANKSEL OSCCON		; SELECCIONAR CONFIGURADOR DEL OSCILADOR
    BSF SCS			; USAR OSCILADOR INTERNO PARA RELOJ DE SISTEMA
    BCF IRCF0			; BIT 4 DE OSCCON EN 0
    BSF IRCF1			; BIT 5 DE OSCCON EN 1
    BSF IRCF2			; BIT 6 DE OSCCON EN 1
    //OSCCON 110 -> 4MHz RELOJ INTERNO
    RETURN
    
INT_CONFIG:
    BSF GIE
    BSF RBIE
    BCF RBIF
    RETURN
END
    
