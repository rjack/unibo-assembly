! boot.s - inizializzazione del sistema
!
! Giacomo Ritucci, Paolo Pennestri, 30/07/2007

#include "defs.h"

.SECT .TEXT
! Punto di ingresso del sistema.
main:
	! FIXME commentare se non ci sono test da fare
	!CALL dotest

	! Inizializzazione file di rom
	CALL	openrom
	CMP	AX, -1
	JE	9f

	! Da specifiche, "all'avvio file di log creato vuoto"
	PUSH	0644
	PUSH	logpath
	PUSH	_CREAT
	SYS
	ADD	SP, 6
	CMP	AX, -1
	JE	9f
	MOV	(logfd), AX

	! Stampa schermo iniziale.
	PUSH	NULL
	PUSH	msginbdg	! inserire badge
	PUSH	NULL
	PUSH	NULL
	PUSH	msgtitle	! CONTROLLO ACCESSI
	PUSH	NULL
	CALL	drwscr
	ADD	SP, 12
	
1:	! Lettura nome utente.
	CALL	rduser
	CMP	AX, -1		! badge male inserito
	JE	1b

	! Stampa richiesta password.
	PUSH	NULL
	PUSH	msginpas	! inserire pass
	PUSH	NULL
	PUSH	NULL
	PUSH	msgtitle	! CONTROLLO ACCESSI
	PUSH	NULL
	CALL	drwscr
	ADD	SP, 12

	! Lettura password.
	CALL	rdpass
	CMP	AX, -1		! password errata
	JE	1b

	! Gestione utente / amministratore.
	MOV	AX, (userid)
	CMP	AX, ROOTUID
	JE	3f
	CALL	serveusr
	JMP	1b
3:	CALL	serveadm
	JMP	1b

	! Errore fatale durante l'inizializzazione.
9:	! TODO stampa messaggio errore
	PUSH	1
	PUSH	_EXIT
	SYS

! Routine per testare le altre routine
dotest:
	PUSH	BP
	MOV	BP, SP

	PUSH	0
	PUSH	_EXIT
	SYS

.SECT .DATA
logpath:
	.ASCIZ	"porta.log"
msgtitle:
	.ASCIZ	"CONTROLLO ACCESSI"
msginbdg:
	.ASCIZ	"inserire badge..."
msginpas:
	.ASCIZ	"digitare password..."

.SECT .BSS
logfd:
	.SPACE	2
