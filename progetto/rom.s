! rom.s - gestione del database utenti
!
! Giacomo Ritucci, Paolo Pennestri, 30/07/2007


.SECT .TEXT

! int authusr (id, *pass)
! Confronta la password passata come argomento con quella salvata nel record
! id della rom.
! Ritorna 0 se le password coincidono, -1 altrimenti.
authusr:
	PUSH	BP
	MOV	BP, SP

	! Costruzione puntatore alla password salvata nella romimg.
	PUSH	+4(BP)		! id
	CALL	getlnoff
	ADD	SP, 2
	ADD	AX, MAXUSRLEN+1
	ADD	AX, romimg

	! Confronto con la password passata come argomento.
	PUSH	PASSLEN
	PUSH	AX		! campo pass del record #id
	PUSH	+6(BP)		! pass
	CALL	memcmp
	ADD	SP, 8

	! Pass coincidono, ritorna 0.
	CMP	AX, 0
	JE	9f
	! Altrimenti ritorna -1.
	MOV	AX, -1

9:	MOV	SP, BP
	POP	BP
	RET


! int srchrom (*name)
! Cerca user tra i campi utente dei record della romimg.
! Se user esiste ritorna il suo id, altrimenti ritorna -1.
srchrom:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX
	PUSH	CX

	MOV	CX, (numusers)
	! DEC	CX

	! Costruzione offset al record.
1:	PUSH	CX
	CALL	getlnoff
	ADD	SP, 2
	SUB	AX, RECORDLEN
	MOV	BX, AX	
	ADD	BX, romimg

	! Confronto stringa passata come argomento con nome utente del record.
	PUSH	BX		! romimg + offset
	PUSH	+4(BP)		! name
	CALL	strcmp
	ADD	SP, 4
	CMP	AX, 0
	LOOPNE	1b

	! Controllo esito: se utente e' stato trovato ritorna id.
	CMP	AX, 0
	JE	2f
	! Altrimenti ritorna -1.
	MOV	AX, -1
	JMP	9f

2:	MOV	AX, CX		! CX = id utente

9:	POP	CX
	POP	BX

	MOV	SP, BP
	POP	BP
	RET


! int getnumus (void)
! Ritorna il numero di utenti contenuti nel file rom.txt, dividendo la
! dimensione del file per la lunghezza di un record (RECORDLEN).
getnumus:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX

	! Con _LSEEK determina dimensione file.
	PUSH	SEEK_END
	PUSH	0
	PUSH	0
	PUSH	(romfd)
	PUSH	_LSEEK
	SYS
	ADD	SP, 10

	! Divisione per lunghezza di un record.
	MOV	BX, RECORDLEN
	DIV	BX

	POP	BX

	MOV	SP, BP
	POP	BP
	RET


! int getlnoff (id)
! Ritorna l'offset del record numero id rispetto all'inizio della rom,
! moltiplicando la lunghezza di un record per il valore di id.
getlnoff:
	PUSH	BP
	MOV	BP, SP

	MOV	AX, RECORDLEN
	MUL	+4(BP)		! id

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

	! Se open fallisce ritorna -1.
	CMP	AX, -1
	JE	9f

	! Altrimenti, salva il file descriptor e ritorna 0.
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
	MOV	BX, RECORDLEN
	MUL	BX

	POP	BX

	MOV	SP, BP
	POP	BP
	RET


! int loadrom (void)
! Legge tutta la rom e ne salva l'immagine in memoria. Calcola il numero di
! utenti presenti contando le righe del file.
! Ritorna 0 se riesce, -1 se fallisce.
! SIDE EFFECT:
! - salva in numusers il numero di righe lette.
loadrom:
	PUSH	BP
	MOV	BP, SP

	! Lettura di tutto il file.
	PUSH	MAXROMLEN
	PUSH	romimg
	PUSH	(romfd)
	PUSH	_READ
	SYS
	ADD	SP, 8

	! Se _READ ritorna errore, salta alla fine.
	CMP	AX, -1
	JE	9f

	! Calcolo e salvataggio del numero di utenti.
	CALL	getnumus
	MOV	(numusers), AX
	MOV	AX, 0

9:	MOV	SP, BP
	POP	BP
	RET


! int saverom (void)
! Ricrea il file della rom salvando interamente l'immagine della rom in
! memoria.
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

	! Calcolo dimensioni effettive romimg.
	CALL	getromsz

	! Scrittura buffer nel nuovo file.
	PUSH	AX		! dimensione rom
	PUSH	romimg
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


! int romusadd (*newuser, *newpass)
! Aggiunge un nuovo utente a romimg e salva rom.txt
! Ritorna 0 se riesce, -1 se fallisce.
! SIDE EFFECT: incrementa numusers.
romusadd:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX

	! Calcolo dimensione romimg.
	CALL	getromsz
	MOV	BX, AX

	! Puntatore posizionato alla fine di romimg.
	ADD	BX, romimg

	! Inizializzazione spazio nuovo record.
	PUSH	RECORDLEN
	PUSH	0
	PUSH	BX		! romimg + offset
	CALL	memset
	ADD	SP, 6

	! Copia del nome utente all'inizio della riga.
	PUSH	+4(BP)		! newuser
	PUSH	BX		! romimg + offset
	CALL	strcpy
	ADD	SP, 4

	! Puntatore posizionato all'inizio del campo password e copia di
	! newpass.
	! TODO: usare strcpy al posto di memcpy?
	ADD	BX, MAXUSRLEN+1
	PUSH	PASSLEN
	PUSH	+6(BP)
	PUSH	BX
	CALL	memcpy
	ADD	SP, 6

	! Incremento numero di utenti e salvataggio rom.txt.
	INC	(numusers)
	CALL	saverom

	POP	BX

	MOV	SP, BP
	POP	BP
	RET


