! kbrd.s - tastierino numerico
!
! Giacomo Ritucci, Paolo Pennestri, 29/07/2007

	KBDSTRLN = 20
	RETCHAR = '.'
	CNLCHAR = ','

.SECT .TEXT
! void skipln (void)
! Scarta tutti i caratteri sullo standard input fino al successivo \n
! (compreso).
skipln:
	PUSH	BP
	MOV	BP, SP

	PUSH	_GETCHAR
1:	SYS
	CMPB	AL, '\n'
	JNE	1b

	MOV	SP, BP
	POP	BP
	RET


! char keypress (void)
! Simula il comportamento di un tastierino alfanumerico. Attende una serie di
! n cifre identiche terminate da un '\n' e ritorna il carattere corrispondente
! a n pressioni del tasto. In caso di errore ritorna -1.
! Es:
! "11111\n"	ritorna 1
! "777\n"	ritorna 'q'
! "12\n"	ritorna -1
keypress:
	PUSH	BP
	MOV	BP, SP

	! Variabili locali:
	! -2: carattere ritornato da _GETCHAR
	SUB	SP, 2

	PUSH	BX
	PUSH	SI

	! Lettura primo carattere, deve essere una cifra 0-9
1:	PUSH	_GETCHAR
	SYS
	CMPB	AL, '\n'	! salto delle righe vuote
	JE	1b
	CMPB	AL, RETCHAR	! carattere speciale: INVIA
	JE	9f
	CMPB	AL, CNLCHAR	! carattere speciale: ANNULLA
	JE	9f
	CMPB	AL, '0'		! carattere non valido
	JL	7f
	CMPB	AL, '9'		! carattere non valido
	JG	7f

	! Salvataggio carattere e conversione a intero.
	MOV	-2(BP), AX
	SUB	AX, 0x30

	! Posizionamento di BX all'inizio della stringa kbdstr relativa al
	! tasto premuto: BX = kbdstr + AX * KBDSTRLN
	MOV	BX, KBDSTRLN
	MUL	BX
	MOV	BX, kbdstr
	ADD	BX, AX

	MOV	SI, 0
	
	! Lettura dei caratteri successivi, fino al '\n'.
	! Se un carattere e' diverso da quello letto per primo, errore.
	! Ad ogni carattere letto, SI = (SI + 1) % KBDSTRLN
2:	SYS
	CMPB	AL, '\n'	! trovato "a capo", fine stringa
	JE	8f
	CMPB	AL, -2(BP)	! carattere uguale ai precedenti
	JNE	7f
	INC	SI
	CMP	SI, KBDSTRLN
	JNE	2b
	MOV	SI, 0
	JMP	2b

7:	MOV	AX, -1		! errore, ritorna -1
	JMP	9f
8:	MOVB	AH, 0
	MOVB	AL, (BX)(SI)	! ok, ritorna il carattere individuato

9:	ADD	SP, 2		! ripristina stack usato da _GETCHAR

	POP	SI
	POP	BX

	MOV	SP, BP
	POP	BP
	RET

! int readkbd (buf, buflen)
! Legge una stringa dal tastierino numerico e la salva nella locazione di
! memoria puntata da buf. Ritorna quando viene premuto il tasto INVIA
! (simulato con il carattere '.').  ! Ritorna il numero di caratteri letti.
readkbd:
	PUSH	BP
	MOV	BP, SP

	! Salvataggio registri usati.
	PUSH	CX
	PUSH	DI

	! Azzeramento buffer e lettura caratteri fino a ricezione INVIA o a
	! riempimento buffer.
1:	MOV	AX, 0		! terminatore
	MOV	DI, +4(BP)	! buffer
	MOV	CX, +6(BP)	! lunghezza buffer
	REP	STOSB		! azzeramento buffer
	MOV	DI, +4(BP)
	MOV	CX, +6(BP)

	! Stampa carattere digitato.
2:	PUSH	6
	PUSH	+4(BP)
	CALL	drwmsg
	ADD	SP, 4

	CALL	keypress

	! Sostituzione codice di INVIO con terminatore.
	CMPB	AL, RETCHAR
	JNE	3f
	CALL	skipln		! fine input, flush stdin
	MOV	AX, 0

	! Salvataggio carattere nel buffer.
3:	STOSB
	PUSH	AX
	POP	AX

	! Ricevuto un ANNULLA, tutto da rifare.
	CMPB	AL, CNLCHAR
	JE	1b

	! Terminatore o buffer pieno, fine ciclo.
	CMPB	AL, 0
	LOOPNE	2b
	
	! Se s'e' riempito il buffer, sostituzione ultimo carattere con
	! terminatore.
	MOV	AX, 0
	DEC	DI
	STOSB

	! Calcolo numero di caratteri letti per valore di ritorno.
4:	MOV	AX, +6(BP)
	SUB	AX, CX

	! Ripristino registri usati.
	POP	DI
	POP	CX

	MOV	SP, BP
	POP	BP
	RET

! int readchc (n)
! Legge da tastierino un numero che rappresenta la scelta di un menu.
! Non ritorna finche' l'input da tastierino non rappresenta un numero
! compreso tra 0 e n.
readchc:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX		! salvataggio

	! Lettura input.
1:	MOV	AX, 0
	PUSH	_GETCHAR
	SYS
	ADD	SP, 2

	! Scarto di eventuali caratteri fino al '\n'
	MOV	BX, AX		! salvataggio carattere letto
	CALL	skipln

	! Conversione a intero e controllo.
	SUB	BX, '0'
	CMP	BX, 0
	JL	8f		! errore
	CMP	BX, +4(BP)	! n
	JG	8f		! errore
	JMP	9f

	! Errore input: minore di zero oppure maggiore del numero di scelte
	! del menu. Stampa un messaggio di errore e salta a richiedere l'input
	! nuovamente.
8:	PUSH	6
	PUSH	errchc
	CALL	drwmsg
	ADD	SP, 4
	JMP	1b

9:	MOV	AX, BX		! ritorna scelta effettuata
	POP	BX		! ripristino

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA
kbdstr:
	.ASCII	"0_0_0_0_0_0_0_0_0_0_"
	.ASCII	"11111111111111111111"
	.ASCII	"2abc2abc2abc2abc2abc"
	.ASCII	"3def3def3def3def3def"
	.ASCII	"4ghi4ghi4ghi4ghi4ghi"
	.ASCII	"5jkl5jkl5jkl5jkl5jkl"
	.ASCII	"6mno6mno6mno6mno6mno"
	.ASCII	"7pqrs7pqrs7pqrs7pqrs"
	.ASCII	"8tuv8tuv8tuv8tuv8tuv"
	.ASCII	"9wxyz9wxyz9wxyz9wxyz"

numfmt:
	.ASCIZ	"%d"

errchc:
	.ASCIZ	"Scelta non valida!"

.SECT .BSS
