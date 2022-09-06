all:
	cl65 main.c polygon_array.c scanline_c.s waitforjiffy.s -o main.prg -t cx16 -Or -Ois --codesize 20