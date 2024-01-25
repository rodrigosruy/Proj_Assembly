; --- Mapeamento de Hardware (8051) ---
    RS      equ     P1.3    ;Reg Select ligado em P1.3
    EN      equ     P1.2    ;Enable ligado em P1.2

; R2 decide se o botao foi apertado ou nao, 0= nao >0= sim
; R3 decide qual farol esta sofrendo mudancas, 0=P1.0-2 1=P1.3-5
; R4 decide se o pedestre pode atravessar, 1=sim 0=nao
; R5 decide qual cor está o farol sofrendo mudanca, 0=Vermelho 1=Verde 2=Amarelo
org 0000h
	LJMP START

org 0003h ; interrupt quando o botao eh apertado


	ACALL BOTAOAPERTADO
	RETI
org 000Bh; interrupt do temporizador
; logica para saber se troca o 1o ou 2o farol
; logica para trocar as luzes do farol selecionado
; logica para paralizar no vermelho quando o R5 = 3 e atualizar R3
; logica do R5 para mudar a cor do farol
	ACALL LOGICAFAROL
	RETI
	


org 0030h
; put data in ROM
LINHA1: ; 1a linha do display
	;LOGICA TERMINADA
	
	ATRAVESSAR:
		
		DB "PODE ATRAVESSAR"
  		DB 00h ;Marca null no fim da String
		RET
	NAOATRAVESSAR:
 		DB "NAO ATRAVESSAR "
 	 	DB 00h ;Marca null no fim da String
		RET

LINHA2:; 2a linha do display
 	; logica onde R4 = 0 ->Estado, R4=1 ->Temporaizador
		LIMPALINHA2:
			DB "             "
			DB 00h
	ESTADO: ;avisa o estado do botao
		;logica onde R2 = 0->Nao, R2=1->Sim
		NAO:
			DB "NAO APERTADO" ;aparece se o botao nao tiver sido apertado
			DB 00h
			RET
		SIM:
			DB "APERTADO!   " ;aparece se o botao tiver sido apertado
			DB 00h
			RET
	
	TEMPORIZADOR: ;temporizador do tempo que vai ficar aberto, so usado caso o farol esteja aberto
		MOV A, #40h 
  		ACALL posicionaCursor
		mov DPTR, #LIMPALINHA2
		ACALL escreveStringROM
		MOV A, #00h
		ACALL posicionaCursor
		mov DPTR, #ATRAVESSAR
		ACALL escreveStringROM
	CONTANDOTEMPO:
		MOV A, #40h 
  		ACALL posicionaCursor
		mov A, R2
		mov B, #10
		DIV AB
		ADD A, #30h
		ACALL sendCharacter
		mov A, B
		ADD A, #30h
		ACALL sendCharacter
		ACALL delay
		DJNZ R2,CONTANDOTEMPO
	TERMINADOTEMPO:
		MOV A, #00h
		ACALL posicionaCursor
		mov DPTR, #NAOATRAVESSAR
		ACALL escreveStringROM
		MOV A, #40h 
  		ACALL posicionaCursor
		mov DPTR, #NAO
		ACALL escreveStringROM
	RET

;MAIN
org 0100h
START:
mov R5, #0; variavel que diz qual a cor atual do farol a ser modificado
mov R4, #0; variavel que diz se o pedestre pode atravessar, R4=1 atravessar R4=0 nao atravessar
mov R3,#0; variavel que diz qual farol deve se modificar, R3=1 farol esquerdo R3=0 farol direito
mov R2,#0; variavel que diz se o botao foi pressionado, R2>0 pressionado R2=0 nao pressionado
SETB EA ; habilita interrupcoes externas
SETB EX0; habilita interrup 0
SETB ET0 ; habilita interrupcao 1
SETB IT0 ; interrupcao na borda de descida
mov TMOD,#1
mov TH0, #0B1h ; 20 ms no temporizador
mov TL0, #0E0h ; 45.536 microseg




LCD: ;para redesenhar o LCD no caso de mudanca
	CLR TR0;pausa o temporizador
	ACALL lcd_init
	MOV A, #00h
	ACALL posicionaCursor
	mov A, R4
	CJNE A, #0,R41 ;confirma se R4 eh ou nao 0
	R40: ; R4= 0
		mov DPTR, #NAOATRAVESSAR
		SJMP PROX1
	R41: ; R4=1
		MOV DPTR,#ATRAVESSAR          
	PROX1:
	ACALL escreveStringROM
	L2LCD:;Label para Linha 2 do LCD
	MOV A, #40h 
  	ACALL posicionaCursor
	
	CJNE R2, #0, R2Ap
	R20:;R2=0, logo botao nao pressionado
		MOV DPTR, #NAO
		SJMP FIML2LCD
	R2Ap:;R2>0, logo botao pressionado
		MOV DPTR, #SIM
	FIML2LCD:
  	ACALL escreveStringROM
	mov P1, #11110110B ;deixa apenas os vermelhos acesos
	SETB TR0;continua o temporizador

	JMP $

