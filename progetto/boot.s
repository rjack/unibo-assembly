! boot.s - inizializzazione del sistema
!
! Giacomo Ritucci, Paolo Pennestri, 30/07/2007

#include "defs.h"

.SECT .TEXT
! Punto di ingresso del sistema.
main:
	! Inizializzazione file di rom.
	CALL	openrom

	! Caricamento file di rom in memoria e calcolo numero di utenti.
	CALL	loadrom
	CMP	AX, -1
	JE	main

	CALL creatlog

	! Richiesta badge.
1:	PUSH	msgtitle
	CALL	askbadge
	ADD	SP, 2

	! Richiesta password.
	PUSH	password
	PUSH	msgtitle
	CALL	askpass
	ADD	SP, 4

	! Autenticazione.
	PUSH	password
	PUSH	(userid)
	CALL	authusr
	CMP	AX, -1
	JE	1b
	
	! Gestione utente / amministratore.
	MOV	AX, (userid)
	CMP	AX, ROOTUID
	JE	3f
	CALL	serveusr
	JMP	1b
3:	CALL	serveadm
	JMP	1b


! void creatlog (void)
! Crea il file di log.
creatlog:
	PUSH	BP
	MOV	BP, SP

	! Da specifiche, "all'avvio file di log creato vuoto"
1:	PUSH	0644
	PUSH	logpath
	PUSH	_CREAT
	SYS
	ADD	SP, 6
	CMP	AX, -1
	JNE	8f

	PUSH	callhelp
	PUSH	doorerr
	CALL	showerr
	ADD	SP, 4

	JMP	1b

8:	MOV	(logfd), AX

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA
logpath:
	.ASCIZ	"porta.log"
msgtitle:
	.ASCIZ	"CONTROLLO ACCESSI"
doorerr:
	.ASCIZ	"ERRORE PORTA"

.SECT .BSS
logfd:
	.SPACE	2

! Variabili usate nell'identificazione dell'utente autenticato via badge.
username:
	.SPACE	MAXUSRLEN+1
password:
	.SPACE	PASSLEN+1
userid:
	.SPACE	2
newusrn:
	.SPACE	MAXUSRLEN+1
newpass:
	.SPACE	PASSLEN+1
delusrn:
	.SPACE	MAXUSRLEN+1
