! file.s - operazioni sui file
!
! Giacomo Ritucci, Paolo Pennestri, 30/07/2007

	TMPBUFLEN  = 10

.SECT .TEXT
! void bldindx (fd, indexbuf)
! Riempe l'array indexbuf con gli indici di inizio riga di ogni riga del file
! relativo al file descriptor fd.
! In altre parole, per raggiungere l'inizio della i-esima riga del file basta
! fare una lseek di indexbuf[i] caratteri a partire dall'inizio del file.
! NB: indexbuf e' un array di parole.
bldindx:
	PUSH	BP
	MOV	BP, SP

	! Salvataggio registri usati.
	PUSH	BX
	PUSH	CX
	PUSH	SI
	PUSH	DI

	MOV	BX, 0		! numero totale di byte letti
	MOV	DI, +6(BP)	! indexbuf

	! La prima riga del file parte sempre a zero caratteri dall'inizio del
	! file.
	MOV	AX, 0
	STOS
	MOV	SI, DI		! DI verra' usato per SCASB.

	! Lettura dal fd nel tmpbuf.
	PUSH	TMPBUFLEN
	PUSH	tmpbuf
	PUSH	+4(BP)		! fd
	PUSH	_READ
1:	SYS

	! Read ritorna 0 quando arriva all'EOF, non dovrebbe ritornare -1 con
	! i file.
	CMP	AX, 0
	JLE	6f

	! Ricerca '\n'
	ADD	BX, AX		! numero byte totali
	MOV	CX, AX		! numero byte in tmpbuf
	MOV	DI, tmpbuf	! preparazione SCASB

2:	MOVB	AL, '\n'	! byte da cercare
	REPNZ	SCASB

	! Se CX arriva a zero, il buffer non contiene altri '\n', salta alla
	! lettura.
	JNE	1b

	! Trovato un '\n', calcolo posizione carattere successivo.
	MOV	AX, BX
	SUB	AX, CX
	! Salvataggio della posizione in indexbuf.
	XCHG	SI, DI		! DI = indexbuf, SI = tmpbuf
	STOS
	XCHG	SI, DI		! DI = tmpbuf, SI = indexbuf
	CMP	CX, 0
	JNE	2b
	JMP	1b

	! Fine file, ripristino stack e registri.
6:	ADD	SP, 8		! _READ
	POP	DI
	POP	SI
	POP	CX
	POP	BX

	MOV	SP, BP
	POP	BP
	RET

.SECT .DATA

.SECT .BSS
! buffer di caratteri per le letture da file
tmpbuf:
	.SPACE	TMPBUFLEN
