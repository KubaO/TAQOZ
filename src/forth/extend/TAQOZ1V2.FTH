TAQOZ

{
TAQOZ V1.1 EXTENSIONS
V1.2 integrates kernel components

}
pre '' [C] \ ;
{ NOTE - built back into kernel and into ; word as the immediate word EXIT
--- Compiles an EXIT but first tries to modify a threaded call to a jump
pre EXITS
	@CODES W@ 2- W@ $800 ' !SP WITHIN
	IF @CODES W@ 2- DUP W@ 1 OR SWAP W!
	ELSE ' EXIT [C] [W]
	THEN
	;
}

{
--- set new cfa to point back to DOES: code (skipped by DOES: itself)
pub DOES>	R> 0 REG W@ W! ;
--- create new dev with dummy cfa (save ptr to it)
pub CREATE	HERE [C] CREATE: [C] GRAB HERE 0 REG W! 0_0 [W] ;

pre Q  CREATE [W] DOES> W@ . ;
}

( P2 CONTROL )

$1FA := DIRA
$1FB := DIRB
$1FC := OUTA
$1FD := OUTB
$1FE := INA
$1FF := INB

{

rx_pin		=	63		'pin serial receiver
tx_pin		=	62		'pin serial transmitter
spi_cs		=	61		'pin SPI memory select		(also sd_ck)
spi_ck		=	60		'pin SPI memory clock		(also sd_cs)
spi_di		=	59		'pin SPI memory data in		(also sd_di)
spi_do		=	58		'pin SPI memory data out	(also sd_do)
sd_cs		=	spi_ck
sd_ck		=	spi_cs
sd_di		=	spi_di
sd_do		=	spi_do
}

61	:= SDCK
\ 60	:= SDCS
59	:= SDDI
58	:= SDDO
\ : CHECK SDDI HIGH SDCS HIGH 96 FOR SDCK LOW SDCK HIGH NEXT  .SF ;
\  40 P2MHZ SF? 180 P2MHZ DROP

6	:= KBCLK
7	:= KBDAT
8	:= SCL
9	:= SDA

31	:= AOUTL	--- directly coupled via 220R
30	:= AOUTR
29	:= AINL
28	:= AINR
27	:= USB+		--- via 22R series termination
26	:= USB-
25	:= USB1+
24	:= USB1-
23	:= WIZCE	--- W5500 Ethernet
22	:= WIZDO
21	:= WIZDI
20	:= WIZCK

&23.22.21.20	:= @wizpins


--- EFM88BB10F CHIP ---
57	:= BB02
56	:= BB01
55	:= BB00
54	:= BBGND
53	:= BBVDD
52	:= C2CK
51	:= C2D
50	:= BB13

{
BUGS?
HUBEXEC COG@ in COG DUMP crashes  ( CALL BUG )
$15 IN COG MEMORY ERROR
}

( CLOCK MODES )
---	 1098_7654_321098_7654321098_7654_32_10
---	 0000_000E_DDDDDD_MMMMMMMMMM_PPPP_CC_SS
long _clk  \  _clk ~
long _fin
--- set the
: CLKSET 	_clk @ HUBSET ;
( PLL should run between 100 to 200MHz )
: CLK! ( data mask -- )	_clk @ SWAP ANDN OR _clk ! ;
: PLLEN		24 |< _clk SET ;
: PLLOFF	24 |< _clk CLR ;

: XIDIV ( 1..64 -- ) 	1- $3F AND 18 << $00FC0000 CLK! ;
( ends up as multiply)
: VCOMUL ( 1..1024 -- ) 1- $3FF AND 8 << $3FF00 CLK! ;
--- Divide the PLL by 1 2 4 6 ... 30 for the system clock when SS = %11
: PLLDIV ( 2..30 -- ) 	2/ 1- $0F AND 4 << $0F0 CLK! ;
: CLKSRC	CLKSET DUP 1 > IF 200,000 WAITX THEN 3 AND 3 CLK! CLKSET ;

: USEPLL 	3 CLKSRC ;
: USEXTAL	2 CLKSRC ;
: RCSLOW	1 HUBSET _clk ~ ;
: RCFAST	0 HUBSET _clk ~ ;

: CC		3 AND 2 << $0C CLK! ;
: 15PF		2 CC ;
: 30PF		3 CC ;
: 0PF		1 CC ;
: XPF		0 CC ;

12000000	:= _xin
: XIN		' _xin 2+ ! ;

long _baud 115200 _baud !	( DEFAULT BAUD )

: CONBAUD	DUP _baud ! 63 PIN DUP RXD 62 PIN TXD ;



--- Set P2 CLOCK to selected MHZ ( simple PLL settings only )
: CLOCK ( HZ --- )
	' CLKHZ 2+ !
	_xin @ 20,000,000 =
	IF ( P2-ES )
	  15PF PLLEN 1 XIDIV
	  _xin / VCOMUL 1 PLLDIV USEXTAL
	ELSE
	  30PF PLLEN _xin 1,000,000 U/ XIDIV CLKHZ
	  1,000,000 U/ VCOMUL 1 PLLDIV USEPLL
	THEN
	_baud @ CONBAUD
	;

--- setup for P2-ES instead
: P2-ES		20,000,000 XIN ;
: P2D2		12,000,000 XIN ;




: P2MHZ		M CLOCK ;

: SLOW		40 P2MHZ ;
: ECO		80 P2MHZ ;
: CRUISE	180 P2MHZ ;
: TURBO		250 P2MHZ ;
: RACE		300 P2MHZ ;
: HYPER		340 P2MHZ ;
: FLANK		360 P2MHZ ;

{
: .CLK
	CLKHZ 1 M // 0=
 	IF CLKHZ 1 M U/ . ." MHz" ELSE CLKHZ .DECL ." Hz" THEN
 ;

: .LAP
	LAP@ LAP LAP LAP@ -
	( cycles/clkhz )
	DUP .DECL ."  cycles = "
	1,000,000 CLKHZ 1000 U/ */  ( scale cycles to nanoseconds )
	.DECL ." ns @" .CLK
	;
}


: U.R	<# FOR # NEXT #> PRINT$ ;

{ MEASURE PIN CAPACITANCE AS A FLOAT TO HIGH TIME }
: ?PIN ( pin --  )
	CRLF ." P" DUP . 9 EMIT
	PIN
	0 8 FOR L 100 us F CNT@ BEGIN R UNTIL CNT@ SWAP - ABS + NEXT 3 >>
	10 U.R
	;
: ?PINS ( from for -- ) 	ADO I ?PIN LOOP ;


--- type out printable characters or substitute with a dot
pub .TYPE ( adr cnt -- )	ADO I C@ .EMIT LOOP ;

pri EMIT:	R> uemit W! ;
pri KEY:	R> ukey W! ;
pre TABLE  	HERE 2+ [C] GRAB [C] CREATE: DUP ALLOT ERASE ;



{
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''' SD CARD SUPPORT '''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

$200 REGS
$300..$800 FREE

}



\	org	@sdvars
org@	org ( marks start of block for DATLEN )

0	bytes	sdvars
4	bytes	ocr
16	bytes	cid
16	bytes	csd
	byte	sdcmd
	byte	wrflg
	byte	mntd
	byte	sdcrc
	long	@sdrd
	long	@sdwr
	long	sdsum
	long	seccrc
	long	@sector
