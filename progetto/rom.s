! rom.s - gestione del database utenti
!
! Giacomo Ritucci, Paolo Pennestri, 30/07/2007

.SECT .TEXT

! int seekrom (i)
! Sposta il puntatore del file della rom alla riga riga numero i.
! Se i = 0 si posiziona all'inizio del file, se i = -1 si posiziona alla fine.
! Ritorna cio' che viene ritornato da _LSEEK
seekrom:
	PUSH	BP
	MOV	BP, SP

	MOV	DX, 0
	MOV	AX, ROMLINELEN

	MUL	+4(BP)		! ROMLINELEN * i

	! Se risultato moltiplicazione e' >= 0, usa SEEK_SET, se minore
	! SEEK_END (i era negativo).
	CMP	AX, 0
	JGE	1f

	MOV	AX, 0
	MOV	DX, 0
	PUSH	SEEK_END
	JMP	2f

1:	PUSH	SEEK_SET
2:	PUSH	DX
	PUSH	AX
	PUSH	(romfd)
	PUSH	_LSEEK
	SYS
	ADD	SP, 10

	MOV	SP, BP
	POP	BP
	RET

! int getlnnum (void)
! Ritorna il numero di riga a cui e' attualmente posizionato il puntatore del
! file.
getlnnum:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX

	PUSH	SEEK_CUR
	PUSH	0
	PUSH	0
	PUSH	(romfd)
	PUSH	_LSEEK
	SYS
	ADD	SP, 10

	MOV	BX, ROMLINELEN
	DIV	BX

	POP	BX

	MOV	SP, BP
	POP	BP
	RET


! int openrom (void)
! Apre il file che simula la rom.
! Ritorna -1 se fallisce, 0 se tutto ok.
! SIDE EFFECT:
! - salva in romfd il valore del file descriptor del file della rom.
openrom:
	PUSH	BP
	MOV	BP, SP

	! Apertura del file rom.txt in lettura e scrittura.
	PUSH	RDWR
	PUSH	rompath
	PUSH	_OPEN
	SYS
	ADD	SP, 6

	! Se la open e' fallita, ritorna subito -1.
	CMP	AX, -1
	JE	9f

	! Altrimenti, salvataggio file descriptor.
	MOV	(romfd), AX
	MOV	AX, 0

9:	MOV	SP, BP
	POP	BP
	RET

! int getromsz (void)
! Ritorna il numero di byte usati in romimg, basandosi sul numero di utenti e
! sulla lunghezza di una riga della rom.
getromsz:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX

	MOV	AX, (numusers)
	MOV	BX, ROMLINELEN
	MUL	BX

	POP	BX

	MOV	SP, BP
	POP	BP
	RET


! int loadrom (*buf, buflen)
! Legge buflen byte dal file della rom salvandoli nel buffer buf. Tipicamente
! buflen e' la dimensione massima possibile del file della rom.
! Ritorna 0 se riesce, -1 se fallisce.
! SIDE EFFECT:
! - salva in numusers il numero di righe lette.
loadrom:
	PUSH	BP
	MOV	BP, SP

	! Lettura dal file.
	PUSH	+6(BP)		! buflen
	PUSH	+4(BP)		! buf
	PUSH	(romfd)
	PUSH	_READ
	SYS
	ADD	SP, 8

	! Se _READ ritorna errore, salta alla fine.
	CMP	AX, -1
	JE	9f

	! Calcolo e salvataggio del numero di utenti.
	CALL	getlnnum
	MOV	(numusers), AX
	MOV	AX, 0

9:	MOV	SP, BP
	POP	BP
	RET


! int saverom (*buf, buflen)
! Ricrea il file della rom scrivendoci i primi buflen byte del buffer buf.
! Tipicamente buf punta all'immagine in memoria della rom e buflen e' la sua
! dimensione.
! Ritorna 0 se riesce, -1 se fallisce.
! SIDE EFFECT:
! - chiude e riapre romfd.
saverom:
	PUSH	BP
	MOV	BP, SP

	! Chiusura file descriptor della rom.
	PUSH	(romfd)
	PUSH	_CLOSE
	SYS
	ADD	SP, 4
	CMP	AX, -1
	JE	9f

	! Riapertura di un file vuoto.
	PUSH	0644
	PUSH	rompath
	PUSH	_CREAT
	SYS
	ADD	SP, 6
	CMP	AX, -1
	JE	9f

	! Salvataggio nuovo file descriptor.
	MOV	(romfd), AX

	! Scrittura buffer nel nuovo file.
	PUSH	+6(BP)
	PUSH	+4(BP)
	PUSH	(romfd)
	PUSH	_WRITE
	SYS
	ADD	SP, 8
	CMP	AX, -1
	JE	9f

	! Riuscito, ritorna 0.
	MOV	AX, 0

