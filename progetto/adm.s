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
	! FIXME
	! Questo codice va adattato al nuovo formato della rom.
	! FIXME
	! Questo codice deve usare le funzioni rduser e rdpass.
	! FIXME
	! Questo codice deve gestire
	PUSH	BP
	MOV	BP, SP

	! FIXME
	! Ricerca del primo id libero della rom.
	! CALL	freeid
	! CMP	AX, -1
	! JE	8f
	! MOV	(newkey), AX

	! FIXME
	! Sostituire con askuser
	PUSH	NULL
	PUSH	msginusr	! inserire nome utente
	PUSH	NULL
	PUSH	NULL
	PUSH	msgnewus	! NUOVO UTENTE
	PUSH	NULL
	CALL	drwscr
	ADD	SP, 12

	! FIXME
	! Sostituire con askuser
	! Lettura nuovo nome utente
1:	PUSH	MAXUSRLEN+1
	PUSH	newusrn
	CALL	readkbd
	ADD	SP, 4
	CMP	AX, 1
	JLE	6f
	CMP	AX, MAXUSRLEN+1
	JG	6f

	! Nome utente non deve essere gia' in uso.
	PUSH	newusrn
	! FIXME
	! CALL	srchrom
	ADD	SP, 2
	CMP	AX, -1
	JNE	5f

	! FIXME
	! Sostituire con askpass
	PUSH	5
	! PUSH	msginpas		! digitare password
	CALL	drwmsg
	ADD	SP, 4

	! FIXME
	! Sostituire con askpass
	! Lettura password
2:	PUSH	PASSLEN+1
	PUSH	newpass
	CALL	readkbd
	ADD	SP, 4
	CMP	AX, PASSLEN+1
	JNE	7f

	PUSH	newpass
	PUSH	newusrn
	CALL	romusadd
	ADD	SP, 4
	JMP	9f

	! Lunghezza username non valida, salta all'inizio.
5:	PUSH	4
	PUSH	errusexs		! nome utente in uso
	CALL	drwmsg
	ADD	SP, 4
	JMP	1b

	! Lunghezza username non valida, salta all'inizio.
6:	PUSH	4
	PUSH	erruslen
	CALL	drwmsg
	ADD	SP, 4
	JMP	1b

	! Lunghezza password non valida, salta a lettura pass.
7:	PUSH	4
	PUSH	errpslen
	CALL	drwmsg
	ADD	SP, 4
	JMP	2b

	! Rom piena, impossibile aggiungere un altro utente.
8:	PUSH	NULL
	PUSH	anykey
	PUSH	cantadd
	PUSH	NULL
	PUSH	errfull
	PUSH	NULL
	CALL	drwscr
	ADD	SP, 12

	! Attende e scarta input.
	PUSH	_GETCHAR
	SYS
	ADD	SP, 2
	CALL	skipln

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

errfull:
	.ASCIZ	"ROM PIENA"
cantadd:
	.ASCIZ	"Operazione impossibile."
anykey:
	.ASCIZ	"Premere un tasto..."
msgnewus:
	.ASCIZ	"NUOVO UTENTE"
msginusr:
	.ASCIZ	"digitare nome utente..."
erruslen:
	.ASCIZ	"Lunghezza nome utente errata"
errpslen:
	.ASCIZ	"Lunghezza password errata"
errusexs:
	.ASCIZ	"Nome utente gia' in uso"
