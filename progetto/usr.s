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
! vecchia.
chgpass:
	PUSH	BP
	MOV	BP, SP

	! Inizializzazione buffer.
	PUSH	PASSLEN+1
	PUSH	0
	PUSH	newpass
	CALL	memset
	ADD	SP, 6

	! Richiesta password.
	PUSH	newpass
	PUSH	msgnewps
	CALL	askpass
	ADD	SP, 2

	! Modifica password.
	PUSH	newpass
	PUSH	(userid)
	CALL	editpass
	ADD	SP, 4

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA
msgnewps:
	.ASCIZ	"MODIFICA PASSWORD"
errlenps:
	.ASCIZ	"lunghezza errata!"