9:	MOV	SP, BP
	POP	BP
	RET


! void prsromln
! Legge il file rom dalla posizione corrente fino al fine linea, salvando i
! campi nelle tre variabili temporanee (tmpkey, tmpusrn, tmppass).
! Il comportamento non e' definito se il puntatore del file non e' posizionato
! all'inizio di una riga.
! Ritorna il valore di ritorno della _READ.
prsromln:
	PUSH	BP
	MOV	BP, SP

	! Lettura riga nel buffer temporaneo.
	PUSH	ROMLINELEN
	PUSH	romlnbuf
	PUSH	(romfd)
	PUSH	_READ
	SYS
	ADD	SP, 8

	CMP	AX, 0		! fine file, salta scansione
	JE	9f

	PUSH	AX		! salva retval di _READ

	! Scansione buffer.
	PUSH	tmppass
	PUSH	tmpusrn
	PUSH	romfmt
	PUSH	romlnbuf
	PUSH	_SSCANF
	SYS
	ADD	SP, 10

	POP	AX		! recupero retval di _READ

9:	MOV	SP, BP
	POP	BP
	RET
	

! int srchrom (target)
! Cerca target tra i nomi utente.
! Se trova qualcosa ritorna il numero di riga in cui si trova e tmpusrn e
! tmppass contengono i dati cercati, altrimenti ritorna -1 in AX e un
! puntatore a un messaggio d'errore in DX.
srchrom:
	PUSH	BP
	MOV	BP, SP

	! Riposiziona il puntatore all'inizio del file.
	PUSH	0
	CALL	seekrom
	ADD	SP, 2

	! Ricerca del nome utente, riga per riga.
	! Lettura di una riga e scansione dei campi.
1:	CALL	prsromln
	! Se ritorna 0 e' finito il file e non e' stato trovato cio' che si
	! cercava.
	CMP	AX, 0
	JE	8f

	! Confronto username usando strcmp.
	PUSH	tmpusrn
	PUSH	+4(BP)			! target
	CALL	strcmp
	ADD	SP, 4
	CMP	AX, 0
	JE	7f
	JMP	1b

	! Utente trovato. prsromln lascia il puntatore al file alla riga
	! successiva, bisogna decrementare il risultato di getlnnum.
7:	CALL	getlnnum
	DEC	AX
	JMP	9f

	! Errore, utente non trovato.
8:	MOV	AX, -1
	MOV	DX, erruser

9:	MOV	SP, BP
	POP	BP
	RET


! void editrom (id, newuser, newpass)
! Sovrascrive la riga associata a id con il nuovo username e la nuova
! password.
editrom:
	PUSH	BP
	MOV	BP, SP

	! Calcola offset riga.
	MOV	AX, ROMLINELEN
	MUL	+4(BP)		! id
	ADD	AX, KEYLEN	! salta la chiave numerica

	! Salta al primo carattere dell'username.
	PUSH	SEEK_SET
	PUSH	0
	PUSH	AX
	PUSH	(romfd)
	PUSH	_LSEEK
	SYS
	ADD	SP, 10

	PUSH	0		! spazio per len
	PUSH	+6(BP)		! newuser
	CALL	strlen
	MOV	-2(BP), AX	! salvataggio len
	PUSH	(romfd)
	PUSH	_WRITE
	SYS

	NEG	-2(BP)
	ADD	-2(BP), MAXUSRLEN
	INC	-2(BP)
	MOV	-4(BP), blkline
	SYS

	MOV	-2(BP), PASSLEN
	MOV	AX, +8(BP)
	MOV	-4(BP), AX
	SYS

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA
rompath:
	.ASCIZ	"./rom.txt"
romfmt:
	.ASCIZ	"%s %s\n"
.SECT .BSS
romfd:
	.SPACE	2
romimg:
	.SPACE	MAXROMLEN
numusers:
	.SPACE	2

! Buffer usato da prsromln.
romlnbuf:
	.SPACE	ROMLINELEN
! Buffer temporanei per utente e password.
tmpusrn:
	.SPACE	MAXUSRLEN+1
tmppass:
	.SPACE	PASSLEN+1