64	bytes	parts	--- STATE,[HEAD,[SECT(2),TYPE,HEAD],SECT(2)],1STSECT(4),PARTSEC(4)
				---  00    82    03 00   0B   50    CA C6     $2000  $00ECC000
	long	filesect	--- starting sector of open file'
	long	_fread
	word	_fkey

\ ''''''''''''''''''''''''''''''
\	FAT32
\ ''''''''''''''''''''''''''''''


3	bytes	fat32
8	bytes	oemname
2	bytes	bytesect
1	bytes	sectclust
2	bytes	rsvd
1	bytes	fats
15	res
( 32 )
	long	sdsize		--- Number of sectors * byte/sect (512) = capacity'
	long	sectfat		--- Number of sectors per FAT table'
2	res	fat?		--- fat flags
2	res	fatver		--- fat version
( 44 )
	long	rootcl		--- Cluster Number of the Start of the Root Directory'
2	res	infosect	--- info = Sector Number of the FileSystem Information Sector  (from part start)
2	res	bbssect		--- boot = Sector Number of the Backup Boot Sector (from part start)
12	res
( 64 )
3	res
	long	serial		--- serial number of partition
11	bytes	volname		--- volume name
8	res	fatname		--- always FAT32 - (don't trust)
( 96 )
--- --- --- --- --- --- --- --- --- --- --- --- --- ---
--- create room for some system variables in this table

	long	rootdir		--- sector address of root directory
	long	fat1
	long	fat2
	long	cwdsect
orglen		:= sdsz
cwdsect fat32 - := fatsz

\ ''''''''''''''''''''''''''''''
\ 	DIRECTORY STRUCTURE'
\ ''''''''''''''''''''''''''''''

0	org	--- use relative offsets

8	res	fnam
3	res	fext
1	res	fatr
1	res			\ MUST BE 00'
1	res	fcms
2	res	fctime
2	res	fcdate
2	res	fadate
2	bytes	fch
2	bytes	ftime
2	bytes	fdate
2	bytes	fcl
4	res	fsize

	!org --- reset org back to previous

$10000		:= SDBUF	--- allocate 4k for buffers

pub SDSPI	&60.58.59.61 SPIPINS ;
pub SDCS	' SDSPI 5 + C@ ;
--- set SD PINS
pub SDPINS	' SDSPI :=! ;

pub SD? ( -- flg )
	SDCS LOW 100 WAIT SDCS FLOAT 1000 WAIT SDCS PIN@ SDCS HIGH
 	DUP ?EXIT mntd C~
	;
pri SDCLK	8 CLKS ;
pri SDCLK3	24 CLKS ;
pri TOKEN ( marker -- flgX ) --- clock SD for token but timeout false if not found
	10000 BEGIN OVER 0 SPIRD <> WHILE 100 us 1- DUP 0= IF NIP EXIT THEN REPEAT
	2DROP TRUE
	;
pri !CRC	$95 sdcrc C! ;
pub CMD ( data cmd -- res )
	DUP sdcmd C!
	SDSPI SDCLK
	SPIWC SPIWL sdcrc C@ SPIWB !CRC
pub SDRES
	0 1000 FOR SPIRD >B DUP $FF <> ?NEXT DROP
	;
pub ACMD ( data acmd -- res )
	0 55 CMD DROP CMD
	;

pri SDSTAT ( -- stat ) 0 13 CMD SDRES 8<< OR ;

pri SD4@ ( -- long ) 0 SPIRD SPIRD SPIRD SPIRD ;
pri SDDAT! ( adr -- ) --- read info into memory
	$FE TOKEN IF 16 ADO 0 SPIRD I C! LOOP SDCLK3 THEN DROP
	;


pri !SX
	sdcmd C~~ !CRC 5 FOR 0 0 CMD 1 = ?NEXT 0EXIT
	5 FOR $87 sdcrc C! $1AA 8 CMD 1 = ?NEXT 0EXIT
	SD4@ $1AA = 0EXIT
	0 1000 0 DO 30 |< 41 ACMD IF 200 CLKS ELSE 1+ LEAVE THEN LOOP 0EXIT
	0 58 CMD ?EXIT SD4@ DUP ocr ! 0EXIT
	0 10 CMD 0= IF cid SDDAT! THEN
	0 9 CMD 0= 0EXIT csd SDDAT!
	;

--- Initialise the SD card in SPI mode and return with the OCR
--- pub !SD ( -- ocr|false )
pub !SD
	SDSPI ocr sdsz ERASE
	SDBUF $800 ERASE
	@sector ~~
	SD? IF SDCLK3 20 FOR !SX sdcmd C@ 9 = DUP 0= IF 5000 CLKS THEN ?NEXT DROP
	ocr @ SPICE
	800 CLKS
	;


		--- CARD INFO ---



pri .MAN
	SWITCH
	1 CASE  ." PANASONIC" BREAK
	2 CASE  ." TOSHIBA  " BREAK
	3 CASE  ." SANDISK  " BREAK
	CASE@ 3 U.R ."  BRAND"
	;


pub .SD
---		123456789
	." CARD: " cid C@ .MAN
	SPACE cid 1+ 2 .TYPE
	SPACE cid 3 + 5 .TYPE
	."  REV" cid 8 + C@ .B
	."  #" cid 9 + @ 10 U.R
	."  MADE:" cid 14 + C@ >N 100 * cid 13 + C@ DUP 4 >> 10 * SWAP >N + + 12 U// 2000 + . ." /" .
	cid 15 + 1 AND 0= IF CRLF ." INVALID TERMINATOR " THEN
	;











		--- CARD MEMORY ACCESS ---

pub SDWR ( src sect -- flg  )
	SDCLK3 24 CMD 0=
	  IF SDCLK3 $FE SPIWB 512 SPITX
	    0 TOKEN $FF TOKEN AND
	  ELSE FALSE
	  THEN
	DUP @sdwr ! SPICE
	;
pub SDWRS ( ram sector bytes -- )
	512 ALIGN 9>> ADO DUP I SDWR DROP 512 + !SD DROP LOOP DROP
	SPICE
	;

pub FLUSH ( force -- )
	wrflg C@ OR 0EXIT
	SDBUF @sector @ SDWR DROP wrflg C~
	;

pri SDRDBK ( dst -- crc/flg )
	512 SPIRX sdsum !
	0 SPIRD SPIRD 1 OR
	;

pub SDRD ( sector dst --  )
	SDCLK3
	SWAP 17 CMD DUP 0=
	IF DROP SDRES $FE =
	  IF SDRDBK ELSE SDCLK SDCLK SDSTAT 2DROP 0 THEN
	THEN
	DUP @sdrd ! seccrc !
	SPICE SDCLK
	;



pri SDWAIT --- wait for data token with timeout (only used in SDRDS)
	1000 BEGIN 1- SDRES $FE = OVER 0= OR UNTIL DROP
	;

--- read multiple sectors in continuous multiblock mode
pub SDRDS ( sector dst cnt -- crc | false )
---	convert cnt to sectors '
	512 ALIGN  9>>
---	multiblock read   --  command not accepted '
	-ROT SWAP 18 CMD
	IF 2DROP FALSE
	ELSE
---	process read token and read block if available '
	  SDRES $FE =
	  IF SWAP FOR DUP SDRDBK DROP SDWAIT 512 + NEXT DROP
	  ELSE 2DROP 16 CLKS SDSTAT DROP SPICE FALSE
	  THEN
	THEN
	SDCLK SPICE
	DUP @sdrd !
	2000 BEGIN 1- 0 12 CMD 0= OVER 0= OR UNTIL DROP
	SPICE
	;


pub SECTOR ( sect -- sdbuf )
	@sector @ \ OVER @sector !
	<> IF
pub SECTORF
	0 FLUSH DUP @sector ! SDBUF SDRD
	THEN
	SDBUF
	;

pub @FILE ( -- sector )		filesect @ ;


pub SDADR!
	wrflg C~~
pub SDADR ( sdadr -- ramadr )		L>S @FILE + SECTOR + ;
pub SD@ ( xaddr -- long )		SDADR @ ;
pub SD! ( data xaddr -- )		SDADR ! ;
pub SDC@				SDADR C@ ;
pub SDC!				SDADR! C! ;
pub SDW@				SDADR W@ ;
pub SD					DUMP: SDC@ SDW@ SD@ ;

\ pre [+]		@CODES 2- W@ $3FF AND @CODES 4 - W+! -2 @CODES W+! ;

pub @ROOT				rootdir @ ;
pub @BOOT				parts 8 + @ ;
pub @FAT ( fat# -- sector )		sectfat @ * @BOOT rsvd W@ + + ;
pub ROOT				@ROOT
pri FOPENS1				_fread ~ filesect ! ;

pub CWD! ( sect str -- )		cwdsect ! ;

pub CLUST>SECT ( clust# -- sector )	rootcl @ -
pri CL>SECT2				sectclust C@ * @BOOT + ;


pub RDFAT
	@BOOT SECTORF fat32 90 CMOVE
	rsvd W@ sectfat @ fats C@ *
	rootcl @ 2- CL>SECT2 + +
	rootdir !
---	'' save time by precalculating FAT table addresses
	0 @FAT fat1 ! 1 @FAT fat2 !
	;

---	MOUNT FAT32 if not already mounted
pub ?MOUNT
	SD? 0EXIT mntd C@ ?EXIT
pub MOUNT
	!SD 0= 2 ?ERROR
	0 SECTORF $1FE + W@ $AA55 <> 3 ?ERROR
	CRLF .SD
	fat32 fatsz ERASE
	SDBUF $1BE + parts 64 CMOVE
	RDFAT
	ROOT mntd C~~
pub .FAT
\	CRLF
	parts 4 + C@ DUP 11 12 WITHIN IF ."  FAT32 " 12 = IF ." LBA " THEN
	serial @ .L SPACE volname 11 .TYPE
	sectclust C@ 2/ . ." k cluster "
	SPACE sdsize @ 11 >> .DECL ." M size "
	ELSE DUP 6 = IF DROP ." - FAT16 " ELSE .AS"  - TYPE### NON-FAT32 " THEN 1 4 ?ERROR THEN
\	CNT@ 1 SECTOR DROP CNT@ SWAP - ABS CLKHZ 1000000 / / .AS" -- speed = #,##~#us"
	CNT@ 1 SDBUF SDRD CNT@ SWAP - ABS CLKHZ 1000000 / / .AS"  *|#us speed"

	;


{
20 .AS" #~#.# '"

TYPE
11	FAT32 CHS
12	FAT32 LBA


CARD: SU04G SD03.80 #C195.DBB1 2013/6 !C0FF.80B9 1,912us
FAT: #E3FE.D79D mkfs.fat WIDGET      FAT32   3,965,190,144 bytes (4kB clusters)
								 UUID
CARD: SANDISK   SD SL08G REV$80 #0168665696 DATE=2016/9 - FAT32: $63FE_C331 P2D2       32k 7,576M ok
FIRST SECTOR 8192
LAST SECTOR 15523839
TOTAL 15515648


HEADS 255
SECT/TRACK 63
CYLINDERS 966
TOTAL SECTORS 15523840
SECTOR SIZE 512

BOOT
0001_0000: EB 00 90 4D  53 57 49 4E  34 2E 31 00  02 40 34 11     '...MSWIN4.1..@4.'
0001_0010: 02 00 00 00  00 F8 00 00  3F 00 FF 00  00 20 00 00     '........?.... ..'
0001_0020: 00 C0 EC 00  66 07 00 00  00 00 00 00  02 00 00 00     '....f...........'
0001_0030: 01 00 06 00  00 00 00 00  00 00 00 00  00 00 00 00     '................'
0001_0040: 80 01 29 14  7F 5F 5E 54  41 51 4F 5A  20 20 20 20     '..).._^TAQOZ    '
0001_0050: 20 20 46 41  54 33 32 20  20 20 F4 F4  F4 F4 F4 F4     '  FAT32   ......'
0001_0060: F4 F4 F4 F4  F4 F4 F4 F4  F4 F4 F4 F4  F4 F4 F4 F4     '................'


--- STATE,[HEAD,[SECT(2),TYPE,HEAD],SECT(2)],1STSECT(4),PARTSEC(4)
---  00    82    $0003    0B   50    $C6CA    $00002000  $00ECC000
	   0  1  2  3   4  5  6  7   8  9  A  B   C  D  E  F
0001_01BE: 00 82 03 00  0B 50 CA C6  00 20 00 00  00 C0 EC 00     '.....P... ......' ok

	   80 47 04 01 06 20  E0 90 FC 30  00 00 04 0F  EE 00

pub .PARTS
	0 SECTOR $1BE +
	4 0 DO DUP @ IF CRLF ." PART " I . SPACE
	DUP C@ IF ." ACTIVE " ELSE ." INACTIVE " THEN
	DUP 1+ C@
	THEN
	16 +
	LOOP
	DROP
	;
}



pub FOPENS ( sect -- )		?MOUNT FOPENS1 ;
\ FOPENS	word	MOUNTQ
\ FOPEN1	word	w+_fread,CLRL,w+filesect,STOREX+ex


pub FSECT ( diradr -- sector ) --- Lookup starting sector from dir entry
	fcl OVER+ W@ SWAP fch + W@ W>L
pub C>S
 	rootcl @ - sectclust C@ * @ROOT +
	;


{
' RDDIR - read root dir entries and process as name/sector/size into fast access buffer
RDROOT	word	ATROOT
	word	DUP,SECTOR,w+16,ADO,I
	word	ATROOT,ROOTBUF,_WORD,$800,SDRDS,DROP
}
'' DIR '
'' FORMAT: 21: BIRD    .BMP $0002_89A8   2018.12.24.14.21   BMz.......z...l.   308,346



\ pri .DIRX			CRLF I .AS" ##\#:" SPACE ;

pri DIRX0
	0
pri DIRX ( offset --- hubadr ) --- return with the indexed directory plus offset in hub RAM
	I 5 << + ROOT SDADR
	;

pub .NAME
	DIRX0 8 .TYPE
	8 DIRX C@ $20 <> IF '.' EMIT 8 DIRX 3 .TYPE EXIT THEN
pri 3S	3 SPACES
	;
\ pub .HDR	DIRX0 FSECT FOPENS1 0 SDADR 16 ADO I C@ .EMIT LOOP ;

\ pub .SIZE	28 DIRX @ .DECL ;

pub .DATE
	fdate DIRX DUP W@ DUP 9>> 1980 + .DEC4
	5 >> >N .DEC2 $1F AND .DEC2
	ftime DIRX W@ DUP 11 >> .DEC2
	5 >> $3F AND .DEC2
	;

word f?
--- Print dir entry rg+1=mode
pri .ENT
	8 f? SET? IF CRLF I .AS" ##\#:" SPACE THEN
	.NAME 8 f? SET? ( ls or dir ? )
	IF
	  DIRX0 FSECT .L 3S .DATE
	  3S DIRX0 FSECT FOPENS1 0 SDADR 16 ADO I C@ .EMIT LOOP
	  3S 28 DIRX @ .DECL EXIT
	THEN
	f? C++ f? C@ 7 AND ?EXIT CRLF
	;


pub ls
	CRLF ?MOUNT f? W~ GOTO
pub DIR
	8 f? W!
	?MOUNT CRLF .FAT
---	scan root directory from start sector for max dir entries (index)
	THEN
	0 sectclust C@ 4 << ADO
---	Look for a valid dir entry and print it '
	DIRX0 C@ $20 $7E WITHIN IF .ENT THEN
	LOOP SPACE
	;






pub FLOAD ( sector -- ) --- load file as console input then restore on null to console input '
	FOPENS ukey W@ _fkey W!
	KEY:
pub FGET ( -- ch ) --- Read the next byte from the file
	_fread @ SDC@ ?DUP
	IF
\	  DUP $0A = IF DROP $0D THEN
	_fread ++ EXIT
	THEN
	_fkey W@ ukey W! _fkey W~
	FALSE
	;

pub FREAD ( sdsrc hubdst bytes -- )
	4 ALIGN ADO I OVER+ SD@ I ! 4 +LOOP DROP
	;
pub FWRITE ( hubsrc sddst bytes -- )
	4 ALIGN ADO I OVER+ @ I SD! 4 +LOOP DROP
	;


{
' RENAME THE CURRENTLY OPEN FILE'
RENAME
: FNAME		GETWORD
FNAME	word	GETWORD

To print a file:
$1B780 FOPEN 0 SD PRINT$

}


\ : DIROPEN	@ROOT FOPENS ;

--- FSECT ( diradr -- sector )
--- @FILE ( -- sector )

{ dir structure
fnam		res	8
fext		res	3
fatr		res	1
		res	1	' MUST BE 00'
fcms		res	1
fctime		res	2
fcdate		res	2
fadate		res	2
fclsth		res	2
ftime		res	2
fdate		res	2
fclstl		res	2
fsize		res	4
}
0 bytes dirbuf
8 bytes fname
3 bytes ext
1 bytes atr
4 bytes


pub >F83 ( str -- buf )
	fname 12 $20 FILL  fname 11 + C~
---	str buf
	fname OVER LEN$ 0 DO
	  OVER I+ C@ DUP 'a' 'z' WITHIN IF $20 - THEN
	  DUP '.' = IF 2DROP ext ELSE OVER C! 1+ THEN
	LOOP
	2DROP fname
	;

byte cflg
pub COMPARE ( adr1 adr2 cnt -- flg )	cflg C~~ ADO DUP C@ I C@ <> IF cflg C~ LEAVE THEN 1+ LOOP DROP cflg C@ 0<> ;

--- compare file name at dirptr with fname
pub FNAME= ( dirptr -- flg )	fname 11 COMPARE ;

--- find current f83 name and return with file offset to directory entry
pri FINDSD ( -- sdrel )
	ROOT
	0 BEGIN DUP SDADR FNAME= NOT WHILE DUP SDADR C@ 0= IF DROP 0 EXIT THEN 32 + REPEAT
	SDADR
	;

pub FOPEN# ( index -- )	ROOT 5 << SDADR FSECT FOPENS ;

pre FOPEN	GET$
pub FOPEN$ ( str -- )
	>F83 DROP FINDSD ?DUP IF FSECT ELSE 0 THEN FOPENS
	;



pri FLOAD1	FLOAD ;
pre FLOAD ( <name> -- )		[C] FOPEN @FILE FLOAD1 ;

pub GETFNAME	GET$ >F83 ;


pre RENAME# ( dir# <new> -- )
	[C] GRAB GETFNAME ROOT SWAP 5 << SDADR 11 CMOVE 1 FLUSH
	;

pre RENAME ( <old> <new> -- )
	GETFNAME DROP FINDSD ?DUP IF GETFNAME SWAP 11 CMOVE 1 FLUSH ELSE ."  NOT FOUND " THEN
	;

pre cat		[C] FOPEN 0 SD PRINT$ ;

pre QV		[C] FOPEN 0 SDADR $80 DUMP ;

pub FL	;
pub OPENBOOT	" _BOOT_P2.BIX" FOPEN$ @FILE ;

pub MAKEBOOT	OPENBOOT ?DUP IF 0 SWAP $2.0000 SDWRS THEN ;

\ pub MAKEBOOT	OPENBOOT ?DUP IF 0 SWAP 256 ADO DUP I SDWR 1 AND . 512 + LOOP DROP THEN ;

\ $9658 0 $20000 ADO !SD DROP I $1FF AND 0= IF I OVER SDWR 1& . 1+ 512 +LOOP FLUSH DROP






	(	*** VIDEO ***	 )

{
bmpint		= $00
bmppal		= $100
bmppic		= $500
}

$3.0000 	:= BMP
BMP 		:= INT
INT 1+		:= INTON
BMP 6 +		:= VCNT
BMP $100 + 	:= PALETTE		--- palette in RAM $xxRRGGBB
PALETTE $400 +	:= SCR
640 		:= cols
480 		:= rows
cols rows *	:= SCRSZ
SCRSZ $400 +	:= BMPSZ
0		:= lm
cols 1-		:= rm



: BRIGHTER ( n -- )	INT C+! ;
: FADE			BEGIN INT C@ WHILE -1 BRIGHTER 1 ms REPEAT ;

: SYNCH			1
: FRAMES ( cnt -- )	VCNT W@ + >W BEGIN DUP VCNT W@ = UNTIL DROP ;

: HIDE			0 INT C! ;
: SHOW			SYNCH INTON C@ INT C! ;

word _x
word _x1
word _y
word _y1
word width
word height
long scr'

: X@			_x W@ ;
: Y@			_y W@ ;
: x			DUP _x W! _x1 W! ;
: y			DUP _y W! _y1 W! ;
: w			width W! ;
: h			height W! ;

: @XY			y x ;

: XY!			_y1 W! _x1 W! ;
: XY@!			X@ Y@ XY! ;
: !XY			_x1 W@ _x W! _y1 W@ _y W! ;
: X+!			_x W+! X@ cols => IF _x W~ _y W++ THEN  ;
: Y+!			_y W+! Y@ rows => IF _y W~ THEN ;

: CENTER		cols 2/ rows 2/ @XY ;
: TL			0 0 @XY ;
: TR			cols 1- 0 @XY ;
: BL			0 rows 1- @XY ;
: BR			cols 1- 0 @XY ;

byte _paper
byte _pen
byte _paper1
byte _pen1

: PEN			_pen C! ;
: PAPER			_paper C! ;
: PEN@			_pen C@ ;
: PAPER@		_paper W@ ;
: >PEN			PEN@ _pen1 C! PEN ;
: PEN>			_pen1 C@ PEN ;

--- write color to pixel at XY - do not change XY - update scr' pointer
pub PIXEL! ( pen -- )	X@ Y@
pub PLOT ( pen x y -- )	cols W* + SCR + DUP scr' ! C! ;

: COLORS		PALETTE 1024 ;

0	:= black
$E0	:= red
$1C	:= green
$F8	:= yellow
$03	:= blue
$1F	:= cyan
$E3	:= magenta
$FF	:= white
$25	:= coal
$49	:= gray
$65	:= brown


: PLAIN			white PEN black PAPER ;
: REVERSE		PEN@ PAPER@ PEN PAPER ;



: RGB> ( rgb -- r g b )		DUP 16>> >B OVER 8>> >B ROT >B ;
: >RGB ( r g b -- rgb )		ROT 8<< ROT + 8<< + ;


: !PALETTE	256 0 DO I 5 >> 7 AND 36 W*    I 2 >> 7 AND 36 W* I 3 AND 84 W* >RGB I 4* PALETTE + ! LOOP ;

( themes )
: MAC			!PALETTE black PEN white PAPER ;
: -TERM			!PALETTE green PEN 4 paper ;
: -C64			!PALETTE white pen blue paper ;

: -BEST
	0 0 256 0 DO I 4* PALETTE + @ RGB> + + 2DUP < IF -ROT 2DROP I SWAP ELSE DROP THEN LOOP DROP PEN
	0 $FFFFFF 256 0 DO I 4* PALETTE + @ RGB> + + 2DUP > IF -ROT 2DROP I SWAP ELSE DROP THEN LOOP DROP PAPER
	;

word X2
word Y2
word Y+-
word X+-

--- simple line draw in 1st octant - continue to draw a line to these coordinates
: LINETO ( x2 y2 -- )
	Y2 W! X2 W!
	1 Y2 W@ Y@ < IF NEGATE THEN Y+- W!
	1 X2 W@ X@ < IF NEGATE THEN X+- W!
	Y2 W@ Y@ - ( dy )
	X2 W@ X@ - ( dy dx )
	OVER 2* OVER - ( dy dx d )
	BEGIN
	  X@ X2 W@ <=
	WHILE
	  PEN@ PIXEL!
	  X+- W@ X+!
	  DUP 0< IF 3RD 2* + ELSE 3RD 3RD - 2* + Y+- W@ Y+! THEN
	REPEAT
	3DROP
	;

: HLINE ( -- )	width W@ PEN@ PIXEL! scr' @ DUP 1+ ROT CMOVE ; \ X+! ;

: VLINE ( -- )	height W@ FOR PEN@ PIXEL! 1 Y+! NEXT !XY ;


: RECT ( color -- )  		HLINE VLINE width W@ X+! HLINE !XY height W@ Y+! VLINE !XY ;

: PANEL ( color -- ) 		>PEN height W@ FOR _x1 W@ _x W! HLINE 1 Y+! NEXT PEN> ;

{
: PANEL ( width height color -- ) 	>PEN FOR _x1 W@ _x W! DUP HLINE 1 Y+! NEXT DROP PEN> ;

40 X 40 Y 200 W 100 H RED PANEL

}

: BUTTON ( width height -- ) 	2DUP RECT !XY 1 X+! 1 Y+! XY@! 2DUP 2- SWAP 2- SWAP RECT !XY 3 X+! 3 Y+! XY@! 8 - SWAP 8 - SWAP PANEL ;
\ 100 100 @XY 100 50 BUTTON

\ : FRAMED ( width height -- )	$FF PEN 2DUP PANEL $20 PEN !XY 10 _x1 W+! 10 _y W+! 20 - SWAP 20 - SWAP PANEL ;

: DEMO		80 1 DO I 2* DUP x y i 4* DUP w h I 3 W*  PANEL 4 +LOOP ;

: HVFLIP	SCR DUP SCRSZ + 1- SCRSZ 2/
: XFLIP		FOR OVER C@ OVER C@ 4TH C! OVER C! 1- SWAP 1+ SWAP NEXT 2DROP ;
: HFLIP		rows 0 DO I cols W* SCR + DUP cols 1- + cols 2/ XFLIP LOOP ;

$1.F000		:= BUFFER

: V
: VFLIP
	HIDE
	SCR DUP rows 1- cols W* +
	BEGIN
	  DUP BUFFER cols 4/ LMOVE 2DUP cols 4/ LMOVE BUFFER 3RD cols 4/ LMOVE
	  cols - SWAP cols + SWAP
	  2DUP >
	UNTIL
	2DROP
	SHOW
	;


: CS
: CLRSCR	PAPER@
: VFILL 	SCR SCRSZ ROT FILL !PALETTE 0 lm :=! ;

{ display palette colors
: XX 	CLRSCR SCR SCRSZ ROT FILL ;
CLRSCR 512 0 DO I 0 @XY I 2/ PEN 10 VLINE LOOP
CLRSCR 256 0 DO 0 I @XY I PEN 640 HLINE LOOP
CLRSCR 256 0 DO I >N 40 * I 4 >> 30 * @XY I PEN 40 30 PANEL LOOP
}

(		BMP VIEWER		)

{
00000: 4D42 B47A 0004 0000  0000 047A 0000 006C     'BMz.......z...l.'
00010: 0000 0280 0000 01E0  0000 0001 0008 0000     '................'
00020: 0000 B000 0004 0B13  0000 0B13 0000 0100     '................'
00030: 0000 0100 0000 4742  7352 0000 0000 0000     '......BGRs......'
00040: 0000 0000 0000 0000  0000 0000 0000 0000     '................'
00050: 0000 0000 0000 0000  0000 0000 0000 0000     '................'
00060: 0000 0000 0000 0000  0000 0002 0000 0000     '................'
00070: 0000 0000 0000 0000  0000 0C0C 000C 5028     '..............(P' ok

BMP FILE FORMAT
0		BM	SIGNATURE
2		$04B47A	FILE SIZE	(308,346)
6		$0000	RES1
8		$0000	RES2
$0A		$047A	PIXELARRAY OFFSET

$0E		DIB HEADER

$12		HORZ RES
$16		VERT RES
$1C		8
}


14 bytes V$

pub $+ ( str1 str2 -- str1 )	OVER DUP LEN$ + OVER LEN$ 1+ CMOVE ;

pub VIEWSEC ( sector -- )
---	read file header and align file palette to memory palette then read all
	?DUP IF
	  CLRSCR DUP FOPENS
	  PALETTE 10 SDW@ $400 - - BMPSZ 511 + HIDE SDRDS
	  $32 SDW@ IF 256 $32 SDW@ - ?DUP IF 4* PALETTE OVER + PALETTE ROT 1024 SWAP - CMOVE THEN THEN
	  SHOW
	  THEN
	;
pre VIEW ( <name> --- )
	GET$
pub VIEW$ ( str -- )
	DUP UPPER$ V$ $!
	V$ " .BMP" $+ FOPEN$ @FILE ?DUP IF VIEWSEC VFLIP ( @FILE ."  AT " .L ) THEN
	;

(		SOME DEMO WORDS 	)

pub SLIDESHOW ( frames -- )
	BEGIN
	0
	  BEGIN
	    ROOT DUP SDC@
	  WHILE
	    DUP 8 + SD@ 24 BITS " BMP" @ = IF DUP SDADR FSECT VIEWSEC VFLIP OVER FRAMES THEN
	    32 +
	  REPEAT
	  DROP
	  KEY
	UNTIL DROP
	;


100 INTON C! SHOW	--- show VGA

: PALMASK ( mask -- )		COLORS ADO I @ OVER AND I ! 4 +LOOP DROP ;

: SHADOWS ( val -- )		COLORS ADO I @ RGB> 3 FOR 4TH OVER > IF DROP 0 THEN ROT NEXT >RGB I ! 4 +LOOP DROP ;

: N
: NEGATIVE			COLORS ADO I @ NOT I ! 4 +LOOP ;

byte gam*
byte gam/
byte _th

--- simple gamma routine
: GAMMA ( gamma* gamma/ thresh< -- )
	_th C! gam/ C! gam* C!
	PALETTE $400 ADO
	  I @ RGB> ( split into components )
	  3 FOR DUP _th C@ < IF gam* C@ gam/ C@ */ THEN ROT NEXT
	  >RGB I ! ( recombine rgb and update )
	4 +LOOP DROP
	;


: SUBS	( old new -- )		COLORS ADO OVER I @ = IF I ! LEAVE THEN 4 +LOOP DROP ;




(  FILE CONTROL )

\ pri ERPAGE ( page pages -- )	ADO I 16 << SFER64 200 ms LOOP ;
\ pub BACKUP			$0E 2 ERPAGE " TAQO" $F.FFFC $! 0 $0E.0000 $2.0000 SFWRS ;


\ pub SAVE			$03.0000 SCRSZ $47A + ADO I SFER64 200 ms I I SFWRS $10000 +LOOP ;
\ : MAKEBOOT ( sector -- )	FOPENS  ;









(		VGA BITMAP TEXT		)

96 7 * TABLE FONT5X7

FONT5X7 $20 7 * -	:= FONT5X7A

10 	:= lsp	--- line space constant'
6	:= csp	--- character space constant

--- User commands to change line and character spacing
: LSP ( n -- )	' lsp :=! ;
: CSP ( n -- )	' csp :=! ;

long col
long col1
long row
long row1
byte vflg	--- 0= noscroll
byte _scrolls

'' bytes/line of text
: b/l ( -- bytes )	cols lsp W* ;


--- setup _scr to point to screen at current row and column
pri @RC 			col @ row @ cols W* + SCR + scr' ! ;
\ pri @FONT ( ascii -- chadr ) 	>B $20 - 7 * FONT5X7 + ;


pub VXY    ( x y -- )	row ! col ! ;
pub VXY>		col1 @ row1 @ VXY ;
pub >VXY		col @ col1 ! row1 @ row1 ! ;

pub BOTTOM		0 rows lsp - VXY ;

--- Set how many rows the terminal will use where 0 = all
pub NS			0
pub TERM ( lines -- )	rows lsp / MIN _scrolls C! 0 rows lsp - VXY csp 1- ' lm :=! ;

pri VHOME		0 TERM 0 0 VXY 480 lsp / _scrolls C! ;


pri SCROLL
	_scrolls C@ IF SCR SCRSZ + b/l _scrolls C@ W* - DUP b/l + SWAP b/l _scrolls C@ 1- W* 4/ LMOVE THEN
	SCR SCRSZ + b/l - b/l PAPER@ FILL
	lsp NEGATE row +!
	;

pri NEWLINE
    lm col !
    lsp row +!
    row @ lsp 1- + rows => IF SCROLL THEN
    ;



--- Display the VGA character and update position etc
{  original method w/o assembly support
pub VCH1 ( ch -- ) --- 97.8us
     --- new line if needed (scrolls up if needed)
     ?NEWLINE @RC
     _pen C@ PAPER@ ROT
     @FONT 7 ADO I C@ REV 27 >>
       scr' @ csp ADO 1 ROR? IF 3RD ELSE OVER THEN I C! LOOP
       DROP cols scr' +!
     LOOP
     csp col +! 2DROP
     ;
}

--- draw a 5X7 font character
pub VCH ( char -- ) --- 8.750us @300MHZ
	7 W* FONT5X7A +
	col @ rm => IF NEWLINE THEN
	col @ row @ cols W* + SCR +
	PAPER@
	WRCH ( font' screen' pen.paper  -- )
	csp col +!
	;


: BELL 	NOP ;

--- make the VGA display the current output device
pub VGA
    EMIT:
pub VEMIT ( ch -- )
    DUP 32 <
    IF
    SWITCH
      $00 CASE BREAK
      $01 CASE VHOME BREAK
      $07 CASE BELL BREAK
      $08 CASE col @ lm <> IF csp NEGATE col +! THEN BREAK
      $09 CASE  BEGIN 32 VCH col @ csp / 7 AND 0= UNTIL BREAK
      $0A CASE NEWLINE BREAK
      $0C CASE CLRSCR VHOME BREAK
      $0D CASE lm col ! BREAK
\      $1B CASE 2 vflg SET BREAK                    --- ESC will accept next byte as data
 \     $10 $17 CASES SWITCH@ HUE BREAK        --- codes $10..$17 select a color
\     $18 CASE $80 vflg CLR BREAK                --- wrap
\     $19 CASE $80 vflg SET BREAK                --- no word wrap
\    1 vflg CLR
\      CASE@ REVERSE -2 row W+! .BYTE 2 row W+! REVERSE EXIT
	CASE@ ( unknown control - display as character )
    THEN
    VCH
    ;


( temporary font generator )

pub CH
	$20 - 7 W* FONT5X7 + SWAP ( adr str ) 1+
	7 FOR
	 0 OVER 5 ADO 2* I C@ 1 AND OR LOOP ( adr str val )
	 REV 27 >>
	 3RD C! ( adr str ) 5 + SWAP 1+ SWAP
	NEXT
	2DROP
	;

"  00000000000000000000000000000000000" $20 CH
"  00100001000010000100001000000000100" $21 CH
"  01010010100101000000000000000000000" $22 CH
"  01010010101111101010111110101001010" $23 CH
"  00100011111010001110001011111000100" $24 CH
"  11000110010001000100010001001100011" $25 CH
"  01100100101010001000101011001001101" $26 CH
"  01100001000100000000000000000000000" $27 CH
"  00010001000100001000010000010000010" $28 CH
"  01000001000001000010000100010001000" $29 CH
"  00000001001010101110101010010000000" $2A CH
"  00000001000010011111001000010000000" $2B CH
"  00000000000000000000011000010001000" $2C CH
"  00000000000000011111000000000000000" $2D CH
"  00000000000000000000000000110001100" $2E CH
"  00000000010001000100010001000000000" $2F CH
"  01110100011001110101110011000101110" $30 CH
"  00100011000010000100001000010001110" $31 CH
"  01110100010000100010001000100011111" $32 CH
"  11111000100010000010000011000101110" $33 CH
"  00010001100101010010111110001000010" $34 CH
"  11111100001111000001000011000101110" $35 CH
"  00110010001000011110100011000101110" $36 CH
"  11111100010000100010001000010000100" $37 CH
"  01110100011000101110100011000101110" $38 CH
"  01110100011000101111000010001001100" $39 CH
"  00000011000110000000011000110000000" $3A CH
"  00000011000110000000011000010001000" $3B CH
"  00010001000100010000010000010000010" $3C CH
"  00000000001111111111000000000000000" $3D CH
"  01000001000001000001000100010001000" $3E CH
"  01110100010000100010001000000000100" $3F CH

\ "  01110100010000101101101011010101110" $40 CH
"  01110101011010110110100001000101110" $40 CH
"  01110100011000110001111111000110001" $41 CH
"  11110100011000111110100011000111110" $42 CH
"  01110100011000010000100001000101110" $43 CH
"  11100100101000110001100011001011100" $44 CH
"  11111100001000011110100001000011111" $45 CH
"  11111100001000011110100001000010000" $46 CH
"  01110100011000010111100011000101111" $47 CH
"  10001100011000111111100011000110001" $48 CH
"  01110001000010000100001000010001110" $49 CH
"  00111000100001000010000101001001100" $4A CH
"  10001100101010011000101001001010001" $4B CH
"  10000100001000010000100001000011111" $4C CH
"  10001110111010110101100011000110001" $4D CH
"  10001100011100110101100111000110001" $4E CH
"  01110100011000110001100011000101110" $4F CH
"  11110100011000111110100001000010000" $50 CH
"  01110100011000110001101011001001101" $51 CH
"  11110100011000111110101001001010001" $52 CH
"  01111100001000001110000010000111110" $53 CH
"  11111001000010000100001000010000100" $54 CH
"  10001100011000110001100011000101110" $55 CH
"  10001100011000110001100010101000100" $56 CH
"  10001100011000110101101011010101010" $57 CH
"  10001100010101000100010101000110001" $58 CH
"  10001100011000101010001000010000100" $59 CH
"  11111000010001000100010001000011111" $5A CH
"  11100100001000010000100001000011100" $5B CH
"  10000100000100000100000100000100001" $5C CH
"  00111000010000100001000010000100111" $5D CH
"  00100010101000100000000000000000000" $5E CH
"  00000000000000000000000000000011111" $5F CH
\ $60..$7f							\  not all characters have been converted yet
"  01000001000001000000000000000000000" $60 CH
"  00000000000111000001011111000101110" $61 CH
"  10000100001011011001100011000111110" $62 CH
"  00000000000111010000100001000101110" $63 CH
"  00001000010110110011100011000101111" $64 CH
"  00000000000111010001111111000001110" $65 CH
"  00110010010100011110010000100001000" $66 CH
"  00000011111000110001011110000101110" $67 CH
"  10000100001011011001100011000110001" $68 CH
"  00100000000110000100001000010001110" $69 CH
"  00010000000001000010000101001001100" $6A CH
"  10000100001001010100110001010010010" $6B CH

"  00000011000010000100001000010001110" $6C CH
"  00000000000101010101101011010110101" $6D CH
"  00000000001011010001100011000110001" $6E CH
"  00000000000011001001010010100100110" $6F CH
"  00000000001011011001100011111010000" $70 CH
"  00000000000110110011011110000100001" $71 CH
"  00000000001011011001100001000010000" $72 CH
"  00000000000111010000011100000111110" $73 CH
"  00000001000111100100001000010000010" $74 CH
"  00000000001000110001100011000101110" $75 CH
"  00000000001000110001010100101000100" $76 CH
"  00000000001010110101101011010101010" $77 CH
"  00000000001000101010001000101010001" $78 CH
"  00000000001000110001010100010001100" $79 CH
"  00000000001111100010001000100011111" $7A CH
"  00110001000010011000001000010000110" $7B CH
"  00100001000010000100001000010000100" $7C CH
"  01100001000010000011001000010011100" $7D CH
"  00000000000101010100000000000000000" $7E CH
"  11111111111111111111111111111111111" $7F CH

FORGET CH ( remove compile helper )

: fibo ( n -- f )  	0 1 ROT FOR BOUNDS NEXT DROP ;

: fibos  1 46 ADO CRLF ." fibo(" I . ." ) = " LAP I fibo  LAP .LAP ."  result =" . 5 +LOOP ;
{
: FIB ( x -- y )
	DUP 2 > IF DUP  1- FIB
		   SWAP 2- FIB +  EXIT
	     THEN
	DROP 1
	;
}


( SMART PINS )
{
 %AAAA_BBBB_FFF_PPPPPPPPPPPPP_TT_MMMMM_0
}

\ ' 12-bit analog to digital to analog, 19.5k samples/second

pub DAC ( bits -- )	%101000000000001000110 WRPIN |< WXPIN L ;

pub ADC12
	@PIN DUP 1+ PIN %100011000000000000000 WRPIN
  	PIN %10000000000000000000000011000 WRPIN 4096 WXPIN L
	;


long kbs
0 |<	:= caps	--- caps lock
1 |<	:= lsk	--- left shift key
2 |<	:= rsk	--- right shift key
3 |<	:= lck	--- left ctrl
4 |<	:= rck	--- right ctrl
5 |<	:= lak	--- left alt
6 |<	:= rak	--- right alt

2 longs kbk	--- sequence of KEY# codes - lsb = latest

{
$14	left ctrl
$58	caps
$12	LEFT SHIFT
$59	RIGHT SHIFT
$11	LEFT ALT
$E0 11	RIHT ALT

}
256 TABLE kbtbl

--- receive PS/2 data from smartpin and right justify
pri RXKB ( -- KEY# )	KBDAT PIN R IF RDPIN 23 >> ELSE 0 THEN >B ;

pri MAKE?			kbk 1+ C@ $F0 <> ;
pri KBRK			kbs MAKE? IF SET ELSE CLR THEN 0 ;

--- get KEY#ode but process and filter break codes
pri KEY#@
	RXKB DUP
	IF DUP SWITCH kbk kbk 1+ 7 <CMOVE kbk C!	\ kbk @ 8<< OR kbk !
	$14 CASE lck KBRK BREAK
	$12 CASE lsk KBRK BREAK
	$59 CASE rsk KBRK BREAK
	$58 CASE MAKE? IF kbs C@ 1 XOR kbs C! THEN 0 BREAK
---	ignore break codes and keys          use key  else no key
	kbk 1+ C@ $F0 <> kbk C@ $F0 <> AND IF kbk C@  ELSE 0 THEN
	THEN
	;

12250 := kbb --- keyboard baud rate
\ 11350 := kbb --- keyboard baud rate

--- setup P7 for PS/2 keyboard data
pri !KB			KBDAT PIN F 9 BIT kbb RXD H ;

pub KB	KEY:
--- select PS/2 keyboard in tandem with console as input
pri KB@
---	KEY#ode + shift
	KEY#@ kbs C@ 6 AND IF $80 + THEN
---	lookup      and apply shift if necessary
	kbtbl + C@   DUP 'a' 'z' WITHIN kbs C@ 1 AND AND IF $20 - THEN
---	and trim if control pressed
	lck kbs SET? IF $1F AND THEN
	;

pub CONKB		KEY: KB@ DUP 0= IF DROP CONKEY THEN ;
pub CONVGA		EMIT: DUP CONEMIT VEMIT ;
pub PC			CONKB CONVGA ;

( configure TAQOZ to use VGA and PS/2 keyboard for its console - as well as the serial input )
pub P2PC
	!KB PC MAC CLS 100 INTON C! -C64 8 SPACES ." PARALLAX P2 TAQOZ PC " 8 SPACES
	SD? IF MOUNT MAC ls THEN MAC
	;


{
--- TESTING WORDS
: DKB		KEY: KB@ DROP CONKEY ;
: L		kbk 4 + @ .L SPACE kbk @ .L ;
}
{
16 bytes kbbuf
byte kbw
byte kbr
: KBPOLL	KB@ ?DUP IF kbbuf kbw C@ >N + C! kbw C++ THEN ;
: KBTASK	!KB kbw W~ BEGIN KBPOLL AGAIN ;
: KB		KEY: kbr C@ >N kbw >N C@ <> IF kbr C@ >N kbbuf + C@ kbr C++ ELSE CONKEY THEN ;
}


pri KEY^				$80 +
pri KEY#	( ascii KEY# -- )	>B kbtbl + C! ;
( LOWER CASE )
'a' $1C KEY#	'b' $32 KEY#	'c' $21 KEY#	'd' $23 KEY#
'e' $24 KEY#	'f' $2B KEY#	'g' $34 KEY#	'h' $33 KEY#
'i' $43 KEY#	'j' $3B KEY#	'k' $42 KEY#	'l' $4B KEY#
'm' $3A KEY#	'n' $31 KEY#	'o' $44 KEY#	'p' $4D KEY#
'q' $15 KEY#	'r' $2D KEY#	's' $1B KEY#	't' $2C KEY#
'u' $3C KEY#	'v' $2A KEY#	'w' $1D KEY#	'x' $22 KEY#
'y' $35 KEY#	'z' $1A KEY#
( UPPER CASE )
 'A' $1C KEY^	'B' $32 KEY^	'C' $21 KEY^	'D' $23 KEY^
 'E' $24 KEY^	'F' $2B KEY^	'G' $34 KEY^	'H' $33 KEY^
 'I' $43 KEY^	'J' $3B KEY^	'K' $42 KEY^	'L' $4B KEY^
 'M' $3A KEY^	'N' $31 KEY^	'O' $44 KEY^	'P' $4D KEY^
 'Q' $15 KEY^	'R' $2D KEY^	'S' $1B KEY^	'T' $2C KEY^
 'U' $3C KEY^	'V' $2A KEY^	'W' $1D KEY^	'X' $22 KEY^
 'Y' $35 KEY^	'Z' $1A KEY^
( NUMBERS )
 '1' $16 KEY#	'2' $1E KEY#	'3' $26 KEY#	'4' $25 KEY#
 '5' $2E KEY#	'6' $36 KEY#	'7' $3D KEY#	'8' $3E KEY#
 '9' $46 KEY#	'0' $45 KEY#
( SYMBOLS )
 '!' $16 KEY^	'@' $1E KEY^	'#' $26 KEY^	'$' $25 KEY^
 '%' $2E KEY^	'^' $36 KEY^	'&' $3D KEY^	'*' $3E KEY^
 '(' $46 KEY^	')' $45 KEY^	 '~' $0E KEY^	'`' $0E KEY#
 '-' $4E KEY#	'_' $4E KEY^	'=' $55 KEY# 	'+' $55 KEY^
 '[' $54 KEY#	'{' $54 KEY^	']' $5B KEY#	'}' $5B KEY^
 '\' $5D KEY#	'|' $5D KEY^	';' $4C KEY#	':' $4C KEY^
 ''' $52 KEY#	'"' $52 KEY^	',' $41 KEY#	'<' $41 KEY^
 '.' $49 KEY#	'>' $49 KEY^	'/' $4A KEY#	'?' $4A KEY^
( CONTROLS )
 $0D $5A KEY#	$0D $5A KEY^	$20 $29 KEY#	$20 $29 KEY^
 $1B $76 KEY#	$08 $66 KEY#	$09 $0D KEY#	$09 $0D KEY^

 ( F1 to F12 )
 $F1 $05 KEY#	$F2 $06 KEY#	$F3 $04 KEY#	$F4 $0C KEY#
 $F5 $03 KEY#	$F6 $0B KEY#	$F7 $F3 KEY#	$F8 $0A KEY#
 $F9 $01 KEY#	$FA $09 KEY#	$FB $78 KEY#	$FC $07 KEY#


( NUM PAD ) ( still needs to have num lock select function )
$90 $7E KEY#	\ SCROLL
$91 $77 KEY#	\ NUM LOCK
'+' $79 KEY# \ NUM+
'*' $7C KEY#	\ NUM*
'-' $7B KEY# \ NUM-
'.' $71 KEY#	\ NUM. DEL
'0' $70 KEY#	\ NUM0 INS
'1' $69 KEY#	\ NUM1 END
'2' $72 KEY# \ NUM2 DOWN
'3' $7A KEY# \ NUM3 PG DN
'4' $6B KEY# \ NUM4 LEFT
'5' $73 KEY# \ NUM5
'6' $74 KEY# \ NUM6 RIGHT
'7' $6C KEY#	\ NUM7 HOME
'8' $75 KEY# \ NUM8 UP
'9' $7D KEY# \ NUM9 PG UP


{
$E0 $1F 	\ LEFT WIN
$E0 $27		\ RIGHT WIN
$E0 $2F		\ LIST
$E0 $5E		\ WAKE UP
$E0 $3F		\ SLEEP
$E0 $37		\ POWER
$E0 $4A		\ NUM/
$E0 $12		\ DOWN
$E0 $14		\ RIGHT CTL
$E0 $23		\ MUTE
$E0 $34		\ PLAY
$E0 $44		\ STOP
}

\ FORGET KEY^

--- define F12 key
pub :FC		ls ;
pub :FB		DIR ;
pub :F5		" SPIDEY" VIEW$ ;
pub :F6		" MCQUEEN" VIEW$ ;





pub $= ( str1 str2 -- flg )
	OVER LEN$ OVER LEN$ =
	IF
	DUP LEN$
	ADO C@++ IC@ <> IF DROP 0 LEAVE THEN LOOP
	0<>
	ELSE 2DROP FALSE
	THEN
	;


: TIMEOUT	2DROP ;
: TIMEOUT?	DROP 0 ;
: ALARM		2DROP ;
: CONIO		CON ;
pre TIMER	[C] long ;
pub .TIME	." 00:00:00" ;
pub .DATE	." Wed Dec 26, 2018 " ;
: .DT		.DATE .TIME ;
: PLAIN ;
: BOLD ;
: CLKFREQ	CLKHZ ;
: U.R		<# FOR # NEXT #> PRINT$ ;
: EE@		@ ;
: EE!		! ;
ukey 2+		:= keypoll
ukey 14 +	:= flags
delim 4 +	:= uprompt
delim 6 +	:= uaccept
delim 16 +	:= unum

: OK		IF ' NOP ELSE 0 THEN uaccept W! ;
: ECHO		flags 1 ROT IF SET ELSE CLR THEN ;

: NULLOUT	EMIT: DROP ;

: PCB$	" P2D2" ;


long ucon

: [CON		uemit @ ucon ! CON ;
: CON]		ucon @ uemit ! ;


END