LOGICAFAROL:
	CLR TR0
	CJNE R3, #1, R30
	R31:
	R31V:;R3=1 e vermelho ->verde
	CJNE R5, #0,R31Ve
	mov P1, #11011110b
	R31Ve:;R3=1 e verde -> amarelo
	CJNE R5, #1,R31A
	mov P1, #11101110b
	R31A:;R3=1 e amarelo ->vermelho
	CJNE R5, #2, R3CONT
	mov P1, #11110110b
	
	
	

	SJMP R3CONT

	R30:
	R30V:; R3=0 e vermelho ->verde
	CJNE R5, #0,R30Ve
	mov P1, #11110011b

	R30Ve:; R3=0 e verde ->amarelo
	CJNE R5, #1,R30A
	mov P1, #11110101b

	R30A:; R3=0 e amarelo -> vermelho
	CJNE R5, #2, R3CONT
	mov P1, #11110110b
	SJMP R3CONT

	
	R3CONT:
	INC R5
	CJNE R5, #3, R3FIM;confirma se o farol voltou a vermelho
	mov R5,#0
	CJNE R3, #1,TROCAFAROL; momento onde eh garantido que ambos estao vermelhos
	mov R3, #0
	CJNE R2, #0, ABERTO
	SJMP R3FIM
	TROCAFAROL:
	mov R3, #1
	CJNE R2, #0, ABERTO
	SJMP R3FIM
	ABERTO:
	ACALL TEMPORIZADOR
	mov P1, #11110110b
	R3FIM:

	mov TH0, #0B1h ; 20 ms no temporizador
	mov TL0, #0E0h ; 45.536 microseg
	SETB TR0
	RET

BOTAOAPERTADO:;quando o botao eh apertado, entrar aqui
	CLR TR0
	mov R2, #15
	MOV A, #40h 
  	ACALL posicionaCursor
	MOV DPTR, #SIM
	ACALL escreveStringROM
	ACALL delay
	SETB TR0

RET

escreveStringROM:
  MOV R1, #00h
	; Inicia a escrita da String no Display LCD
loop:
  MOV A, R1
	MOVC A,@A+DPTR 	 ;l� da mem�ria de programa
	JZ finish		; if A is 0, then end of data has been reached - jump out of loop
	ACALL sendCharacter	; send data in A to LCD module
	INC R1			; point to next piece of data
   MOV A, R1
	JMP loop		; repeat
finish:
	RET
	
	






; initialise the display
; see instruction set for details
lcd_init:

	CLR RS		; clear RS - indicates that instructions are being sent to the module

; function set	
	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear	
					; function set sent for first time - tells module to go into 4-bit mode
; Why is function set high nibble sent twice? See 4-bit operation on pages 39 and 42 of HD44780.pdf.

	SETB EN		; |
	CLR EN		; | negative edge on E
					; same function set high nibble sent a second time

	SETB P1.7		; low nibble set (only P1.7 needed to be changed)

	SETB EN		; |
	CLR EN		; | negative edge on E
				; function set low nibble sent
	CALL delay		; wait for BF to clear


; entry mode set
; set to increment with no shift
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.6		; |
	SETB P1.5		; |low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear


; display on/off control
; the display is turned on, the cursor is turned on and blinking is turned on
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.7		; |
	SETB P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear
	RET


sendCharacter:
	SETB RS  		; setb RS - indicates that data is being sent to module
	MOV C, ACC.7		; |
	MOV P1.7, C			; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay			; wait for BF to clear
	CALL delay			; wait for BF to clear
	RET

;Posiciona o cursor na linha e coluna desejada.
;Escreva no Acumulador o valor de endere�o da linha e coluna.
;|--------------------------------------------------------------------------------------|
;|linha 1 | 00 | 01 | 02 | 03 | 04 |05 | 06 | 07 | 08 | 09 |0A | 0B | 0C | 0D | 0E | 0F |
;|linha 2 | 40 | 41 | 42 | 43 | 44 |45 | 46 | 47 | 48 | 49 |4A | 4B | 4C | 4D | 4E | 4F |
;|--------------------------------------------------------------------------------------|
posicionaCursor:
	CLR RS	
	SETB P1.7		    ; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay			; wait for BF to clear
	CALL delay			; wait for BF to clear
	RET


;Retorna o cursor para primeira posi��o sem limpar o display
retornaCursor:
	CLR RS	
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear
	RET


;Limpa o display
clearDisplay:
	CLR RS	
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	MOV R6, #40
	rotC:
	CALL delay		; wait for BF to clear
	DJNZ R6, rotC
	RET


delay:
	MOV R0, #0FFH
	DJNZ R0, $
	RET
