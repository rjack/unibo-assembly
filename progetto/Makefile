# Makefile per progetto assembly

ASS=as88
BOOT=boot
SOURCES=adm.s drwscr.s file.s io.s kbrd.s menu.s rom.s string.s usr.s
COMMON=defs.h Makefile


.PHONY	: all clean


all	: tags $(BOOT).s $(SOURCES) $(COMMON)
	$(ASS) $(BOOT).s $(SOURCES)


tags	: $(BOOT).s $(SOURCES) $(COMMON)
	ctags -R


clean	:
	rm -f $(BOOT).$$
	rm -f $(BOOT).#
	rm -f $(BOOT).88
	rm -f tags