! int romusdel (id)
! Rimuove la riga numero id da romimg, decrementa il numero di utenti e salva
! rom.txt.
romusdel:
	PUSH	BP
	MOV	BP, SP

	PUSH	BX

	! Calcolo offset riga successiva a quella da rimuovere.
	PUSH	+4(BP)		! id
	CALL	getlnoff
	ADD	SP, 2
	MOV	BX, AX
	ADD	BX, RECORDLEN

	! Calcolo dimensione dati da spostare.
	CALL	getromsz
	SUB	AX, BX

	! Se non ci sono dati da spostare id e' l'ultima riga e si salta la
	! copia.
	CMP	AX, 0
	JE	8f

	! Costruzione puntatore alla riga.
	ADD	BX, romimg

	! Copia delle righe successive alla numero id sulla numero id.
	! Le aree di memoria si sovrappongono ma la copia e' possibile perche'
	! avviene dagli indirizzi piu' alti a quelli piu' bassi.
	PUSH	AX		! dimensione
	PUSH	BX		! riga successiva a quella da rimuovere
	SUB	BX, RECORDLEN
	PUSH	BX		! riga da rimuovere
	CALL	memcpy
	ADD	SP, 6

	! Decremento numero di utenti e salvataggio rom.txt.
8:	DEC	(numusers)
	CALL	saverom

	POP	BX

	MOV	SP, BP
	POP	BP
	RET


! void editpass (id, *newpass)
! Sovrascrive la password della riga id e salva la rom.
editpass:
	PUSH	BP
	MOV	BP, SP

	! Calcolo offset riga.
	PUSH	+4(BP)		! id
	CALL	getlnoff
	ADD	SP, 2

	! Costruzione puntatore al primo carattere della password.
	ADD	AX, MAXUSRLEN+1
	ADD	AX, romimg
	
	! Copia della nuova password in romimg.
	PUSH	PASSLEN
	PUSH	+6(BP)		! newpass
	PUSH	AX		! romimg + offset
	CALL	memcpy
	ADD	SP, 6

	! Salvataggio romimg in rom.txt
	CALL	saverom

	MOV	SP, BP
	POP	BP
	RET


! void inititer (void)
! Inizializza le strutture dati che tengono traccia dell'iterazione sui
! record. Da eseguire prima di ogni nuova iterazione.
inititer:
	PUSH	BP
	MOV	BP, SP

	! Azzera id.
	MOV	(iterid), 0

	! Azzera il buffer.
	PUSH	MAXUSRLEN+1
	PUSH	0
	PUSH	itrusrn
	CALL	memset
	ADD	SP, 6

	! Uno spazio come primo carattere e' utile all'inizio dell'iterazione
	! in ordine alfabetico.
	MOVB	(itrusrn), ' '

	! Idem per itralnxt.
	PUSH	itrusrn
	PUSH	itralnxt
	CALL	strcpy
	ADD	SP, 4

	MOV	SP, BP
	POP	BP
	RET


! int romnext (int mode)
! Passa al nome utente successivo nell'iterazione sui record. Il nome utente
! viene memorizzato nel buffer itrusrn, il suo id in iterid. Se l'iterazione
! e' giunta all'ultimo utente, la funzione ritorna al primo.
! L'argomento mode specifica se avanzare in ordine di inserimento (0) oppure
! alfaberico (1).
! Ritorna l'id utente.
! SIDE EFFECT:
! - modifica iterid, itrusrn e itralnxt
romnext:
	PUSH	BP
	MOV	BP, SP

	! Passa al prossimo id: iterid = (iterid + 1) % numusers
	INC	(iterid)
	MOV	AX, (iterid)
	CMP	AX, (numusers)
	JL	1f
	
	! Se l'iterazione era arrivata alla fine, riparte da 1.
	MOV	(iterid), 1

	! Costruzione puntatore al nome utente.
1:	PUSH	(iterid)
	CALL	getlnoff
	ADD	SP, 2
	ADD	AX, romimg

	! Copia in itrusrn.
	PUSH	AX
	PUSH	itrusrn
	CALL	strcpy
	ADD	SP, 4

	MOV	SP, BP
	POP	BP
	RET


.SECT .DATA
rompath:
	.ASCIZ	"./rom.txt"

.SECT .BSS
romfd:
	.SPACE	2
romimg:
	.SPACE	MAXROMLEN
numusers:
	.SPACE	2

! Buffer per tenere traccia dell'iterazione sui record della rom.
iterid:
	.SPACE	2
itrusrn:
        .SPACE  MAXUSRLEN+1
itralnxt:
        .SPACE  MAXUSRLEN+1
