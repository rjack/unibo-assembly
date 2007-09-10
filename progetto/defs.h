	NULL = 0xffff
	
	! file descriptor standard
	STDIN = 0
	STDOUT = 1
	SRDERR = 2
	
	! codici syscall
	_EXIT = 1
	_READ = 3
	_WRITE = 4
	_OPEN = 5
	_CLOSE = 6
	_CREAT = 8
	_LSEEK = 19
	_GETCHAR = 117
	_PUTCHAR = 122
	_PRINTF = 127
	_SPRINTF = 121
	_SSCANF = 125

	! costanti per _READ
	RD = 0
	WR = 1
	RDWR = 2

	! costanti per _LSEEK
	SEEK_SET = 0
	SEEK_CUR = 1
	SEEK_END = 2

	! costanti per seekrom
	ROMEND = -1

	! limiti
	MAXUSERS = 100
	MAXUSRLEN = 16
	PASSLEN = 8
	KEYLEN = 3
	RECORDLEN = 26
	DISPLAYLN = 6
	! RECORDLEN * MAXUSERS
	MAXROMLEN = 2600

	! varie
	ROOTUID = 0
