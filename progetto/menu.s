! menu.s - menu utente e amministratore a scelta multipla.
!
! Giacomo Ritucci, Paolo Pennestri, 02/08/2007

.SECT .TEXT
! int shwmenu (routearray, menuarray, n)
! Mostra un menu e attende la scelta dell'utente, quindi esegue la funzione
! associata alla scelta. Al ritorno della funzione, ritorna il numero della
! scelta compiuta.
! routearray e' un array di puntatori a funzioni, menuarray e' un array di
! puntatori a stringhe di testo.
! NB: n deve essere minore o uguale a 5 altrimenti il menu non sta nel
! display.
shwmenu:
	PUSH	BP
	MOV	BP, SP

	PUSH	CX		! salvataggio
	PUSH	SI

	! Preparazione stampa a video del menu

	! Calcolo righe vuote, non usate dal menu:
	! vuote = disponibili - (n usate dal menu + 1 dal titolo)
	MOV	CX, DISPLAYLN
	SUB	CX, +8(BP)	! n (menu)
	DEC	CX		! titolo

	! Argomenti di drwscr per le righe vuote.
	CMP	CX, 0
	JE	2f
1:	PUSH	NULL
	LOOP	1b

	! Argomenti di drwscr per le voci del menu e il titolo
2:	MOV	CX, +8(BP)	! n
	INC	CX
	MOV	SI, +6(BP)	! menuarray
2:	LODS
	PUSH	AX
	LOOP	2b

	CALL	drwscr
	ADD	SP, 12

	PUSH	+8(BP)		! n
	CALL	readchc
	ADD	SP, 2
	MOV	CX, AX		! salva scelta in CX
	SHL	AX, 1		! AX * 2, l'array e' di parole non di byte

	MOV	BX, +4(BP)	! routearray
	ADD	BX, AX
	CALL	(BX)

	MOV	AX, CX		! ritorna il numero della scelta

	POP	SI		! ripristino
	POP	CX
	
	MOV	SP, BP
	POP	BP
	RET


! void noop (void)
! Non fa nulla. Associata alle voci "0. Annulla" dei menu.
noop:
	RET


.SECT .DATA
usrroute:
	.WORD	noop, opendoor, chgpass
usrmenu:
	.WORD	mecancl, mepass, medoor, mtuser

admroute:
	.WORD	noop, opendoor, chgpass, usrmng
admmenu:
	.WORD	mecancl, meusmng, mepass, medoor, mtadm

! Menu title
mtuser:
	.ASCIZ	"MENU UTENTE"
mtadm:
	.ASCIZ	"MENU AMMINISTRATORE"

! Menu entry
medoor:
	.ASCIZ	"1. Apertura porta           "
mepass:
	.ASCIZ	"2. Modifica password        "
meusmng:
	.ASCIZ	"3. Gestione utenti          "
mecancl:
	.ASCIZ	"0. Annulla                  "

.SECT .BSS
choiche:
	.SPACE	2	! carattere + terminatore
