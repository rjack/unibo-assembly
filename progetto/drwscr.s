! drwscr.s - routine per la stampa dello schermo
!
! procedure:
! 	drwscr, disegna il display e il tastierino
!
! Giacomo Ritucci, Paolo Pennestri, 28/07/2007

	LINELEN = 29		! 28 spazi piu' terminatore

.SECT .TEXT
! void drwscr (line1, line2, line3, line4, line5, line6)
! Stampa lo schermo e il tastierino numerico.
! Dentro al riquadro dello schermo stampa le stringhe passate come argomento,
! ognuna lunga al massimo 28 caratteri.
drwscr:
	PUSH	BP
	MOV	BP, SP

	! Salvataggio registri usati.
	PUSH	BX
	PUSH	CX
	PUSH	SI

	! Scorrimento in alto delle schermate vecchie.
	! FIXME rimetterlo prima della consegna
	PUSH	flush
	PUSH	_PRINTF
	SYS
	ADD	SP, 4

	! Stampa del bordo superiore del display
	PUSH	updwbrd
	PUSH	_PRINTF
	SYS
	ADD	SP, 4

	! Stampa delle sei righe del display, passate come argomenti.
	! A ogni iterazione viene preparata una riga di soli spazi, e se
	! la stringa puntata dall'argomento corrente non e' NULL viene copiata
	! sopra gli spazi.

	! Preparazione ciclo.
	MOV	CX, 6		! contatore
	MOV	SI, 4		! offset argomenti: 4, 6, 8, ...
	PUSH	blkline		! riga di soli spazi
	PUSH	line-LINELEN	! riga da stampare

1:	! Calcolo prossima riga da gestire.
	POP	DX
	ADD	DX, LINELEN
	PUSH	DX
	! Se l'argomento e' -2, va stampata la riga salvata all'invocazione
	! precedente, salta subito alla printf.
	CMP	(BP)(SI), -2
	JE	2f
	! Altrimenti la riga e' da modificare: azzerata riempendola di spazi.
	CALL	strcpy
	! Se l'argomento e' NULL salta subito a stampare la riga di spazi.
	CMP	(BP)(SI), NULL
	JE	2f
	! Altrimenti stringa non nulla, va copiata nella riga da stampare
	! usando memcpy perche' non bisogna prendere il terminatore.
	! Calcolo lunghezza.
	PUSH	(BP)(SI)
	CALL	strlen
	ADD	SP, 2

	! Centratura testo:
	! spiazzamento = (spazio disponibile - spazio utilizzato) / 2
	MOV	BX, LINELEN
	SUB	BX, AX
	SHR	BX, 1
	POP	DX
	PUSH	DX
	ADD	BX, DX
	
	! Copia della stringa nella riga da stampare
	PUSH	AX		! lunghezza stringa passata come argomento
	PUSH	(BP)(SI)
	PUSH	BX
	CALL	memcpy
	ADD	SP, 6

	! Stampa della riga
2:	PUSH	fmtline
	PUSH	_PRINTF
	SYS
	ADD	SP, 4
	ADD	SI, 2
	LOOP	1b

	ADD	SP, 4		! toglie dallo stack blkline e line

	! Stampa del bordo inferiore
	PUSH	updwbrd
	PUSH	_PRINTF
	SYS
	ADD	SP, 4

	! FIXME commentata perche' il tracer ha il display piccolo
	! Stampa del tastierino
	PUSH	keybrd
	PUSH	_PRINTF
	SYS
	ADD	SP, 4

	! Ripristino registri usati.
	POP	SI
	POP	CX
	POP	BX

	MOV	SP, BP
	POP	BP
	RET

! void drwmsg (msg, i)
! Ridisegna lo schermo precedente, sostituendo l'i-esima (1...6) riga
! dall'alto con la stringa msg.
drwmsg:
	PUSH	BP
	MOV	BP, SP

	PUSH	CX

	! Preparazione argomenti per drwscr.
	MOV	CX, DISPLAYLN

1:	CMP	CX, +6(BP)	! i
	JE	2f
	PUSH	-2
	JMP	3f
2:	PUSH	+4(BP)		! errmsg
3:	LOOP	1b

	CALL	drwscr
	ADD	SP, 12

9:	POP	CX		! ripristino

	MOV	SP, BP
	POP	BP
	RET

! void askbadge (*title)
! Stampa una schermata con titolo title e con la richiesta di inserimento del
! badge. Attende la pressione del tasto associato all'evento e usa rdbadge
! salvare il nome utente in username.
! In caso di errore ripresenta la domanda: non ritorna finche' il badge non
! e' stato letto correttamente.
askbadge:
	PUSH	BP
	MOV	BP, SP

	! Stampa schermo iniziale.
	PUSH	NULL
	PUSH	msgbdg		! "inserire il badge"
	PUSH	NULL
	PUSH	NULL
	PUSH	+4(BP)		! title
	PUSH	NULL
	CALL	drwscr
	ADD	SP, 12

	! Lettura nome utente.
1:	CALL	rdbadge
	CMP	AX, -1		! badge male inserito
	! In caso di errore la stampa di un messaggio esplicativo e' a carico
	! di rdbadge quindi e' sufficiente ritentare.
	JE	1b

	MOV	SP, BP
	POP	BP
	RET

! void askpass (*title, *passbuf)
! Stampa una schermata con titolo title richiedente la digitazione di una
! password e ne attende l'inserimento. La password viene memorizzata, con
! tanto di terminatore, nel buffer passbuf specificato, che deve essere lungo
! almeno PASSLEN+1.
askpass:
	PUSH	BP
	MOV	BP, SP

	! Stampa schermata
	PUSH	NULL
	PUSH	msgpass		! "digitare password"
	PUSH	NULL
	PUSH	NULL
	PUSH	+4(BP)		! title
	PUSH	NULL
	CALL	drwscr
	ADD	SP, 12

	! Lettura password
	PUSH	PASSLEN+1
	PUSH	+6(BP)		! passbuf
	CALL	readkbd
	ADD	SP, 4

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA
msgbdg:
	.ASCIZ	"inserire il badge..."
msgpass:
	.ASCIZ	"digitare la password..."
updwbrd:
	.ASCIZ	"********************************\n"
blkline:
	.ASCIZ	"                            "	! 28 spazi + terminatore
fmtline:
	.ASCIZ	"* %s *\n"
keybrd:
	.ASCII	"\n\n"
	.ASCII	"|  1   | 2abc | 3def |\n"
	.ASCII	"| 4ghi | 5jkl | 6mno |\n"
	.ASCII	"| 7pqrs| 8tuv | 9wxyz|\n"
	.ASCII	"|  0_  |\n"
	.ASCIZ	"|   INVIA  | ANNULLA |\n" 
flush:
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCII	"\n\n\n\n\n\n\n\n\n\n"
	.ASCIZ	"\n\n\n\n\n\n\n\n\n\n"

.SECT .BSS
line:
	.SPACE	LINELEN
	.SPACE	LINELEN
	.SPACE	LINELEN
	.SPACE	LINELEN
	.SPACE	LINELEN
	.SPACE	LINELEN
