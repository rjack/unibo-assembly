! usr.s - routine per la gestione delle scelte utente.
!
! Giacomo Ritucci, Paolo Pennestri, 02/08/2007

! void serveusr (void)
! Presenta il menu utente sul display.
serveusr:
	PUSH	BP
	MOV	BP, SP

	PUSH	3
	PUSH	usrmenu
	PUSH	usrroute
1:	CALL	shwmenu
	CMP	AX, 2		! modifica password
	JE	1b
	ADD	SP, 6

	! Stampa messaggio iniziale.
	PUSH	NULL
	PUSH	msginbdg
	PUSH	NULL
	PUSH	NULL
	PUSH	msgtitle
	PUSH	NULL
	CALL	drwscr
	ADD	SP, 12

	MOV	SP, BP
	POP	BP
	RET

opendoor:
	PUSH	BP
	MOV	BP, SP

	PUSH	rele
	CALL	OUT_2
	ADD	SP, 2

	MOV	SP, BP
	POP	BP
	RET


! void chgpass (void)
! Richiede una nuova password e la sostituisce in rom.txt al posto della
! vecchia. Accetta esclusivamente password di 8 caratteri, diversamente stampa
! un errore e la chiede nuovamente.
chgpass:
	PUSH	BP
	MOV	BP, SP

	PUSH	NULL
	PUSH	msginnew
	PUSH	NULL
	PUSH	NULL
	PUSH	msgnewps
	PUSH	NULL
	CALL	drwscr
	ADD	SP, 12

	PUSH	PASSLEN+1
	PUSH	tmppass
1:	CALL	readkbd
	CMP	AX, PASSLEN+1
	JE	2f

	! Stampa errore e torna a leggere la nuova pass.
	PUSH	4
	PUSH	errlenps
	CALL	drwmsg
	ADD	SP, 4
	JMP	1b

2:	ADD	SP, 4

	PUSH	tmppass
	PUSH	username
	PUSH	(userid)
	CALL	editrom
	ADD	SP, 6

	MOV	SP, BP
	POP	BP
	RET

.SECT .DATA
msgnewps:
	.ASCIZ	"MODIFICA PASSWORD"
msginnew:
	.ASCIZ	"digitare nuova password..."
errlenps:
	.ASCIZ	"lunghezza errata!"
