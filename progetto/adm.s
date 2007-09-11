! adm.s - funzione per la gestione dell'amministratore.
!
! Giacomo Ritucci, Paolo Pennestri, 02/08/2007

.SECT .TEXT
! void serveadm (void)
! Presenta il menu amministratore sul display.
serveadm:
	PUSH	BP
	MOV	BP, SP

	PUSH	4
	PUSH	admmenu
	PUSH	admroute
1:	CALL	shwmenu
	CMP	AX, 2		! modifica pass
	JE	1b
	CMP	AX, 3		! gestione utenti
	JE	1b
	ADD	SP, 6

	MOV	SP, BP
	POP	BP
	RET


usrmng:
	PUSH	BP
	MOV	BP, SP

	PUSH	3
	PUSH	ummenu
	PUSH	umroute
1:	CALL	shwmenu
	CMP	AX, 0		! annulla
	JNE	1b
	ADD	SP, 6

	MOV	SP, BP
	POP	BP
	RET


usadd:
	PUSH	BP
	MOV	BP, SP

	! Controllo numero utenti.
	CMP	(numusers), MAXUSERS
	JL	1f
	
	PUSH	cantadd
	PUSH	errfull
	JMP	8f

	! Richiesta nuovo nome utente.
1:	PUSH	newusrn
	PUSH	msgnewus	! "AGGIUNTA UTENTE"
	CALL	askusrn
	ADD	SP, 4

	! Controllo lunghezza nome utente.
	PUSH	newusrn
	CALL	strlen
	ADD	SP, 2
	CMP	AX, 0
	JG	1f

	PUSH	usleninf
	PUSH	errlen
	JMP	8f

	! Nome utente non deve essere gia' in uso.
1:	PUSH	newusrn
	CALL	srchrom
	ADD	SP, 2
	CMP	AX, -1
	JE	2f

	PUSH	cantadd
	PUSH	errused
	JMP	8f

	! Richiesta nuova password.
2:	PUSH	newpass
	PUSH	msgnewus
	CALL	askpass
	ADD	SP, 4

	! Controllo lunghezza password.
	PUSH	newpass
	CALL	strlen
	ADD	SP, 2
	CMP	AX, PASSLEN
	JE	3f

	PUSH	psleninf
	PUSH	errlen
	JMP	8f

	! Inserimento nella rom.
3:	PUSH	newpass
	PUSH	newusrn
	CALL	romusadd
	ADD	SP, 4
	JMP	9f

	! Stampa l'errore.
8:	CALL	showerr
	ADD	SP, 4

9:	MOV	SP, BP
	POP	BP
	RET


ussrch:
	PUSH	BP
	MOV	BP, SP


	MOV	SP, BP
	POP	BP
	RET


uslst:
	PUSH	BP
	MOV	BP, SP

	PUSH	4
	PUSH	lsmenu
	PUSH	lsroute
1:	CALL	shwmenu
	CMP	AX, 0
	JNE	1b

	ADD	SP, 4

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA

mtumng:
	.ASCIZ	"GESTIONE UTENTI"
meusadd:
	.ASCIZ	"1. Aggiunta utente          "
meuslst:
	.ASCIZ	"2. Elenco utenti            "

umroute:
	.WORD	noop, usadd, uslst
ummenu:
	.WORD	mecancl, meuslst, meusadd, mtumng

mtlst:
	.ASCIZ	"ELENCO UTENTI"
meusnxt:
	.ASCIZ	"1. Successivo               "
meusprv:
	.ASCIZ	"2. Elimina utente           "
meussrch:
	.ASCIZ	"3. Ricerca utente           "

lsroute:
	.WORD	noop, noop, noop, noop
lsmenu:
	.WORD	mecancl, meussrch, meusprv, meusnxt, mtlst

msgnewus:
	.ASCIZ	"AGGIUNTA UTENTE"

errfull:
	.ASCIZ	"ROM PIENA"
errused:
	.ASCIZ	"NOME UTENTE IN USO"
cantadd:
	.ASCIZ	"Impossibile aggiungere utente."

errlen:
	.ASCIZ	"LUNGHEZZA ERRATA"
usleninf:
	.ASCIZ	"da 1 a 16 caratteri."
psleninf:
	.ASCIZ	"8 caratteri."
