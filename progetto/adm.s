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

	PUSH	5
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
	PUSH	0
	CALL	inititer
	ADD	SP, 2

	CALL	dolst

	MOV	SP, BP
	POP	BP
	RET


uslstal:
	PUSH	BP
	MOV	BP, SP

	! Inizializza iterazione alfabetica rom.
	PUSH	1
	CALL	inititer
	ADD	SP, 2
	
	CALL	dolst

	MOV	SP, BP
	POP	BP
	RET


dolst:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX

	! Se c'e' solo l'admin, mostra una schermata d'errore.
1:	CMP	(numusers), 1
	JG	2f

	PUSH	nousers
	PUSH	errempty
	CALL	showerr
	ADD	SP, 4
	JMP	9f

	! Mostra il menu.
2:	PUSH	4
	PUSH	lsmenu
	PUSH	lsroute
	CALL	shwmenu
	ADD	SP, 6

	! Utente ha scelto "annulla", esce dal menu.
	CMP	AX, 0
	JE	9f

	! Se non ha scelto "elimina" torna subito a mostrare il menu.
	CMP	AX, 2
	JNE	1b

	! Altrimenti cancellazione utente e visualizzazione successivo.
	MOV	BX, (iterid)	! salva in BX l'id da cancellare
	CALL	romnext
	! Ora iterid contiene il nuovo id.
	! Se cancelliamo un id utente minore di quello che dobbiamo mostrare,
	! va decrementato l'id superstite.
	CMP	BX, (iterid)
	JGE	3f
	DEC	(iterid)
3:	PUSH	BX
	CALL	romusdel
	ADD	SP, 2
	JMP	1b

9:	POP	BX

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA

mtumng:
	.ASCIZ	"GESTIONE UTENTI"
meusadd:
	.ASCIZ	"1. Aggiunta                 "
meusdel:
	.ASCIZ	"2. Rimozione                "
meuslst:
	.ASCIZ	"3. Elenco                   "
meuslsal:
	.ASCIZ	"4. Elenco alfabetico        "

umroute:
	.WORD	noop, usadd, usdel, uslst, uslstal
ummenu:
	.WORD	mecancl, meuslsal, meuslst, meusdel, meusadd, mtumng

mtlst:
	.ASCIZ	"ELENCO UTENTI"
meusnxt:
	.ASCIZ	"1. Successivo               "
meusdel2:
	.ASCIZ	"2. Elimina utente           "

lsroute:
	.WORD	noop, romnext, noop, noop
lsmenu:
	.WORD	itrusrn, mecancl, meusdel2, meusnxt, mtlst

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
