! io.s - funzioni di I/O
!
! Giacomo Ritucci, Paolo Pennestri, 31/07/2007

	BADGESIM = 'x'

.SECT .TEXT
! int IN_2 (indirizzo)
! In AX ritorna:
! -1 se c'e' un errore hardware
! -2 se il badge e' stato inserito male
! >0 ovvero il carattere letto dal badge
!  0 quando non c'e' altro da leggere
! Se fallisce, DX contiene l'indirizzo del messaggio d'errore, altrimenti il
! contenuto di DX e' indefinito.
IN_2:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX		! salvataggio

	MOV	AX, -1		! init valore di ritorno
	MOV	DX, errhw	! init msg errore

	! Controllo indirizzo passato come argomento.
	MOV	BX, 0x0
	CMP	BX, +4(BP)
	JNE	9f

	! Se il fd vale -1, c'e' da iniziare la lettura di un nuovo badge.
	CMP	(badgefd), -1
	JNE	1f

	! Attesa inserimento badge, simulata con pressione tasto.
	! Lettura fino al '\n' per evitare che input "abbondanti" influiscano
	! sulle _GETCHAR successive: viene considerato solo il primo carattere
	! (quindi 'xfggf\n' viene accettato).
	PUSH	_GETCHAR
	SYS
	ADD	SP, 2
	PUSH	AX			! salvataggio primo carattere
	CALL	skipln			! scarta tutto il resto fino al \n
	POP	AX			! ripristino primo carattere

	CMPB	AL, BADGESIM		! AL == 'x'
	JNE	8f

	! Badge ben inserito, apertura file.
	PUSH	RD
	PUSH	bdgpath
	PUSH	_OPEN
	SYS
	ADD	SP, 6
	CMP	AX, -1
	JE	9f

	MOV	(badgefd), AX		! salvataggio fd

	! Lettura di un carattere dal badge. Generalmente i file hanno un \n
	! prima dell'EOF, ma non e' certo. Viene controllato prima l'EOF poi
	! il \n.
1:	PUSH	1
	PUSH	lettore	
	PUSH	(badgefd)
	PUSH	_READ
	SYS
	ADD	SP, 8
	CMP	AX, 0			! controllo EOF
	JE	2f

	MOVB	AL, (lettore)		! ritorna il carattere letto
	CMPB	AL, '\n'		! controllo newline
	JE	2f
	JMP	9f
	
	! Badge letto completamente, chiusura file e valore di ritorno 0.
2:	MOV	AX, 0
	PUSH	(badgefd)
	PUSH	_CLOSE
	SYS
	ADD	SP, 4
	MOV	(badgefd), -1
	JMP	9f
	
	! Errore inserimento badge (non e' stato premuto 'x')
8:	MOV	AX, -2
	MOV	DX, errbadge

9:	POP	BX		! ripristino

	MOV	SP, BP
	POP	BP
	RET


! Apre la porta
OUT_2:
	PUSH	BP
	MOV	BP, SP

	PUSH	DI		! salvataggio

	! Confronto indirizzo dato.
	CMP	+4(BP), 0x3
	JNE	8f

	SUB	SP, 2		! spazio per lunghezza username

	PUSH	username
	CALL	strlen

	! Aggiunta di un '\n' alla fine dell'username. Si puo' modificare
	! l'username perche' dopo l'apertura della porta c'e' il logout,
	! quindi il contenuto del buffer non viene piu' utilizzato fino al
	! prossimo accesso.
	MOV	DI, username
	ADD	DI, AX
	INC	AX		! ora len conta anche il '\n'

	MOV	-4(BP), AX	! salvataggio len nello stack

	MOVB	AL, '\n'
	STOSB

	PUSH	(logfd)
	PUSH	_WRITE
	SYS
	ADD	SP, 8

	JMP	9f
	
8:	MOV	AX, -1

9:	POP	DI		! ripristino

	MOV	SP, BP
	POP	BP
	RET


! int rdbadge (void)
! Accede al lettore del badge, attende l'inserimento e prova a leggere il nome
! utente, salvandolo nella variabile username.
! Ritorna 0 se tutto ok, -1 se fallisce. In questo caso mostra un messaggio di
! errore.
! SIDE EFFECT:
! - salva il nome utente in username
rdbadge:
	PUSH	BP
	MOV	BP, SP

	PUSH	DI

	! Inizializzazione buffer username
	PUSH	MAXUSRLEN+1
	PUSH	0
	PUSH	username
	CALL	memset
	ADD	SP, 6

	MOV	DI, username

1:	PUSH	0x0
	CALL	IN_2
	ADD	SP, 2
	CMPB	AL, 0
	JL	8f
	STOSB			! salvataggio carattere o terminatore
	CMPB	AL, 0
	JG	1b

	! Ricerca utente nel database
	PUSH	username
	CALL	srchrom
	ADD	SP, 2
	CMP	AX, -1
	JE	8f

	! L'utente esiste, salva userid e ritorna zero.
	MOV	(userid), AX
	MOV	AX, 0
	JMP	9f

	! Stampa del messaggio d'errore. DX viene riempito da IN_2 e contiente
	! il puntatore al messaggio.
8:	PUSH	4
	PUSH	DX
	CALL	drwmsg
	ADD	SP, 4

	MOV	AX, -1		! ritorna errore

	! Ripristino registri usati.
9:	POP	DI

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA
bdgpath:
	.ASCIZ	"badge.txt"
errbadge:
	.ASCIZ	"Badge male inserito"
erruser:
	.ASCIZ	"Utente inesistente"
errhw:
	.ASCIZ	"Malfunzionamento lettore"
badgefd:
	.WORD	-1

.SECT .BSS
lettore:
	.SPACE	1		! buffer carattere letto dal badge
