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

	PUSH	4
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


! void usdel (void)
! Richiede il nome dell'utente da cancellare, lo cerca in romimg e, se
! presente, lo rimuove e salva la rom.
! Se l'utente specificato non esiste (o e' l'admin) stampa una schermata di
! errore.
usdel:
	PUSH	BP
	MOV	BP, SP

	! Inizializza buffer nome utente da cancellare.
	PUSH	MAXUSRLEN+1
	PUSH	0
	PUSH	delusrn
	CALL	memset
	ADD	SP, 6

	! Richiesta nome utente.
	PUSH	delusrn
	PUSH	msgdelus
	CALL	askusrn
	ADD	SP, 4

	! Ricerca nome utente.
	PUSH	delusrn
	CALL	srchrom
	ADD	SP, 2

	! Se srchrom ritorna -1, l'utente non esiste, se ritorna 0 si sta
	! tentando di cancellare l'admin; in entrambi i casi e' errore.
	CMP	AX, 0
	JG	1f

	! Stampa messaggio d'errore e ritorno.
	PUSH	erruser
	PUSH	msgdelus
	CALL	showerr
	ADD	SP, 4
	JMP	9f

	! Rimozione nome utente dalla rom.
1:	PUSH	AX		! id utente
	CALL	romusdel
	ADD	SP, 2

9:	MOV	SP, BP
	POP	BP
	RET


uslst:
	PUSH	BP
	MOV	BP, SP

	! Inizializza iterazione rom.
	CALL	inititer

	! Se c'e' solo l'admin, mostra una schermata d'errore.
1:	CMP	(numusers), 1
	JG	2f

	PUSH	nousers
	PUSH	errempty
	CALL	showerr
	ADD	SP, 2
	JMP	9f

	! Mostra il menu.
2:	PUSH	5
	PUSH	lsmenu
	PUSH	lsroute
	CALL	shwmenu
	ADD	SP, 6
	CMP	AX, 0
	JNE	1b


9:	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA

mtumng:
	.ASCIZ	"GESTIONE UTENTI"
meusadd:
	.ASCIZ	"1. Aggiunta utente          "
meusdel:
	.ASCIZ	"2. Rimozione utente         "
meuslst:
	.ASCIZ	"3. Elenco utenti            "

umroute:
	.WORD	noop, usadd, usdel, uslst
ummenu:
	.WORD	mecancl, meuslst, meusdel, meusadd, mtumng

mtlst:
	.ASCIZ	"ELENCO UTENTI"
meusnxt:
	.ASCIZ	"1. Successivo (inserimento) "
meusalph:
	.ASCIZ	"2. Successivo (alfabetico)  "
meusdel2:
	.ASCIZ	"3. Elimina utente           "

lsroute:
	.WORD	noop, romnext, noop, noop, noop
lsmenu:
	.WORD	itrusrn, mecancl, meusdel2, meusalph, meusnxt, mtlst

msgnewus:
	.ASCIZ	"AGGIUNTA UTENTE"
msgdelus:
	.ASCIZ	"RIMOZIONE UTENTE"

errfull:
	.ASCIZ	"ROM PIENA"
errused:
	.ASCIZ	"NOME UTENTE IN USO"
cantadd:
	.ASCIZ	"Impossibile aggiungere."

errempty:
	.ASCIZ	"ROM VUOTA"
nousers:
	.ASCIZ	"Nessun utente presente."

errlen:
	.ASCIZ	"LUNGHEZZA ERRATA"
usleninf:
	.ASCIZ	"da 1 a 16 caratteri."
psleninf:
	.ASCIZ	"8 caratteri."
