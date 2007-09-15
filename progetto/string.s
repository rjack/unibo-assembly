! string.s - operazioni su stringhe
!
! Giacomo Ritucci, Paolo Pennestri, 28/07/2007


.SECT .TEXT

! void memset (*buf, ch, buflen)
! Inizializza tutti i buflen byte di buf al carattere ch.
memset:
	PUSH	BP
	MOV	BP, SP

	PUSH	CX
	PUSH	DI

	MOV	CX, +8(BP)	! buflen
	MOVB	AL, +6(BP)	! ch
	MOV	DI, +4(BP)	! buf

	REP	STOSB

	POP	DI
	POP	CX

	MOV	SP, BP
	POP	BP
	RET


! void memcpy (dst, src, n)
! Copia i primi n byte del buffer puntato da src nel buffer puntato da dst, che
! deve essere grande a sufficienza.
memcpy:
	PUSH	BP
	MOV	BP, SP

	! salvataggio registri utilizzati
	PUSH	CX
	PUSH	SI
	PUSH	DI

	! preparazione alla copia
	MOV	DI, +4(BP)	! dst
	MOV	SI, +6(BP)	! src
	MOV	CX, +8(BP)	! numero di byte

	! copia: decrementa CX finche' e' maggiore di 0
	REP	MOVSB

	! ripristino registri utilizzati
	POP	DI
	POP	SI
	POP	CX

	MOV	SP, BP
	POP	BP
	RET


! int strlen (ptr)
! Ritorna la lunghezza della stringa puntata da ptr, terminatore escluso.
strlen:
	PUSH	BP
	MOV	BP, SP

	! salvataggio registri usati
	PUSH	CX
	PUSH	DI

	! preparazione al calcolo
	MOV	AX, 0		! terminatore da cercare
	MOV	CX, -1		! contatore iterazioni
	MOV	DI, +4(BP)	! stringa

	! scansione stringa (decrementa CX)
	REPNZ	SCASB

	! calcolo lunghezza
	NEG	CX
	SUB	CX, 2
	MOV	AX, CX

	! ripristino registri usati
	POP	DI
	POP	CX

	MOV	SP, BP
	POP	BP
	RET


! void strcpy (dst, src)
! Copia la stringa puntata da src, terminatore compreso, nel buffer puntato da
! dst, che deve essere grande a sufficienza.
strcpy:
	PUSH	BP
	MOV	BP, SP

	! lunghezza stringa src in AX, incrementato per contare anche il
	! terminatore
	PUSH	+6(BP)		! src
	CALL	strlen
	ADD	SP, 2
	INC	AX

	! copia usando memcpy
	PUSH	AX		! lunghezza src
	PUSH	+6(BP)		! src
	PUSH	+4(BP)		! dst
	CALL	memcpy
	ADD	SP, 6

	MOV	SP, BP
	POP	BP
	RET

! int memcmp (buf1, buf2, n)
! Confronta i primi n byte dei due buffer.
! Ritorna
! -1 se buf1 e' minore di buf2
!  0 se buf1 e buf2 sono uguali
!  1 se buf1 e' maggiore di buf2
memcmp:
	PUSH	BP
	MOV	BP, SP

	PUSH	CX		! salvataggio
	PUSH	SI
	PUSH	DI

	MOV	AX, 0		! init valore di ritorno

	MOV	CX, +8(BP)	! n
	MOV	DI, +6(BP)	! buf2
	MOV	SI, +4(BP)	! buf1
	
	REPZ	CMPSB
	JE	9f		! str1 == str2
	JG	1f		! str1 > str2
	MOV	AX, -1
	JMP	9f

1:	MOV	AX, 1

9:	POP	DI		! ripristino
	POP	SI
	POP	CX
	
	MOV	SP, BP
	POP	BP
	RET
	

! int strcmp (srt1, str2)
! Confronta le due stringhe, che devono avere il terminatore.
! Ritorna:
! -1 se str1 e' alfabeticamente precedente a str2
!  0 se str1 e' identica a str2
!  1 se str1 e' alfabeticamente successiva a str2.
strcmp:
	PUSH	BP
	MOV	BP, SP

	! Calcolo lunghezza strlen
	PUSH	+4(BP)		! str1
	CALL	strlen
	ADD	SP, 2
	INC	AX		! terminatore incluso

	PUSH	AX		! len
	PUSH	+6(BP)		! str2
	PUSH	+4(BP)		! str1
	CALL	memcmp
	ADD	SP, 6

	! Ritorna quello che viene ritornato da memcmp.
	
	MOV	SP, BP
	POP	BP
	RET
