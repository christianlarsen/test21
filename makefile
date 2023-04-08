
BIN_LIB=CMPSYS
LIBLIST=$(BIN_LIB) CLV1
SHELL=/QOpenSys/usr/bin/qsh

all: test21.rpgle

test21.sqlrpgle: test21.dspf

%.sqlrpgle:
	system -s "CHGATR OBJ('/home/CLV/test21/qsqlsrc/$*.sqlrpgle') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system "CRTSQLRPGI OBJ($(BIN_LIB)/$*) SRCSTMF('/home/CLV/test21/qsqlsrc/$*.sqlrpgle') COMMIT(*NONE) DBGVIEW(*SOURCE) OPTION(*EVENTF)"

%.rpgle:
	system -s "CHGATR OBJ('/home/CLV/test21/qrpglesrc/$*.rpgle') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system "CRTRPGMOD MODULE($(BIN_LIB)/$*) SRCSTMF('/home/CLV/test21/qrpglesrc/$*.rpgle') DBGVIEW(*SOURCE) OPTION(*EVENTF)"
	system "CRTPGM PGM($(BIN_LIB)/$*) MODULE($(BIN_LIB)/$*) ACTGRP(*NEW)"

%.dspf:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QDDSSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('/home/CLV/test21/qddssrc/$*.dspf') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QDDSSRC.file/$*.mbr') MBROPT(*REPLACE)"
	system -s "CRTDSPF FILE($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QDDSSRC) SRCMBR($*)"